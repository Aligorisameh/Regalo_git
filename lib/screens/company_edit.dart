import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:regalofficial/screens/editcompanyprofile.dart';
import 'package:regalofficial/screens/company_profile.dart';
import 'package:regalofficial/screens/show_my_ads_page.dart';
import 'package:regalofficial/app_localizations.dart';
import 'chat_page.dart';
import 'company_messages_page.dart';

class CompanyProfilePage1 extends StatefulWidget {
  final String companyEmail;

  CompanyProfilePage1({
    required this.companyEmail,
  });

  @override
  _CompanyProfilePage1State createState() => _CompanyProfilePage1State();
}

class _CompanyProfilePage1State extends State<CompanyProfilePage1> {
  late String companyName = '';
  late String companyEmail = '';
  late String imageUrl = '';
  late String bio = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompanyData();
  }

  Future<void> _fetchCompanyData() async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection('companyRequests')
              .where('companyEmail', isEqualTo: widget.companyEmail)
              .get();
      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        setState(() {
          companyName = doc['companyName'];
          companyEmail = doc['companyEmail'];
          imageUrl = doc['imageUrl'];
          bio = doc['bio'];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching company data: $e');
      // Show error message to the user
    }
  }

  void _editProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCompanyProfilePage(
          companyName: companyName,
          companyEmail: companyEmail,
          imageUrl: imageUrl,
          bio: bio,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        companyName = result['companyName'];
        companyEmail = result['companyEmail'];
        imageUrl = result['imageUrl'];
        bio = result['bio'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(localizations.translate('company_profile')),
        backgroundColor: Colors.green[700],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green[700],
              ),
              child: Text(
                localizations.translate('menu'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.add, color: Colors.green[700]),
              title: Text(
                localizations.translate('add_new_ads'),
                style: TextStyle(color: Colors.green[800]),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CompanyProfilePage(
                          companyEmail: widget.companyEmail)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: Colors.green[700]),
              title: Text(
                localizations.translate('edit_my_profile'),
                style: TextStyle(color: Colors.green[800]),
              ),
              onTap: _editProfile,
            ),
            ListTile(
              leading: Icon(Icons.list, color: Colors.green[700]),
              title: Text(
                localizations.translate('show_my_ads'),
                style: TextStyle(color: Colors.green[800]),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ShowMyAdsPage(
                            companyName: companyName,
                          )),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.message, color: Colors.green[700]),
              title: Text(
                localizations.translate('view_messages'),
                style: TextStyle(color: Colors.green[800]),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CompanyMessagesPage(
                      companyName: companyName,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.chat, color: Colors.green[700]),
              title: Text(
                localizations.translate('open_chat'),
                style: TextStyle(color: Colors.green[800]),
              ),
              onTap: () {
                final User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final String chatId = 'admin_${user.uid}';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        chatId: chatId,
                        receiverEmail: '',
                        receiverType: 'Company',
                      ),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.arrow_back, color: Colors.green[700]),
              title: Text(
                localizations.translate('back'),
                style: TextStyle(color: Colors.green[800]),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    imageUrl.isEmpty || !imageUrl.startsWith('http')
                        ? Text(localizations.translate('no_image_available'))
                        : Image.network(
                            imageUrl,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(
                                  '${localizations.translate('could_not_load_image')} $error');
                            },
                            fit: BoxFit.cover,
                          ),
                    SizedBox(height: 20),
                    Text(
                      localizations.translate('company_name') + ':',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    Text(
                      companyName,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green[800],
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      localizations.translate('email') + ':',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    Text(
                      companyEmail,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green[800],
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      localizations.translate('bio') + ':',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    Text(
                      bio,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
