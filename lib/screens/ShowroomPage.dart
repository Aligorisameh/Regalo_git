import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:regalofficial/screens/VideoPage.dart';
import 'package:regalofficial/app_localizations.dart';

class ShowroomPage extends StatefulWidget {
  @override
  _ShowroomPageState createState() => _ShowroomPageState();
}

class _ShowroomPageState extends State<ShowroomPage> {
  List<QueryDocumentSnapshot> watchedVideos = [];
  String? playerId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPlayerIdAndWatchedVideos();
  }

  Future<void> fetchPlayerIdAndWatchedVideos() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        playerId = user.uid;
      });
      await fetchWatchedVideos();
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchWatchedVideos() async {
    if (playerId != null) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('tickets')
          .where('playerId', isEqualTo: playerId)
          .get();
      setState(() {
        watchedVideos = querySnapshot.docs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('showroom')),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : watchedVideos.isEmpty
              ? Center(
                  child:
                      Text(localizations.translate('no_watched_videos_found')))
              : ListView.builder(
                  itemCount: watchedVideos.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic>? videoData =
                        watchedVideos[index].data() as Map<String, dynamic>?;
                    String adNumber = videoData?['adNumber']?.toString() ?? '';
                    String videoUrl = videoData?['videoUrl'] ?? '';
                    String companyName = videoData?['companyName'] ?? 'Unknown';

                    return ListTile(
                      title: Text(
                          '${localizations.translate('ad_number')}: $adNumber'),
                      subtitle: Text(
                          '${localizations.translate('company')}: $companyName'),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => VideoPage(
                            videoUrl: videoUrl,
                            companyName: companyName,
                          ),
                        ));
                      },
                    );
                  },
                ),
    );
  }
}
