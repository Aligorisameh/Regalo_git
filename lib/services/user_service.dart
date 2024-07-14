import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void saveUserLanguagePreference(String userId, String languageCode) {
    _firestore.collection('users').doc(userId).set({
      'language': languageCode,
    }, SetOptions(merge: true));
  }
}
