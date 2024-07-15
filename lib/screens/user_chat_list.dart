import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_page.dart';

class UserSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select User to Chat'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              var userEmail = user['email'] ?? 'No email';
              var userType = user['userType'] ?? 'Unknown';

              return ListTile(
                title: Text(userEmail),
                subtitle: Text(userType),
                onTap: () {
                  String chatId = 'admin_${user.id}';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        chatId: chatId,
                        receiverEmail: userEmail,
                        receiverType: userType,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
