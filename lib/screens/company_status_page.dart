import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:regalofficial/CompanyDetailsPage.dart';
import 'package:regalofficial/app_localizations.dart'; // تأكد من استخدام AppLocalizations

class CompanyStatusPage extends StatefulWidget {
  @override
  _CompanyStatusPageState createState() => _CompanyStatusPageState();
}

class _CompanyStatusPageState extends State<CompanyStatusPage> {
  String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('company_status')),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('companyRequests')
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text(
                '${AppLocalizations.of(context)!.translate('error')}: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (BuildContext context, int index) {
              Map<String, dynamic> data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String companyName = data['companyName'] ?? '';
              String status = data['status'] ?? '';

              Color backgroundColor = Colors.white;

              switch (status) {
                case 'Approved':
                  backgroundColor = Colors.green;
                  break;
                case 'Rejected':
                  backgroundColor = Colors.red;
                  break;
                case 'Pending':
                  backgroundColor = Colors.yellow;
                  break;
                default:
                  backgroundColor = Colors.white;
                  break;
              }

              return InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CompanyDetailsPage(
                        companyName: companyName,
                        status: status,
                        commercialRegister: data['commercialRegister'],
                        companyAddress: data['companyAddress'],
                        companyNumber: data['companyNumber'],
                        companyEmail: data['companyEmail'],
                        representativeFirstName:
                            data['representativeFirstName'],
                        representativeLastName: data['representativeLastName'],
                        representativePhone: data['representativePhone'],
                        representativeEmail: data['representativeEmail'],
                        onSubmitMessage: (String message) {
                          return FirebaseFirestore.instance
                              .collection('companyMessages')
                              .add({
                            'companyName': companyName,
                            'message': message,
                            'timestamp': FieldValue.serverTimestamp(),
                          }).then((_) =>
                                  '${AppLocalizations.of(context)!.translate('message_submitted')}: $message');
                        },
                      ),
                    ),
                  );

                  if (result != null) {
                    setState(() {
                      message = result as String;
                    });
                  }
                },
                child: Container(
                  color: backgroundColor,
                  padding: const EdgeInsets.all(16.0),
                  child: ListTile(
                    title: Text(companyName),
                    subtitle: Text(
                        '${AppLocalizations.of(context)!.translate('status')}: $status'),
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
