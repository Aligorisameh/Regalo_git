import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:regalofficial/app_localizations.dart';

class WinnersPage extends StatefulWidget {
  @override
  _WinnersPageState createState() => _WinnersPageState();
}

class _WinnersPageState extends State<WinnersPage> {
  @override
  void initState() {
    super.initState();
    testFirestoreData();
  }

  void testFirestoreData() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('winners').get();
      for (var doc in snapshot.docs) {
        print(doc.data());
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('winners_list')),
        backgroundColor: Colors.green[700],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('winners').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            return Center(
              child: Text(
                  '${localizations.translate('error')}: ${snapshot.error}'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print('No winners found.');
            return Center(
                child: Text(localizations.translate('no_winners_found')));
          }

          List<QueryDocumentSnapshot> winners = snapshot.data!.docs;
          print('Winners found: ${winners.length}'); // Debug print

          return ListView.builder(
            itemCount: winners.length,
            itemBuilder: (context, index) {
              var winner = winners[index].data() as Map<String, dynamic>;
              print('Winner data at index $index: $winner'); // Debug print

              return GestureDetector(
                onTap: () {},
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.blue, Colors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: Text(
                      '${winner['companyName']} - ${localizations.translate('ad_number')}: ${winner['adNumber']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${localizations.translate('ticket_number')}: ${winner['ticketNumber']}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          '${localizations.translate('player_name')}: ${winner['playerName']}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
