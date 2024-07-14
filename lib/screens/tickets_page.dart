import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:regalofficial/app_localizations.dart';

class TicketsPage extends StatefulWidget {
  @override
  _TicketsPageState createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> tickets = [];
  List<String> adNumbers = [];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('all_tickets')),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.casino),
            onPressed: _performLottery,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: localizations.translate('search_by_ticket_number'),
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _searchQuery = _searchController.text;
                    });
                  },
                ),
              ),
              enableInteractiveSelection: true,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('tickets').snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          '${localizations.translate('error')}: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text(localizations.translate('no_tickets_found')));
                }

                tickets = snapshot.data!.docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return {
                    'companyName': data['companyName'] ??
                        localizations.translate('unknown_company'),
                    'adNumber': data['adNumber'].toString(),
                    'ticketDetails': data['ticketDetails'] ??
                        localizations.translate('no_details'),
                    'ticketNumber': data['ticketNumber'].toString(),
                    'playerName': data['playerName'] ??
                        localizations.translate('unknown_player'),
                  };
                }).toList();

                adNumbers = tickets
                    .map((ticket) => ticket['adNumber'].toString())
                    .toSet()
                    .toList();

                if (_searchQuery.isNotEmpty) {
                  tickets = tickets.where((ticket) {
                    return ticket['ticketNumber'] == _searchQuery;
                  }).toList();
                }

                tickets.sort((a, b) {
                  int companyComparison =
                      a['companyName'].compareTo(b['companyName']);
                  if (companyComparison != 0) return companyComparison;
                  return a['adNumber'].compareTo(b['adNumber']);
                });

                if (_searchQuery.isNotEmpty && tickets.isEmpty) {
                  return Center(
                      child: Text(localizations
                          .translate('no_matching_tickets_found')));
                }

                return ListView.builder(
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    var ticket = tickets[index];
                    return ListTile(
                      title: SelectableText(
                        '${ticket['companyName']} - ${localizations.translate('ad_number')}: ${ticket['adNumber']}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                              '${localizations.translate('ticket_number')}: ${ticket['ticketNumber']}'),
                          SelectableText(
                              '${localizations.translate('details')}: ${ticket['ticketDetails']}'),
                          SelectableText(
                              '${localizations.translate('player_name')}: ${ticket['playerName']}'),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _performLottery() async {
    final localizations = AppLocalizations.of(context)!;

    if (adNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(localizations.translate('no_ads_found')),
      ));
      return;
    }

    String? selectedAdNumber = await _showAdNumberSelectionDialog();
    if (selectedAdNumber == null) return;

    List<Map<String, dynamic>> adTickets = tickets
        .where((ticket) => ticket['adNumber'] == selectedAdNumber)
        .toList();

    if (adTickets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(localizations.translate('no_tickets_for_selected_ad')),
      ));
      return;
    }

    var random = Random();
    int winnerIndex = random.nextInt(adTickets.length);
    Map<String, dynamic> winningTicket = adTickets[winnerIndex];

    // Store the winning ticket in the winners collection
    await FirebaseFirestore.instance.collection('winners').add({
      'companyName': winningTicket['companyName'],
      'adNumber': winningTicket['adNumber'],
      'ticketNumber': winningTicket['ticketNumber'],
      'playerName': winningTicket['playerName'],
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Display winner information in a dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.translate('lottery_winner')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${localizations.translate('company_name')}: ${winningTicket['companyName']}',
              ),
              Text(
                '${localizations.translate('ad_number')}: ${winningTicket['adNumber']}',
              ),
              Text(
                '${localizations.translate('ticket_number')}: ${winningTicket['ticketNumber']}',
              ),
              Text(
                '${localizations.translate('player_name')}: ${winningTicket['playerName']}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(localizations.translate('ok')),
            ),
          ],
        );
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          '${localizations.translate('winner')}: ${winningTicket['companyName']} - ${winningTicket['adNumber']} - ${winningTicket['ticketNumber']} - ${winningTicket['playerName']}'),
    ));
  }

  Future<String?> _showAdNumberSelectionDialog() async {
    final localizations = AppLocalizations.of(context)!;

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String? selectedAdNumber;
        return AlertDialog(
          title: Text(localizations.translate('select_ad_number')),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButton<String>(
                isExpanded: true,
                value: selectedAdNumber ?? adNumbers[0],
                items: adNumbers.map((String adNumber) {
                  return DropdownMenuItem<String>(
                    value: adNumber,
                    child: Text(adNumber),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedAdNumber = newValue;
                  });
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(selectedAdNumber);
              },
              child: Text(localizations.translate('ok')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(localizations.translate('cancel')),
            ),
          ],
        );
      },
    );
  }
}
