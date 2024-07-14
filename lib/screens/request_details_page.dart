import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:regalofficial/app_localizations.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

class RequestDetailsPage extends StatefulWidget {
  final DocumentSnapshot request;

  RequestDetailsPage({required this.request});

  @override
  _RequestDetailsPageState createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  static const platform =
      MethodChannel('com.example.regalofficial/url_launcher');
  late Map<String, dynamic> requestData;
  bool showCongratulation = false;
  final TextEditingController _rejectionReasonController =
      TextEditingController();
  final List<String> highlightedFields = [];
  String currentTime = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    requestData = widget.request.data() as Map<String, dynamic>;
    setState(() {
      showCongratulation = requestData['status'] == 'approved';
    });
    _updateTime();
    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) => _updateTime());
    _requestPermissions();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    final formattedTime = "${now.hour}:${now.minute}:${now.second}";
    if (mounted) {
      // Check if the widget is still mounted before calling setState
      setState(() {
        currentTime = formattedTime;
      });
    }
  }

  Future<void> _requestPermissions() async {
    if (await Permission.storage.request().isGranted) {
      // Permissions granted
    } else {
      // Handle the case where the user denies the permission
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!
              .translate('storage_permission_denied')),
        ),
      );
    }
  }

  void approveRequest() {
    FirebaseFirestore.instance
        .collection('companyRequests')
        .doc(widget.request.id)
        .update({'status': 'approved'}).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.translate('request_approved'))),
      );
      setState(() {
        showCongratulation = true;
      });
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.translate('error_approving_request')}: $error')),
      );
    });
  }

  void rejectRequest() {
    if (_rejectionReasonController.text.isEmpty && highlightedFields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!
                .translate('provide_reason_and_highlight_fields'))),
      );
      return;
    }

    FirebaseFirestore.instance
        .collection('companyRequests')
        .doc(widget.request.id)
        .update({
      'status': 'rejected',
      'rejectionReason': _rejectionReasonController.text,
      'highlightedFields': highlightedFields,
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.translate('request_rejected'))),
      );
      setState(() {
        showCongratulation = false;
      });
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.translate('error_rejecting_request')}: $error')),
      );
    });
  }

  Future<void> _printPdf() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Table.fromTextArray(
              context: context,
              data: <List<String>>[
                <String>['Field', 'Value'],
                ...requestData.entries
                    .map((entry) => [entry.key, entry.value.toString()]),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      print('Error printing PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context)!.translate('error_printing_pdf')),
        ),
      );
    }
  }

  Future<void> _launchURL(String url) async {
    print('Attempting to launch URL: $url');
    try {
      await platform.invokeMethod('launchURL', {'url': url});
      print('URL launched successfully');
    } on PlatformException catch (e) {
      print("Failed to launch URL: ${e.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not open the file"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('request_details')),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppLocalizations.of(context)!.translate('company_name')}: ${requestData['companyName'] ?? ''}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '${AppLocalizations.of(context)!.translate('representative')}: ${requestData['representativeFirstName']} ${requestData['representativeLastName']}',
            ),
            SizedBox(height: 8),
            Text(
              '${AppLocalizations.of(context)!.translate('current_time')}: $currentTime',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            if (requestData['imageUrl'] != null &&
                requestData['imageUrl'].isNotEmpty)
              Image.network(
                requestData['imageUrl'],
                errorBuilder: (context, error, stackTrace) {
                  return Text(AppLocalizations.of(context)!
                      .translate('could_not_load_image'));
                },
              ),
            if (requestData['fileUrl'] != null &&
                requestData['fileUrl'].isNotEmpty)
              InkWell(
                onTap: () => _launchURL(requestData['fileUrl']),
                child: Text(
                  requestData['fileUrl']
                      .split('/')
                      .last, // Display the file name
                  style: TextStyle(
                      color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ),
            SizedBox(height: 16),
            buildDetailsTable(requestData),
            SizedBox(height: 16),
            buildActionButtons(),
            if (showCongratulation) congratulatoryMessage(),
            SizedBox(height: 20),
            TextFormField(
              controller: _rejectionReasonController,
              decoration: InputDecoration(
                labelText:
                    AppLocalizations.of(context)!.translate('rejection_reason'),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Wrap(
              spacing: 10,
              children: [
                buildChip('companyName'),
                buildChip('commercialRegister'),
                buildChip('companyAddress'),
                buildChip('companyNumber'),
                buildChip('companyEmail'),
                buildChip('representativeFirstName'),
                buildChip('representativeLastName'),
                buildChip('representativePhone'),
                buildChip('representativeEmail'),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _printPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: Text(AppLocalizations.of(context)!
                  .translate('print_details_as_pdf')),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDetailsTable(Map<String, dynamic> data) {
    return Table(
      border: TableBorder.all(),
      columnWidths: {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
      },
      children: data.entries.map((entry) {
        return TableRow(
          children: [
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  AppLocalizations.of(context)!.translate(entry.key),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(entry.value.toString()),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: approveRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: Text(AppLocalizations.of(context)!.translate('approve')),
        ),
        ElevatedButton(
          onPressed: rejectRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: Text(AppLocalizations.of(context)!.translate('reject')),
        ),
      ],
    );
  }

  Widget congratulatoryMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        AppLocalizations.of(context)!
            .translate('congratulations_access_adspage'),
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildChip(String field) {
    return FilterChip(
      label: Text(AppLocalizations.of(context)!.translate(field)),
      selected: highlightedFields.contains(field),
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            highlightedFields.add(field);
          } else {
            highlightedFields.remove(field);
          }
        });
      },
    );
  }
}
