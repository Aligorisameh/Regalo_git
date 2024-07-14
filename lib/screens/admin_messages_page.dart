import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:regalofficial/app_localizations.dart'; // تأكد من استخدام AppLocalizations

class AdminMessagesPage extends StatelessWidget {
  const AdminMessagesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!
            .translate('all_messages_and_answers')),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('companyMessages')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
              final companyName = messageData['companyName'] ??
                  AppLocalizations.of(context)!.translate('no_company_name');
              final message = messageData['message'] ??
                  AppLocalizations.of(context)!.translate('no_message');
              final timestamp = messageData['timestamp'] as Timestamp?;
              final answers = List<String>.from(
                  messageData['answers']?.map((answer) => answer.toString()) ??
                      []);

              return ListTile(
                title: Text(companyName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${AppLocalizations.of(context)!.translate('message')}: $message'),
                    if (timestamp != null)
                      Text(
                          '${AppLocalizations.of(context)!.translate('sent_at')}: ${timestamp.toDate()}'),
                    ...answers.map((answer) => Text(answer)).toList(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
