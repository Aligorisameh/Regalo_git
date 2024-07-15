import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:regalofficial/app_localizations.dart'; // تأكد من استخدام AppLocalizations

// تعريف الدوال sendMessage و fetchMessages خارج صف _MessagingPageState
Future<void> sendMessage(String recipientEmail, String content) async {
  try {
    await FirebaseFirestore.instance.collection('messages').add({
      'sender': 'evolutionn.informatique@gmail.com',
      'recipient': recipientEmail,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    print('Error sending message: $e');
    // Show error message to the user
  }
}

Future<List<Map<String, dynamic>>> fetchMessages(String userEmail) async {
  List<Map<String, dynamic>> messages = [];
  try {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('messages')
        .where('recipient', isEqualTo: userEmail)
        .orderBy('timestamp', descending: true)
        .get();

    snapshot.docs.forEach((doc) {
      Map<String, dynamic> messageData = {
        'sender': doc['sender'],
        'content': doc['content'],
        'timestamp': doc['timestamp'],
      };
      messages.add(messageData);
    });
  } catch (e) {
    print('Error fetching messages: $e');
    // Show error message to the user
  }
  return messages;
}

class MessagingPage extends StatefulWidget {
  @override
  _MessagingPageState createState() => _MessagingPageState();
}

class _MessagingPageState extends State<MessagingPage> {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _sendMessage() async {
    await sendMessage(_recipientController.text, _contentController.text);
    _contentController.clear();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    List<Map<String, dynamic>> messages =
        await fetchMessages('user@example.com');
    setState(() {
      _messages = messages;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('messaging')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _recipientController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.translate('recipient'),
              ),
            ),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.translate('content'),
              ),
            ),
            ElevatedButton(
              onPressed: _sendMessage,
              child: Text(AppLocalizations.of(context)!.translate('send')),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> message = _messages[index];
                  return ListTile(
                    title: Text(message['content']),
                    subtitle: Text(
                        '${AppLocalizations.of(context)!.translate('sender')}: ${message['sender']}'),
                    trailing: Text(
                        '${AppLocalizations.of(context)!.translate('timestamp')}: ${message['timestamp'].toDate()}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
