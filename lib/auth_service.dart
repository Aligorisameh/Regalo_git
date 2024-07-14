import 'package:firebase_auth/firebase_auth.dart';

Future<bool> isAdmin() async {
  // Get the current user
  User? user = FirebaseAuth.instance.currentUser;

  // Check if the user is signed in and their email matches the admin email
  if (user != null && user.email == 'evolutionn.informatique@gmail.com') {
    return true;
  }

  return false;
}
