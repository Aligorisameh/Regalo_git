import 'package:cloud_firestore/cloud_firestore.dart';

class MessageStorage {
  static Future<void> addMessage(String companyName, String message) async {
    await FirebaseFirestore.instance.collection('companyMessages').add({
      'companyName': companyName,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getMessages(String companyName) {
    return FirebaseFirestore.instance
        .collection('companyMessages')
        .where('companyName', isEqualTo: companyName)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
