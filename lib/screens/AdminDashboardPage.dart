// ignore: file_names
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:regalofficial/screens/AdminDashboardPage.dart'; // Import the admin dashboard page

class AdminDashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('companyRequests')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                DocumentSnapshot request = snapshot.data!.docs[index];
                return ListTile(
                  title: Text(request['companyName']),
                  subtitle: Text(request['representativeFirstName'] +
                      ' ' +
                      request['representativeLastName']),
                  trailing: ElevatedButton(
                    onPressed: () {
                      approveRequest(request.id);
                    },
                    child: Text('Approve'),
                  ),
                );
              },
            );
          }
          return Center(
            child: Text('No pending requests'),
          );
        },
      ),
    );
  }

  Future<void> approveRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('companyRequests')
          .doc(requestId)
          .update({'status': 'approved'});
      // Display a success message or perform other necessary actions here
    } catch (e) {
      print('Error approving request: $e');
      // Handle errors here
    }
  }
}
