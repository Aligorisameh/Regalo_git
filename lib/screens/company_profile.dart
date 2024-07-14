import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:regalofficial/app_localizations.dart'; // Ensure you are using AppLocalizations

class CompanyProfilePage extends StatefulWidget {
  final String companyEmail;
  final Map<String, dynamic>? adData;

  const CompanyProfilePage(
      {super.key, required this.companyEmail, this.adData});

  @override
  _CompanyProfilePageState createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  String _selectedType = 'Basic';
  List<Map<String, dynamic>> _questions = [
    {
      'question': '',
      'choices': ['', '', ''],
      'correctAnswer': '',
      'explanation': ''
    },
    {
      'question': '',
      'choices': ['', '', ''],
      'correctAnswer': '',
      'explanation': ''
    },
    {
      'question': '',
      'choices': ['', '', ''],
      'correctAnswer': '',
      'explanation': ''
    },
  ];

  VideoPlayerController? _controller;
  final List<String> _imageUrls = ['', '', '']; // Initialize with empty strings
  String? _videoUrl;
  String companyName = 'Unknown Company';

  @override
  void initState() {
    super.initState();
    if (widget.adData != null) {
      _populateFields();
    } else {
      fetchCompanyName();
    }
  }

  void _populateFields() {
    setState(() {
      companyName = widget.adData!['companyName'] ?? 'Unknown Company';
      _selectedType = widget.adData!['selectedType'] ?? 'Basic';
      _questions =
          List<Map<String, dynamic>>.from(widget.adData!['questions'] ?? []);
      _imageUrls.addAll(List<String>.from(widget.adData!['imageUrls'] ?? []));
      _videoUrl = widget.adData!['videoUrl'];
      if (_videoUrl != null) {
        _controller = VideoPlayerController.network(_videoUrl!)
          ..initialize().then((_) {
            setState(() {});
          });
      }
    });
  }

  Future<void> fetchCompanyName() async {
    print('Fetching company name for email: ${widget.companyEmail}');
    try {
      QuerySnapshot requestSnapshot = await FirebaseFirestore.instance
          .collection('companyRequests')
          .where('companyEmail', isEqualTo: widget.companyEmail)
          .get();
      if (requestSnapshot.docs.isNotEmpty) {
        setState(() {
          companyName = requestSnapshot.docs.first['companyName'];
        });
        print('Company name found: $companyName');
      } else {
        print(
            'No matching company request found for email: ${widget.companyEmail}');
      }
    } catch (e) {
      print('Error fetching company name: $e');
    }
  }

  Future<void> uploadImage(int index) async {
    XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 800,
      maxHeight: 600,
    );

