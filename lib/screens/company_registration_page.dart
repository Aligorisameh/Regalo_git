import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:regalofficial/app_localizations.dart'; // Ensure you are using AppLocalizations

class CompanyRegistrationPage extends StatefulWidget {
  final String companyEmail;
  final List<String> highlightedFields;
  final Function onSubmitted;

  CompanyRegistrationPage({
    this.companyEmail = '',
    this.highlightedFields = const [],
    required this.onSubmitted,
  });

  @override
  _CompanyRegistrationPageState createState() =>
      _CompanyRegistrationPageState();
}

class _CompanyRegistrationPageState extends State<CompanyRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _commercialRegisterController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyNumberController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _representativeFirstNameController = TextEditingController();
  final _representativeLastNameController = TextEditingController();
  final _representativePhoneController = TextEditingController();
  final _representativeEmailController = TextEditingController();
  final _bioController = TextEditingController();
  XFile? image;
  File? file; // Store the picked file
  String imageUrl = ''; // Store the picked image file URL
  String fileUrl = ''; // Store the picked file URL
  bool _isSubmitted = false; // Track submission status

  @override
  void initState() {
    super.initState();
    fetchCompanyDetails();
  }

  Future<void> pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? selectedImage =
        await _picker.pickImage(source: ImageSource.gallery);

    if (selectedImage != null) {
      setState(() {
        image = selectedImage;
      });
    }
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        file = File(result.files.single.path!);
        print('File selected: ${file!.path}');
      });
    } else {
      print('No file selected');
    }
  }

  Future<String> uploadImage() async {
    if (image == null) {
      print('No image selected');
      return '';
    }

    File file = File(image!.path);
    String fileName =
        'uploads/${DateTime.now().millisecondsSinceEpoch}_${image!.name}';
    firebase_storage.Reference ref =
        firebase_storage.FirebaseStorage.instance.ref(fileName);

    firebase_storage.UploadTask uploadTask = ref.putFile(file);
    await uploadTask.whenComplete(() => null);
    String downloadUrl = await ref.getDownloadURL();
    print('Download URL: $downloadUrl'); // Check the URL in console
    return downloadUrl;
  }

  Future<String> uploadFile() async {
    if (file == null) {
      print('No file selected');
      return '';
    }

    String fileName =
        'uploads/${DateTime.now().millisecondsSinceEpoch}_${file!.path.split('/').last}';
    firebase_storage.Reference ref =
        firebase_storage.FirebaseStorage.instance.ref(fileName);

    firebase_storage.UploadTask uploadTask = ref.putFile(file!);
    await uploadTask.whenComplete(() => null);
    String downloadUrl = await ref.getDownloadURL();
    print('File Download URL: $downloadUrl'); // Check the URL in console
    return downloadUrl;
  }

  Future<void> fetchCompanyDetails() async {
    if (widget.companyEmail.isNotEmpty) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('companyRequests')
          .where('companyEmail', isEqualTo: widget.companyEmail)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot snapshot = querySnapshot.docs.first;
        var userData = snapshot.data() as Map<String, dynamic>?;
        if (userData != null) {
          setState(() {
            _companyNameController.text = userData['companyName'] ?? '';
            _commercialRegisterController.text =
                userData['commercialRegister'] ?? '';
            _companyAddressController.text = userData['companyAddress'] ?? '';
            _companyNumberController.text = userData['companyNumber'] ?? '';
            _companyEmailController.text = userData['companyEmail'] ?? '';
            _representativeFirstNameController.text =
                userData['representativeFirstName'] ?? '';
            _representativeLastNameController.text =
                userData['representativeLastName'] ?? '';
            _representativePhoneController.text =
                userData['representativePhone'] ?? '';
            _representativeEmailController.text =
                userData['representativeEmail'] ?? '';
            _bioController.text = userData['bio'] ?? '';
            imageUrl = userData['imageUrl'] ?? '';
            fileUrl = userData['fileUrl'] ?? '';
          });
        }
      }
    }
  }

  void submitRequest() async {
    if (_formKey.currentState!.validate()) {
      String imageUrl = await uploadImage();
      String fileUrl = await uploadFile();
      int requestNumber = await getRequestNumber(widget.companyEmail);

      FirebaseFirestore.instance.collection('companyRequests').add({
        'companyName': _companyNameController.text,
        'commercialRegister': _commercialRegisterController.text,
        'companyAddress': _companyAddressController.text,
        'companyNumber': _companyNumberController.text,
        'companyEmail': _companyEmailController.text,
        'representativeFirstName': _representativeFirstNameController.text,
        'representativeLastName': _representativeLastNameController.text,
        'representativePhone': _representativePhoneController.text,
        'representativeEmail': _representativeEmailController.text,
        'bio': _bioController.text,
        'imageUrl': imageUrl,
        'fileUrl': fileUrl,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'highlightedFields': [], // Reset highlighted fields
        'rejectionReason': '', // Reset rejection reason
        'requestNumber': requestNumber,
      }).then((_) {
        setState(() {
          _isSubmitted = true;
        });
        widget.onSubmitted(); // Notify parent widget about submission
        Navigator.pop(context); // Redirect to the previous page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .translate('request_submitted'))),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                      .translate('error_submitting_request') +
                  ': $error')),
        );
      });
    }
  }

  Future<int> getRequestNumber(String companyEmail) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('companyRequests')
        .where('companyEmail', isEqualTo: companyEmail)
        .get();

    return querySnapshot.docs.length + 1;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('company_registration')),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                buildTextField(
                  controller: _companyNameController,
                  label: localizations.translate('company_name'),
                  highlighted: widget.highlightedFields.contains('companyName'),
                ),
                SizedBox(height: 16),
                buildTextField(
                  controller: _commercialRegisterController,
                  label: localizations.translate('commercial_register'),
                  highlighted:
                      widget.highlightedFields.contains('commercialRegister'),
                ),
                SizedBox(height: 16),
                buildTextField(
                  controller: _companyAddressController,
                  label: localizations.translate('company_address'),
                  highlighted:
                      widget.highlightedFields.contains('companyAddress'),
                ),
                SizedBox(height: 16),
                buildTextField(
                  controller: _companyNumberController,
                  label: localizations.translate('company_number'),
                  highlighted:
                      widget.highlightedFields.contains('companyNumber'),
                ),
                SizedBox(height: 16),
                buildTextField(
                  controller: _companyEmailController,
                  label: localizations.translate('company_email'),
                  highlighted:
                      widget.highlightedFields.contains('companyEmail'),
                ),
                SizedBox(height: 16),
                buildTextField(
                  controller: _representativeFirstNameController,
                  label: localizations.translate('representative_first_name'),
                  highlighted: widget.highlightedFields
                      .contains('representativeFirstName'),
                ),
                SizedBox(height: 16),
                buildTextField(
                  controller: _representativeLastNameController,
                  label: localizations.translate('representative_last_name'),
                  highlighted: widget.highlightedFields
                      .contains('representativeLastName'),
                ),
                SizedBox(height: 16),
                buildTextField(
                  controller: _representativePhoneController,
                  label: localizations.translate('representative_phone'),
                  highlighted:
                      widget.highlightedFields.contains('representativePhone'),
                ),
                SizedBox(height: 16),
                buildTextField(
                  controller: _representativeEmailController,
                  label: localizations.translate('representative_email'),
                  highlighted:
                      widget.highlightedFields.contains('representativeEmail'),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(
                    labelText: localizations.translate('company_bio'),
                    labelStyle: TextStyle(color: Colors.green[800]),
                    fillColor: Colors.green[50],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                if (image != null) Image.file(File(image!.path)),
                ElevatedButton(
                  onPressed: pickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(localizations.translate('upload_image')),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: pickFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(localizations.translate('upload_pdf')),
                ),
                if (file != null)
                  Text(
                    localizations.translate('file_selected') +
                        ' ${file!.path.split('/').last}',
                  ),
                SizedBox(height: 20),
                if (!_isSubmitted)
                  Center(
                    child: ElevatedButton(
                      onPressed: submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding:
                            EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(localizations.translate('submit')),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    bool highlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.green[800]),
          fillColor: highlighted ? Colors.red[50] : Colors.green[50],
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}
