import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:regalofficial/app_localizations.dart';
import 'package:regalofficial/Homepage.dart';
import 'package:regalofficial/screens/player_screen.dart';
import 'package:regalofficial/screens/signup_screen.dart';
import 'package:regalofficial/screens/reset_password.dart';
import 'package:regalofficial/screens/admin_profile.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:regalofficial/main.dart';

class SignIn extends StatefulWidget {
  const SignIn({Key? key});

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _emailTextController = TextEditingController();
  String _errorMessage = '';

  static const Color darkOrange = Color(0xFFFF8C00); // Custom dark orange color

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Colors.white, // Set background color to white
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).size.height * 0.1,
              20,
              0,
            ),
            child: Column(
              children: <Widget>[
                Image.asset('assets/images/logo---.png'), // Add logo at the top
                const SizedBox(height: 30),
                reusableTextField(
                  AppLocalizations.of(context)!.translate('enter_username'),
                  Icons.person_outline,
                  false,
                  _emailTextController,
                  color: darkOrange, // Set the text color here
                ),
                const SizedBox(height: 20),
                reusableTextField(
                  AppLocalizations.of(context)!.translate('enter_password'),
                  Icons.lock_outline,
                  true,
                  _passwordTextController,
                  color: darkOrange, // Set the text color here
                ),
                const SizedBox(height: 5),
                forgetPassword(context),
                firebaseUIButton(
                  context,
                  AppLocalizations.of(context)!.translate('sign_in'),
                  _signInWithEmailAndPassword,
                  color: const Color(0xFF56AB2F),
                  textColor: const Color(0xFFFFC837),
                ),
                const SizedBox(height: 10),
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                signUpOption(),
                goToHomePageOption(),
                const SizedBox(height: 20),
                socialMediaIcons(), // Add social media icons at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _signInWithEmailAndPassword() async {
    String adminEmail = "evolutionn.informatique@gmail.com";

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailTextController.text,
        password: _passwordTextController.text,
      );

      User? user = userCredential.user;
      if (user != null) {
        if (user.email == adminEmail) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminHomePage()),
          );
        } else {
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get()
              .then((DocumentSnapshot documentSnapshot) {
            var data = documentSnapshot.data() as Map<String, dynamic>?;
            if (data != null && data.containsKey('userType')) {
              var userType = data['userType'];

              if (userType == 'player') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayerHomePage(),
                  ),
                );
              } else if (userType == 'company') {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(AppLocalizations.of(context)!
                          .translate('access_denied_title')),
                      content: Text(AppLocalizations.of(context)!
                          .translate('access_denied_message')),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                              AppLocalizations.of(context)!.translate('ok')),
                        ),
                      ],
                    );
                  },
                );
              }
            }
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = "The email or password is incorrect. Please try again.";
      });
      if (kDebugMode) {
        print("Error: ${e.toString()}");
      }
    }
  }

  Row signUpOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('dont_have_account'),
          style: TextStyle(color: Colors.black54),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignUpScreen()),
            );
          },
          child: Text(
            AppLocalizations.of(context)!.translate('sign_up'),
            style: TextStyle(
              color: Color(0xFFFFC837),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Row goToHomePageOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('back_to'),
          style: TextStyle(color: Colors.black54),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  setLocale: (Locale locale) {
                    MyAppState? appState =
                        context.findAncestorStateOfType<MyAppState>();
                    appState?.setLocale(locale);
                  },
                ),
              ),
              (Route<dynamic> route) => false,
            );
          },
          child: Text(
            AppLocalizations.of(context)!.translate('home_page'),
            style: TextStyle(
              color: Color(0xFFFFC837),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget forgetPassword(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 35,
      alignment: Alignment.bottomRight,
      child: TextButton(
        child: Text(
          AppLocalizations.of(context)!.translate('forgot_password'),
          style: TextStyle(color: Colors.black54),
          textAlign: TextAlign.right,
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ResetPassword()),
        ),
      ),
    );
  }

  // Function to display the social media icons
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

  // Function to create individual social media icon
  Widget socialMediaIcon(IconData icon) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Color(0xFFFFC837), // Dialog background color
              content: Text(
                "Coming soon...",
                style: TextStyle(color: Color(0xFF56AB2F)), // Dialog text color
              ),
            );
          },
        );
      },
      child: FaIcon(
        icon,
        color: Color(0xFFFF8008), // Social media icon color
        size: 30,
      ),
    );
  }
}

// Modified reusableTextField to accept color parameter
Widget reusableTextField(String text, IconData icon, bool isPasswordType,
    TextEditingController controller,
    {Color color = Colors.black}) {
  return TextField(
    controller: controller,
    obscureText: isPasswordType,
    style: TextStyle(
        color: color, fontWeight: FontWeight.bold), // Set text color and bold
    decoration: InputDecoration(
      prefixIcon: Icon(icon, color: color),
      labelText: text,
      labelStyle: TextStyle(color: color),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        borderSide: BorderSide(color: color),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        borderSide: BorderSide(color: color),
      ),
    ),
  );
}

// Modified firebaseUIButton to accept color parameters
Widget firebaseUIButton(BuildContext context, String title, Function onTap,
    {Color color = Colors.white, Color textColor = Colors.white}) {
  return Container(
    width: MediaQuery.of(context).size.width,
    height: 50,
    margin: const EdgeInsets.fromLTRB(0, 10, 0, 20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(90),
    ),
    child: ElevatedButton(
      onPressed: () => onTap(),
      child: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.pressed))
            return color.withOpacity(0.5);
          return color; // Use the component's default.
        }),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    ),
  );
}
