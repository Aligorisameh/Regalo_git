import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:regalofficial/app_localizations.dart'; // تأكد من استخدام AppLocalizations

class OurPartnersPage extends StatelessWidget {
  Future<List<Map<String, dynamic>>> _fetchPartners() async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance.collection('companyRequests').get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching partners: $e');
      return [];
    }
  }

  void _showBioDialog(BuildContext context, String bio) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFFFC837),
          title: Text(
            AppLocalizations.of(context)!.translate('company_bio'),
            style: TextStyle(color: Color(0xFFA8E063)),
          ),
          content: Text(
            bio,
            style: TextStyle(color: Color(0xFFA8E063)),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.translate('close'),
                style: TextStyle(color: Color(0xFFA8E063)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFA8E063),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('our_partners')),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchPartners(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text(AppLocalizations.of(context)!
                    .translate('error_fetching_partners')));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text(AppLocalizations.of(context)!
                    .translate('no_partners_found')));
          }

          final partners = snapshot.data!;
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
            ),
            itemCount: partners.length,
            itemBuilder: (context, index) {
              final partner = partners[index];
              return GestureDetector(
                onTap: () {
                  _showBioDialog(
                      context,
                      partner['bio'] ??
                          AppLocalizations.of(context)!
                              .translate('no_bio_available'));
                },
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: partner['imageUrl'] != null &&
                                  partner['imageUrl'].isNotEmpty
                              ? NetworkImage(partner['imageUrl'])
                              : AssetImage('assets/placeholder_image.png')
                                  as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Text(
                          partner['companyName'] ??
                              AppLocalizations.of(context)!
                                  .translate('no_name'),
                          style: TextStyle(
                            color: Color(0xFFFF8008),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
