import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class AdminMessagesPage extends StatefulWidget {
  @override
  _AdminMessagesPageState createState() => _AdminMessagesPageState();
}

class _AdminMessagesPageState extends State<AdminMessagesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _sendResponse(String messageId, String email, String response) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'response': response,
        'responseTimestamp': FieldValue.serverTimestamp(),
        'respondedBy': 'Admin',
      });

      // Send email to the user
      await _sendEmail(email, response);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Response sent successfully')),
      );
    } catch (e) {
      print('Failed to send response: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send response: $e')),
      );
    }
  }

  Future<void> _sendEmail(String email, String response) async {
    final String username =
        'evolutionn.informatique@gmail.com'; // Replace with your email
    final String password =
        'evolutioninformatique152001evolution'; // Replace with your email password

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'Your Name')
      ..recipients.add(email)
      ..subject = 'Response to your message'
      ..text = response
      ..html = '<html><body><p>$response</p></body></html>';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Message not sent. ${e.toString()}');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Messages'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('messages').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var messages = snapshot.data!.docs;

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              var messageData = messages[index].data() as Map<String, dynamic>;
              var messageId = messages[index].id;
              var email = messageData['email'];
              var message = messageData['message'];
              var response = messageData['response'] ?? '';

              return Card(
                child: ListTile(
                  title: Text('From: $email'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Message: $message'),
                      SizedBox(height: 8),
                      TextFormField(
                        initialValue: response,
                        decoration: InputDecoration(
                          labelText: 'Response',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        onChanged: (value) {
                          response = value;
                        },
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          _sendResponse(messageId, email, response);
                        },
                        child: Text('Send Response'),
                      ),
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