    if (image != null) {
      String imageUrl = await uploadImageToStorage(File(image.path));
      setState(() {
        _imageUrls[index] = imageUrl;
      });
      print('Uploaded image URL: $_imageUrls[index]');
    }
  }

  Future<void> uploadVideo() async {
    XFile? videoFile = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 30),
    );

    if (videoFile != null) {
      String videoUrl = await uploadVideoToStorage(File(videoFile.path));
      setState(() {
        _videoUrl = videoUrl;
        _controller = VideoPlayerController.file(File(videoFile.path));
        _controller!.initialize().then((_) {
          setState(() {});
        });
      });
    }
  }

  Future<String> uploadImageToStorage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString() +
          '_' +
          imageFile.path.split('/').last;

      await firebase_storage.FirebaseStorage.instance
          .ref('images/$fileName')
          .putFile(imageFile);

      String downloadURL = await firebase_storage.FirebaseStorage.instance
          .ref('images/$fileName')
          .getDownloadURL();

      return downloadURL;
    } catch (e) {
      print('Error uploading image: $e');
      return '';
    }
  }

  Future<String> uploadVideoToStorage(File videoFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString() +
          '_' +
          videoFile.path.split('/').last;

      await firebase_storage.FirebaseStorage.instance
          .ref('videos/$fileName')
          .putFile(videoFile);

      String downloadURL = await firebase_storage.FirebaseStorage.instance
          .ref('videos/$fileName')
          .getDownloadURL();

      return downloadURL;
    } catch (e) {
      print('Error uploading video: $e');
      return '';
    }
  }

  void submitForm() async {
    CollectionReference companies =
        FirebaseFirestore.instance.collection('companies');

    // Fetch the current count of ads to generate a unique ad number
    QuerySnapshot companySnapshot = await companies.get();
    int adNumber = companySnapshot.size + 1;

    await companies.add({
      'companyName': companyName,
      'selectedType': _selectedType,
      'questions': _questions,
      'imageUrls': _imageUrls,
      'videoUrl': _videoUrl,
      'isPublished': false, // Initial state set to false
      'adNumber': adNumber, // Unique ad number
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('success')),
          content: Text(AppLocalizations.of(context)!.translate('data_saved')),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.translate('ok')),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${localizations.translate('company_profile')} - $companyName'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BlinkText(
              localizations.translate('all_fields_obligatory'),
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${localizations.translate('company_email')}: ${widget.companyEmail}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              localizations.translate('thank_you_choose_ad_type'),
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[800],
              ),
            ),
            DropdownButton<String>(
              value: _selectedType,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedType = newValue!;
                });
              },
              items: <String>['Gold', 'Silver', 'Basic']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              localizations.translate('thank_you_upload_images'),
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[800],
              ),
            ),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () => uploadImage(0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(localizations.translate('upload_image') + ' 1'),
                ),
                const SizedBox(height: 10.0),
                ElevatedButton(
                  onPressed: () => uploadImage(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(localizations.translate('upload_image') + ' 2'),
                ),
                const SizedBox(height: 10.0),
                ElevatedButton(
                  onPressed: () => uploadImage(2),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(localizations.translate('upload_image') + ' 3'),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            if (_imageUrls.isNotEmpty) ...[
              Text(
                localizations.translate('uploaded_images'),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green[800],
                ),
              ),
              Wrap(
                spacing: 10.0,
                children: _imageUrls.map((url) {
                  return url.isNotEmpty
                      ? Image.network(
                          url,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : Container();
                }).toList(),
              ),
              const SizedBox(height: 20.0),
            ],
            Text(
              localizations.translate('thank_you_upload_video'),
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[800],
              ),
            ),
            ElevatedButton(
              onPressed: uploadVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(localizations.translate('upload_video_ads')),
            ),
            const SizedBox(height: 20.0),
            Text(
              localizations.translate('upload_questions_quiz'),
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[800],
              ),
            ),
            for (int i = 0; i < _questions.length; i++)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText:
                          '${localizations.translate('question')} ${i + 1}',
                      labelStyle: TextStyle(color: Colors.green[800]),
                      fillColor: Colors.green[50],
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      errorText: widget.adData?['rejectedFields']
                                  ?.contains('question_${i + 1}') ??
                              false
                          ? localizations.translate('incorrect')
                          : null,
                    ),
                    initialValue: _questions[i]['question'],
                    onChanged: (value) {
                      _questions[i]['question'] = value;
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    localizations.translate('choices'),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[800],
                    ),
                  ),
                  for (int j = 0; j < _questions[i]['choices'].length; j++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText:
                              '${localizations.translate('choice')} ${j + 1}',
                          labelStyle: TextStyle(color: Colors.green[800]),
                          fillColor: Colors.green[50],
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          errorText: widget.adData?['rejectedFields']
                                      ?.contains('choice_${i + 1}_$j') ??
                                  false
                              ? localizations.translate('incorrect')
                              : null,
                        ),
                        initialValue: _questions[i]['choices'][j],
                        onChanged: (value) {
                          _questions[i]['choices'][j] = value;
                        },
                      ),
                    ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: localizations.translate('correct_answer'),
                      labelStyle: TextStyle(color: Colors.green[800]),
                      fillColor: Colors.green[50],
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      errorText: widget.adData?['rejectedFields']
                                  ?.contains('correctAnswer_${i + 1}') ??
                              false
                          ? localizations.translate('incorrect')
                          : null,
                    ),
                    initialValue: _questions[i]['correctAnswer'],
                    onChanged: (value) {
                      _questions[i]['correctAnswer'] = value;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: localizations.translate('explanation'),
                      labelStyle: TextStyle(color: Colors.green[800]),
                      fillColor: Colors.green[50],
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      errorText: widget.adData?['rejectedFields']
                                  ?.contains('explanation_${i + 1}') ??
                              false
                          ? localizations.translate('incorrect')
                          : null,
                    ),
                    initialValue: _questions[i]['explanation'],
                    onChanged: (value) {
                      _questions[i]['explanation'] = value;
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(localizations.translate('submit')),
            ),
          ],
        ),
      ),
    );
  }
}

class BlinkText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const BlinkText(this.text, {required this.style});

  @override
  _BlinkTextState createState() => _BlinkTextState();
}

class _BlinkTextState extends State<BlinkText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _colorAnimation = ColorTween(begin: Colors.red, end: Colors.transparent)
        .animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _controller.forward();
        }
      });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Text(
          widget.text,
          style: widget.style.copyWith(color: _colorAnimation.value),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    title: 'Company Profile Page',
    home: CompanyProfilePage(
      companyEmail: 'your-email@example.com', // replace with actual email
    ),
  ));
}
