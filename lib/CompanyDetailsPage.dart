import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyDetailsPage extends StatefulWidget {
  final String companyName;
  final String? status;
  final String? commercialRegister;
  final String? companyAddress;
  final String? companyNumber;
  final String? companyEmail;
  final String? representativeFirstName;
  final String? representativeLastName;
  final String? representativePhone;
  final String? representativeEmail;
  final Function(String) onSubmitMessage;

  const CompanyDetailsPage({
    super.key,
    required this.companyName,
    this.status,
    this.commercialRegister,
    this.companyAddress,
    this.companyNumber,
    this.companyEmail,
    this.representativeFirstName,
    this.representativeLastName,
    this.representativePhone,
    this.representativeEmail,
    required this.onSubmitMessage,
  });

  @override
  _CompanyDetailsPageState createState() => _CompanyDetailsPageState();
}

class _CompanyDetailsPageState extends State<CompanyDetailsPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submitMessage() async {
    String submittedMessage = _messageController.text;
    if (submittedMessage.isNotEmpty) {
      await widget.onSubmitMessage(submittedMessage);
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message submitted successfully')),
      );
      Navigator.pop(context, 'Message submitted: $submittedMessage');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
    }
  }

  Future<void> _submitAnswer(String messageId) async {
    String answer = _answerController.text;
    if (answer.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('companyMessages')
          .doc(messageId)
          .update({'answer': answer});
      _answerController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer submitted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an answer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Company Name: ${widget.companyName}'),
            if (widget.status != null) Text('Status: ${widget.status}'),
            if (widget.commercialRegister != null)
              Text('Commercial Register: ${widget.commercialRegister}'),
            if (widget.companyAddress != null)
              Text('Company Address: ${widget.companyAddress}'),
            if (widget.companyNumber != null)
              Text('Company Number: ${widget.companyNumber}'),
            if (widget.companyEmail != null)
              Text('Company Email: ${widget.companyEmail}'),
            if (widget.representativeFirstName != null)
              Text(
                  'Representative First Name: ${widget.representativeFirstName}'),
            if (widget.representativeLastName != null)
              Text(
                  'Representative Last Name: ${widget.representativeLastName}'),
            if (widget.representativePhone != null)
              Text('Representative Phone: ${widget.representativePhone}'),
            if (widget.representativeEmail != null)
              Text('Representative Email: ${widget.representativeEmail}'),
            const SizedBox(height: 16),
            const Text(
              'Leave a Message',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type your message here...',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitMessage,
              child: const Text('Submit Message'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Answer a Message',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _answerController,
              decoration: const InputDecoration(
                hintText: 'Type your answer here...',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _submitAnswer(
                  'messageId'), // Replace 'messageId' with actual ID
              child: const Text('Submit Answer'),
            ),
          ],
        ),
      ),
    );
  }
}
