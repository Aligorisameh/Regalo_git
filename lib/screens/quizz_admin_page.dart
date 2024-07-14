import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:regalofficial/app_localizations.dart';

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String? playerId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPlayerId();
  }

  Future<void> fetchPlayerId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        playerId = user.uid;
      });
      await fetchUserProfile();
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchUserProfile() async {
    if (playerId != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(playerId)
          .get();
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _emailController.text = data['email'] ?? '';
          _nameController.text = data['username'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
        });
      }
    }
  }

  Future<void> updateUserProfile() async {
    if (_formKey.currentState!.validate()) {
      if (playerId != null) {
        try {
          DocumentReference userRef =
              FirebaseFirestore.instance.collection('users').doc(playerId);

          await userRef.update({
            'email': _emailController.text,
            'username': _nameController.text,
            'phone': _phoneController.text,
            'address': _addressController.text,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!
                    .translate('profile_updated_successfully'))),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!
                    .translate('failed_to_update_profile'))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('user_profile')),
        backgroundColor: Colors.green[700],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations
                                .translate('please_enter_your_email');
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: localizations.translate('name'),
                          labelStyle: TextStyle(color: Colors.green[800]),
                          fillColor: Colors.green[50],
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations
                                .translate('please_enter_your_name');
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: localizations.translate('phone'),
                          labelStyle: TextStyle(color: Colors.green[800]),
                          fillColor: Colors.green[50],
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations
                                .translate('please_enter_your_phone_number');
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: localizations.translate('address'),
                          labelStyle: TextStyle(color: Colors.green[800]),
                          fillColor: Colors.green[50],
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations
                                .translate('please_enter_your_address');
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 30),
                      Center(
                        child: ElevatedButton(
                          onPressed: updateUserProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child:
                              Text(localizations.translate('update_profile')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class QuizzAdminPage extends StatefulWidget {
  @override
  _QuizzAdminPageState createState() => _QuizzAdminPageState();
}

class _QuizzAdminPageState extends State<QuizzAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _choice1Controller = TextEditingController();
  final TextEditingController _choice2Controller = TextEditingController();
  final TextEditingController _choice3Controller = TextEditingController();
  final TextEditingController _correctAnswerController =
      TextEditingController();
  String? _selectedCategory;
  String? _selectedLanguage;
  int _questionCount = 0; // Counter for questions

  final List<String> _englishCategories = [
    'Geography',
    'Sport',
    'History',
    'Famous',
    'Culture',
    'Health'
  ];

  final List<String> _arabicCategories = [
    'جغرافية',
    'رياضة',
    'تاريخ',
    'مشهور',
    'ثقافة',
    'صحة'
  ];

  List<String> _categories = [];
  final List<String> _languages = ['English', 'Arabic'];

  List<Map<String, dynamic>> _questions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Quiz Questions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  decoration: InputDecoration(labelText: 'Language'),
                  items: _languages.map((String language) {
                    return DropdownMenuItem<String>(
                      value: language,
                      child: Text(language),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedLanguage = newValue;
                      _categories = newValue == 'Arabic'
                          ? _arabicCategories
                          : _englishCategories;
                      _selectedCategory = null; // Reset selected category
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a language';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(labelText: 'Category'),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _questionController,
                  decoration: InputDecoration(labelText: 'Question'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a question';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _choice1Controller,
                  decoration: InputDecoration(labelText: 'Choice 1'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the first choice';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _choice2Controller,
                  decoration: InputDecoration(labelText: 'Choice 2'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the second choice';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _choice3Controller,
                  decoration: InputDecoration(labelText: 'Choice 3'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the third choice';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _correctAnswerController,
                  decoration: InputDecoration(labelText: 'Correct Answer'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the correct answer';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitQuestion,
                  child: Text('Submit Question'),
                ),
                if (_questionCount == 3) ...[
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitQuiz,
                    child: Text('Submit Quiz'),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitQuestion() async {
    if (_formKey.currentState!.validate()) {
      // Gather the data
      String category = _selectedCategory!;
      String question = _questionController.text;
      String choice1 = _choice1Controller.text;
      String choice2 = _choice2Controller.text;
      String choice3 = _choice3Controller.text;
      String correctAnswer = _correctAnswerController.text;

      // Add the question to the list
      _questions.add({
        'question': question,
        'choices': [choice1, choice2, choice3],
        'correctAnswer': correctAnswer,
      });

      // Clear the form for the next question
      _formKey.currentState!.reset();
      setState(() {
        _selectedCategory = category; // Keep the same category selected
        _questionCount++;
      });

      // Show a message when 3 questions are added
      if (_questionCount == 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('3 questions added. You can now submit the quiz.')),
        );
      }
    }
  }

  Future<void> _submitQuiz() async {
    if (_selectedCategory != null &&
        _questions.length == 3 &&
        _selectedLanguage != null) {
      // Store in Firestore
      await FirebaseFirestore.instance.collection('QuizzAdmin').add({
        'category': _selectedCategory,
        'questions': _questions,
        'language': _selectedLanguage,
      });

      // Clear the form
      setState(() {
        _questions.clear();
        _questionCount = 0;
        _selectedCategory = null;
        _selectedLanguage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quiz added successfully')),
      );
    }
  }
}
