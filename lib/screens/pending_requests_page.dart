import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:regalofficial/screens/request_details_page.dart';
import 'package:regalofficial/app_localizations.dart';

class PendingRequestsPage extends StatelessWidget {
  final String currentUserEmail;

  PendingRequestsPage({required this.currentUserEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!
            .translate('pending_and_rejected_requests')),
        backgroundColor: Colors.green[700],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('companyRequests')
            .where('status', whereIn: ['pending', 'rejected']).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                  AppLocalizations.of(context)!.translate('error_occurred')),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)!
                  .translate('no_pending_or_rejected_requests')),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (BuildContext context, int index) {
              DocumentSnapshot request = snapshot.data!.docs[index];
              return RequestItem(
                request: request,
              );
            },
          );
        },
      ),
    );
  }
}

class RequestItem extends StatelessWidget {
  final DocumentSnapshot request;

  RequestItem({
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> requestData = request.data() as Map<String, dynamic>;
    bool isNew = requestData['status'] == 'pending' &&
        DateTime.now().difference(requestData['createdAt'].toDate()).inDays < 7;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RequestDetailsPage(
              request: request,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green, Colors.blue, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: ListTile(
          title: Row(
            children: [
              Text(
                requestData['companyName'] ?? '',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isNew) SizedBox(width: 10),
              if (isNew)
                BlinkingText(
                  text: AppLocalizations.of(context)!.translate('new'),
                  color: Colors.red,
                ),
            ],
          ),
          subtitle: Text(
            '${requestData['representativeFirstName']} ${requestData['representativeLastName']}',
            style: TextStyle(color: Colors.white),
          ),
          trailing: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RequestDetailsPage(
                    request: request,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('details'),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class BlinkingText extends StatefulWidget {
  final String text;
  final Color color;

  BlinkingText({required this.text, required this.color});

  @override
  _BlinkingTextState createState() => _BlinkingTextState();
}

class _BlinkingTextState extends State<BlinkingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat(reverse: true);
    _opacity = Tween(begin: 1.0, end: 0.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Text(
        widget.text,
        style: TextStyle(
          color: widget.color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
