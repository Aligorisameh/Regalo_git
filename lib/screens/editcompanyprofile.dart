import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:io';
import 'package:regalofficial/app_localizations.dart'; // Ensure you are using AppLocalizations

class EditCompanyProfilePage extends StatefulWidget {
  final String companyName;
  final String companyEmail;
  final String imageUrl;
  final String bio;

  EditCompanyProfilePage({
    required this.companyName,
    required this.companyEmail,
    required this.imageUrl,
    required this.bio,
  });

  @override
  _EditCompanyProfilePageState createState() => _EditCompanyProfilePageState();
}

class _EditCompanyProfilePageState extends State<EditCompanyProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _imageUrlController;
  late TextEditingController _bioController;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.companyName);
    _emailController = TextEditingController(text: widget.companyEmail);
    _imageUrlController = TextEditingController(text: widget.imageUrl);
    _bioController = TextEditingController(text: widget.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _imageUrlController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await _uploadImageToFirebase();
    }
  }

  Future<void> _uploadImageToFirebase() async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final firebase_storage.Reference storageRef = firebase_storage
          .FirebaseStorage.instance
          .ref()
          .child('uploads/$fileName');
      final firebase_storage.UploadTask uploadTask =
          storageRef.putFile(_imageFile!);

      final firebase_storage.TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      if (mounted) {
        setState(() {
          _imageUrlController.text = downloadUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        print(
            '${AppLocalizations.of(context)!.translate('error_uploading_image')}: $e');
        // Show error message to the user
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      // Fetch the document ID for the given companyEmail
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('companyRequests')
          .where('companyEmail', isEqualTo: widget.companyEmail)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot docSnapshot = querySnapshot.docs.first;

        await FirebaseFirestore.instance
            .collection('companyRequests')
            .doc(docSnapshot.id)
            .update({
          'companyName': _nameController.text,
          'companyEmail': _emailController.text,
          'imageUrl': _imageUrlController.text,
          'bio': _bioController.text,
        });

        if (mounted) {
          Navigator.pop(context, {
            'companyName': _nameController.text,
            'companyEmail': _emailController.text,
            'imageUrl': _imageUrlController.text,
            'bio': _bioController.text,
          });
        }
      } else {
        if (mounted) {
          print(
              '${AppLocalizations.of(context)!.translate('no_document_found')}: ${widget.companyEmail}');
        }
      }
    } catch (e) {
      if (mounted) {
        print(
            '${AppLocalizations.of(context)!.translate('error_updating_profile')}: $e');
        // Show error message to the user
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('edit_company_profile')),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: localizations.translate('company_name'),
                  labelStyle: TextStyle(color: Colors.green[800]),
                  fillColor: Colors.green[50],
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: localizations.translate('email'),
                  labelStyle: TextStyle(color: Colors.green[800]),
                  fillColor: Colors.green[50],
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: localizations.translate('image_url'),
                  labelStyle: TextStyle(color: Colors.green[800]),
                  fillColor: Colors.green[50],
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(localizations.translate('upload_new_image')),
              ),
              SizedBox(height: 16),
              _imageFile != null
                  ? Image.file(_imageFile!)
                  : widget.imageUrl.isNotEmpty
                      ? Image.network(widget.imageUrl)
                      : Container(),
              SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: localizations.translate('bio'),
                  labelStyle: TextStyle(color: Colors.green[800]),
                  fillColor: Colors.green[50],
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(localizations.translate('save')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
