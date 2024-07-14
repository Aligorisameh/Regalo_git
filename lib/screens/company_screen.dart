import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:audioplayers/audioplayers.dart';
import 'company_registration_page.dart';
import 'company_edit.dart';
import 'package:regalofficial/app_localizations.dart';
import 'signin_screen.dart';

class CompanyHomePage extends StatefulWidget {
  @override
  _CompanyHomePageState createState() => _CompanyHomePageState();
}

class _CompanyHomePageState extends State<CompanyHomePage> {
  late String companyName = 'Company';
  late String companyEmail = '';
  String? approvalMessage;
  bool isRequestApproved = false;
  bool isLoading = true;
  late String currentUserEmail = '';
  late FirebaseAuth _auth;
  String? imageUrl;
  String? bio;
  String? rejectionReason;
  List<String> highlightedFields = [];
  bool _isCompanyRegistered = false;
  bool _isRequestRejected = false;
  String? documentId;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    fetchCurrentUserEmail();
    fetchCompanyDetails();
    _playWelcomeAudio();
  }

  void fetchCurrentUserEmail() {
    currentUserEmail = _auth.currentUser?.email ?? '';
  }

  Future<void> fetchCompanyDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('companyRequests')
          .where('companyEmail', isEqualTo: user.email)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot snapshot = querySnapshot.docs.first;
        var userData = snapshot.data() as Map<String, dynamic>?;
        documentId = snapshot.id;
        if (userData != null) {
          setState(() {
            companyName = userData['companyName'] ?? 'Company';
            companyEmail = userData['companyEmail'] ?? '';
            imageUrl = userData['imageUrl'] ?? '';
            bio = userData['bio'] ??
                AppLocalizations.of(context)!.translate('no_bio_available');
            rejectionReason = userData['rejectionReason'];
            highlightedFields =
                List<String>.from(userData['highlightedFields'] ?? []);
            _isCompanyRegistered = userData['status'] == 'pending' ||
                userData['status'] == 'approved';
            _isRequestRejected = userData['status'] == 'rejected';
            isRequestApproved = userData['status'] == 'approved';

            if (userData['status'] == 'approved') {
              approvalMessage =
                  AppLocalizations.of(context)!.translate('congratulations');
              _showApprovalMessageTemporarily();
            } else {
              approvalMessage = AppLocalizations.of(context)!
                  .translate('new_request_pending');
            }
            print('Fetched company details: $userData');
          });
        }
      }
      setState(() {
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showApprovalMessageTemporarily() {
    Timer(Duration(seconds: 5), () {
      setState(() {
        approvalMessage = null;
      });
    });
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    setState(() {
      approvalMessage = null;
      _isCompanyRegistered = false;
      isRequestApproved = false;
      _isRequestRejected = false;
      companyName = 'Company';
      companyEmail = '';
      imageUrl = null;
      bio = null;
      rejectionReason = null;
      highlightedFields = [];
      currentUserEmail = '';
      print('State reset on logout');
    });
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => SignInScreen(),
    ));
  }

  void handleSubmission() {
    setState(() {
      _isCompanyRegistered = true;
      _isRequestRejected = false;
      isRequestApproved = false;
      approvalMessage =
          AppLocalizations.of(context)!.translate('new_request_pending');
      print('Handled submission: New request pending approval');
    });
  }

  Future<void> approveRequest(String requestId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('companyRequests')
            .doc(requestId)
            .update({
          'status': 'approved',
          'approvedBy': user.uid,
        });
        setState(() {
          isRequestApproved = true;
          approvalMessage =
              AppLocalizations.of(context)!.translate('congratulations');
        });
        print('Request approved successfully');
      } catch (e) {
        print('Failed to approve request: $e');
      }
    } else {
      print('No user logged in');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      await _uploadImage(imageFile);
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && documentId != null) {
      String fileName = 'companyImages/${user.uid}.jpg';
      try {
        UploadTask uploadTask =
            FirebaseStorage.instance.ref().child(fileName).putFile(imageFile);
        TaskSnapshot taskSnapshot = await uploadTask;
        String imageUrl = await taskSnapshot.ref.getDownloadURL();
        await FirebaseFirestore.instance
            .collection('companyRequests')
            .doc(documentId)
            .update({'imageUrl': imageUrl});
        setState(() {
          this.imageUrl = imageUrl;
        });
        print('Image uploaded and URL saved to Firestore');
      } catch (e) {
        print('Failed to upload image: $e');
      }
    } else {
      print('No user logged in or documentId is null');
    }
  }

  Future<void> _playWelcomeAudio() async {
    try {
      await _audioPlayer.setSource(AssetSource('welcomee.wav'));
      await _audioPlayer.resume();
    } catch (e) {
      print('Failed to play welcome audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('company_home')),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.logout, color: Color(0xFFFF8008)),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0x1AA8E063), // Opacity 10%
              Color(0x1A56AB2F), // Opacity 10%
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 120, 20, 0),
                  child: Column(
                    children: <Widget>[
                      InkWell(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey,
                          backgroundImage:
                              imageUrl != null && imageUrl!.isNotEmpty
                                  ? NetworkImage(imageUrl!)
                                  : null,
                          child: imageUrl == null || imageUrl!.isEmpty
                              ? Text(
                                  AppLocalizations.of(context)!
                                      .translate('no_image_available'),
                                  style: TextStyle(color: Color(0xFFFF8008)),
                                )
                              : null,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        AppLocalizations.of(context)!.translate('hello'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF8008),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        companyName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF8008),
                        ),
                      ),
                      SizedBox(height: 20),
                      if (approvalMessage != null)
                        Text(
                          approvalMessage!,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                isRequestApproved ? Colors.green : Colors.red,
                          ),
                        ),
                      SizedBox(height: 20),
                      if (_isRequestRejected)
                        Column(
                          children: [
                            Text(
                              AppLocalizations.of(context)!
                                  .translate('request_rejected'),
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              rejectionReason!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                              ),
                            ),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CompanyRegistrationPage(
                                      companyEmail: companyEmail,
                                      highlightedFields: highlightedFields,
                                      onSubmitted: handleSubmission,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF56AB2F),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.translate(
                                    'view_details_and_update_request'),
                                style: TextStyle(color: Color(0xFFFFC837)),
                              ),
                            ),
                          ],
                        ),
                      if (!_isRequestRejected)
                        Column(
                          children: [
                            if (!_isCompanyRegistered)
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            CompanyRegistrationPage(
                                              companyEmail: companyEmail,
                                              highlightedFields:
                                                  highlightedFields,
                                              onSubmitted: handleSubmission,
                                            )),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF56AB2F),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .translate('register_company'),
                                  style: TextStyle(color: Color(0xFFFFC837)),
                                ),
                              ),
                            SizedBox(height: 20),
                          ],
                        ),
                      if (isRequestApproved)
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CompanyProfilePage1(
                                      companyEmail: companyEmail,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF56AB2F),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!
                                    .translate('go_to_company_profile'),
                                style: TextStyle(color: Color(0xFFFFC837)),
                              ),
                            ),
                            SizedBox(height: 20),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
