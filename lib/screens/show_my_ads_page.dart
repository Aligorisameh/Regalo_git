import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:regalofficial/screens/company_profile.dart';
import 'package:regalofficial/app_localizations.dart';

class ShowMyAdsPage extends StatelessWidget {
  final String companyName;

  ShowMyAdsPage({required this.companyName});

  Future<List<Map<String, dynamic>>> _fetchAds() async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('companies')
              .where('companyName', isEqualTo: companyName)
              .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching ads: $e');
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('show_my_ads')),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAds(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text(localizations.translate('error_fetching_ads')));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(localizations.translate('no_ads_found')));
          }

          final ads = snapshot.data!;
          return ListView.builder(
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final ad = ads[index];
              final isPublished = ad['isPublished'];
              final rejectionReason = ad['rejectionReason'];

              return Card(
                child: ListTile(
                  title: Text(
                      ad['companyName'] ?? localizations.translate('no_title')),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ad['selectedType'] ??
                          localizations.translate('no_type')),
                      Text(
                          '${localizations.translate('number_of_winners')}: ${ad['numberOfWinners'] ?? 'N/A'}'),
                      ad['imageUrls'] != null && ad['imageUrls'].isNotEmpty
                          ? Image.network(ad['imageUrls'][0])
                          : Container(),
                      ad['videoUrl'] != null && ad['videoUrl'].isNotEmpty
                          ? Text(localizations.translate('video_available'))
                          : Container(),
                      isPublished == true
                          ? Text(localizations.translate('status_published'),
                              style: TextStyle(color: Colors.green))
                          : isPublished == false
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        localizations
                                            .translate('status_rejected'),
                                        style: TextStyle(color: Colors.red)),
                                    Text(
                                        '${localizations.translate('reason')}: ${rejectionReason ?? 'N/A'}'),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CompanyProfilePage(
                                              companyEmail: '',
                                              adData: ad,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text(localizations
                                          .translate('view_details')),
                                    ),
                                  ],
                                )
                              : Text(localizations.translate('status_pending'),
                                  style: TextStyle(color: Colors.orange)),
                    ],
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
