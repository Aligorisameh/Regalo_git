import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:regalofficial/app_localizations.dart'; // تأكد من استخدام AppLocalizations

class CompanyMessagesPage extends StatelessWidget {
  final String companyName;

  const CompanyMessagesPage({Key? key, required this.companyName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${AppLocalizations.of(context)!.translate('messages_for')} $companyName'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('companyMessages')
            .where('companyName', isEqualTo: companyName)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text(
                    '${AppLocalizations.of(context)!.translate('error')}: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text(AppLocalizations.of(context)!
                    .translate('no_messages_found')));
          }

          final messages = snapshot.data!.docs;

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final messageData =
                  messages[index].data() as Map<String, dynamic>;
              final message = messageData['message'] ?? 'No message';
              final timestamp = messageData['timestamp'] as Timestamp?;
              final answers = List<String>.from(messageData['answers'] ?? []);

              return ListTile(
                title: Text(message),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (timestamp != null)
                      Text(
                          '${AppLocalizations.of(context)!.translate('sent_at')} ${timestamp.toDate()}'),
                    ...answers.map((answer) => Text(answer)).toList(),
                    TextButton(
                      onPressed: () =>
                          _showAnswerDialog(context, messages[index].id),
                      child: Text(
                          AppLocalizations.of(context)!.translate('answer')),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAnswerDialog(BuildContext context, String messageId) {
    final TextEditingController _answerController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              Text(AppLocalizations.of(context)!.translate('answer_message')),
          content: TextField(
            controller: _answerController,
            decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!
                    .translate('type_your_answer')),
            maxLines: null,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final String answer = _answerController.text;
                if (answer.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('companyMessages')
                        .doc(messageId)
                        .update({
                      'answers': FieldValue.arrayUnion(['Admin: $answer'])
                    });
                    Navigator.of(context).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              '${AppLocalizations.of(context)!.translate('failed_to_submit_answer')} $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(AppLocalizations.of(context)!
                            .translate('please_enter_an_answer'))),
                  );
                }
              },
              child: Text(AppLocalizations.of(context)!.translate('submit')),
            ),
          ],
        );
      },
    );
  }
}
