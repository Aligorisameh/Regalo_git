import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:regalofficial/app_localizations.dart';

class MyTicketsPage extends StatefulWidget {
  @override
  _MyTicketsPageState createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage> {
  String? playerId;
  List<QueryDocumentSnapshot> tickets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPlayerId();
  }

  Future<void> fetchPlayerId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        playerId = user.uid;
      });
      await fetchTickets();
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchTickets() async {
    if (playerId != null) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('tickets')
          .where('playerId', isEqualTo: playerId)
          .get();
      setState(() {
        tickets = querySnapshot.docs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('my_tickets')),
        backgroundColor: Colors.green[700],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : tickets.isEmpty
              ? Center(
                  child: Text(localizations.translate('no_tickets_found')),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> ticketData =
                          tickets[index].data() as Map<String, dynamic>;
                      String adNumber =
                          ticketData['adNumber']?.toString() ?? 'Unknown';
                      String companyName =
                          ticketData['companyName'] ?? 'Unknown';
                      String ticketNumber =
                          ticketData['ticketNumber'] ?? 'Unknown';

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(
                            '${localizations.translate('ad_number')}: $adNumber',
                            style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${localizations.translate('company')}: $companyName',
                                style: TextStyle(color: Colors.green[600]),
                              ),
                              Text(
                                '${localizations.translate('ticket_number')}: $ticketNumber',
                                style: TextStyle(color: Colors.green[600]),
                              ),
                            ],
                          ),
                          contentPadding: EdgeInsets.all(16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.green[700]!),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
