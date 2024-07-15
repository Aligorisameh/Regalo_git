import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:regalofficial/app_localizations.dart';

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String? playerId;
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
      await fetchUserProfile();
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchUserProfile() async {
    if (playerId != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(playerId)
          .get();
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        print("Fetched user data: $data"); // Debugging statement
        setState(() {
          _emailController.text = data['email'] ?? '';
          _nameController.text = data['username'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
        });
      } else {
        print("User document does not exist"); // Debugging statement
      }
    }
  }

  Future<void> updateUserProfile() async {
    if (_formKey.currentState!.validate()) {
      if (playerId != null) {
        try {
          DocumentReference userRef =
              FirebaseFirestore.instance.collection('users').doc(playerId);

          print(
              "Updating profile for user ID: $playerId"); // Debugging statement
          print("New email: ${_emailController.text}");
          print("New name: ${_nameController.text}");
          print("New phone: ${_phoneController.text}");
          print("New address: ${_addressController.text}");

          await userRef.update({
            'email': _emailController.text,
            'username': _nameController.text,
            'phone': _phoneController.text,
            'address': _addressController.text,
          });

          // Fetch the document again to verify the update
          DocumentSnapshot updatedUserDoc = await userRef.get();
          print(
              "Updated user data: ${updatedUserDoc.data()}"); // Debugging statement

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!
                    .translate('profile_updated_successfully'))),
          );
        } catch (e) {
          print("Error updating profile: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!
                    .translate('failed_to_update_profile'))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('user_profile')),
        backgroundColor: Colors.green[700],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: localizations.translate('email'),
                          labelStyle: TextStyle(color: Colors.green[800]),
                          fillColor: Colors.green[50],
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations
                                .translate('please_enter_your_email');
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: localizations.translate('name'),
                          labelStyle: TextStyle(color: Colors.green[800]),
                          fillColor: Colors.green[50],
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations
                                .translate('please_enter_your_name');
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: localizations.translate('phone'),
                          labelStyle: TextStyle(color: Colors.green[800]),
                          fillColor: Colors.green[50],
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations
                                .translate('please_enter_your_phone_number');
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: localizations.translate('address'),
                          labelStyle: TextStyle(color: Colors.green[800]),
                          fillColor: Colors.green[50],
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations
                                .translate('please_enter_your_address');
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 30),
                      Center(
                        child: ElevatedButton(
                          onPressed: updateUserProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child:
                              Text(localizations.translate('update_profile')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
