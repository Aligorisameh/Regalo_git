import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:regalofficial/app_localizations.dart';
import 'package:regalofficial/screens/signin_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum UserType {
  player,
  company,
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _userNameTextController = TextEditingController();
  final TextEditingController _customTokenController = TextEditingController();
  UserType? _selectedUserType;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const Color darkOrange = Color(0xFFFF8C00); // Custom dark orange color

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('sign_up'),
          style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF56AB2F)),
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Colors.white,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 120, 20, 0),
            child: Column(
              children: <Widget>[
                Image.asset('assets/images/logo---.png'),
                const SizedBox(height: 20),
                TextField(
                  controller: _userNameTextController,
                  style:
                      TextStyle(color: darkOrange, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixIcon:
                        Icon(Icons.person_outline, color: Color(0xFF56AB2F)),
                    labelText: AppLocalizations.of(context)!
                        .translate('enter_username'),
                    labelStyle: TextStyle(color: Color(0xFF56AB2F)),
                    filled: true,
                    fillColor: Color(0xFFA8E063).withOpacity(0.1),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(color: Color(0xFF56AB2F)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(color: Color(0xFF56AB2F)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailTextController,
                  style:
                      TextStyle(color: darkOrange, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixIcon:
                        Icon(Icons.email_outlined, color: Color(0xFF56AB2F)),
                    labelText:
                        AppLocalizations.of(context)!.translate('enter_email'),
                    labelStyle: TextStyle(color: Color(0xFF56AB2F)),
                    filled: true,
                    fillColor: Color(0xFFA8E063).withOpacity(0.1),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(color: Color(0xFF56AB2F)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(color: Color(0xFF56AB2F)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordTextController,
                  obscureText: true,
                  style:
                      TextStyle(color: darkOrange, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixIcon:
                        Icon(Icons.lock_outline, color: Color(0xFF56AB2F)),
                    labelText: AppLocalizations.of(context)!
                        .translate('enter_password'),
                    labelStyle: TextStyle(color: Color(0xFF56AB2F)),
                    filled: true,
                    fillColor: Color(0xFFA8E063).withOpacity(0.1),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(color: Color(0xFF56AB2F)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(color: Color(0xFF56AB2F)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<UserType>(
                  value: _selectedUserType,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedUserType = newValue!;
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon:
                        Icon(Icons.person_outline, color: Color(0xFF56AB2F)),
                    labelText: AppLocalizations.of(context)!
                        .translate('select_user_type'),
                    labelStyle: TextStyle(color: Color(0xFF56AB2F)),
                    filled: true,
                    fillColor: Color(0xFFA8E063).withOpacity(0.1),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(color: Color(0xFF56AB2F)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(color: Color(0xFF56AB2F)),
                    ),
                  ),
                  items: [
                    DropdownMenuItem<UserType>(
                      value: UserType.player,
                      child: Text(
                          AppLocalizations.of(context)!.translate('player'),
                          style: TextStyle(color: Color(0xFF56AB2F))),
                    ),
                    DropdownMenuItem<UserType>(
                      value: UserType.company,
                      child: Text(
                          AppLocalizations.of(context)!.translate('company'),
                          style: TextStyle(color: Color(0xFF56AB2F))),
                    ),
                  ],
                  hint: Text(
                    AppLocalizations.of(context)!.translate('select_user_type'),
                    style: TextStyle(color: Color(0xFF56AB2F)),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 50,
                  margin: const EdgeInsets.fromLTRB(0, 10, 0, 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(90),
                  ),
                  child: ElevatedButton(
                    onPressed: _createUser,
                    child: Text(
                      AppLocalizations.of(context)!.translate('sign_up'),
                      style: TextStyle(
                        color: Color(0xFF56AB2F),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                        if (states.contains(MaterialState.pressed))
                          return Color(0xFFFF8008).withOpacity(0.5);
                        return Color(0xFFFF8008);
                      }),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                socialMediaIcons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _createUser() async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailTextController.text,
        password: _passwordTextController.text,
      );
      User? user = userCredential.user;

      if (user != null) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'username': _userNameTextController.text,
          'email': _emailTextController.text,
          'userType': describeEnum(_selectedUserType!),
          'password': _passwordTextController.text, // Save the password
        }).then((_) {
          print("Document added successfully");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SignInScreen(),
            ),
          );
        }).catchError((error) {
          print("Error adding document: $error");
        });
      }
    } catch (error) {
      print("Error creating user: $error");
    }
  }

  Future<void> _signInWithCustomToken() async {
    try {
      final token = _customTokenController.text.trim();
      UserCredential userCredential = await _auth.signInWithCustomToken(token);
      User? user = userCredential.user;

      if (user != null) {
        print('Verification successful: ${user.uid}');
      } else {
        print('Verification failed');
      }
    } catch (e) {
      print("Error verifying custom token: $e");
    }
  }

  Widget socialMediaIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        socialMediaIcon(FontAwesomeIcons.facebook),
        const SizedBox(width: 10),
        socialMediaIcon(FontAwesomeIcons.twitter),
        const SizedBox(width: 10),
        socialMediaIcon(FontAwesomeIcons.instagram),
        const SizedBox(width: 10),
        socialMediaIcon(FontAwesomeIcons.snapchat),
      ],
    );
  }

  Widget socialMediaIcon(IconData icon) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFFC837),
              content: const Text(
                "Coming soon...",
                style: TextStyle(color: Color(0xFF56AB2F)),
              ),
            );
          },
        );
      },
      child: FaIcon(
        icon,
        color: const Color(0xFFFF8008),
        size: 30,
      ),
    );
  }
}
