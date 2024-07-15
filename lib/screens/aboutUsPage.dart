import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AboutUsPage extends StatelessWidget {
  final List<Map<String, String>> lottieFiles = [
    {'file': 'assets/1.json', 'name': '1.json'},
    {'file': 'assets/2.json', 'name': '2.json'},
    {'file': 'assets/3.json', 'name': '3.json'},
    {'file': 'assets/4.json', 'name': '4.json'},
    {'file': 'assets/correct_answer.json', 'name': 'correct_answer.json'},
    {'file': 'assets/error.json', 'name': 'error.json'},
    {
      'file': 'assets/emoji_end_question.json',
      'name': 'emoji_end_question.json'
    },
    {'file': 'assets/celebrations.json', 'name': 'celebrations.json'},
    {'file': 'assets/celebration1.json', 'name': 'celebration1.json'},
    {
      'file': 'assets/all_question_error.json',
      'name': 'all_question_error.json'
    },
    {'file': 'assets/congrats.json', 'name': 'congrats.json'},
    {'file': 'assets/wait.json', 'name': 'wait.json'},
    {'file': 'assets/sorry.json', 'name': 'sorry.json'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About Us'),
      ),
      body: Container(
        color: Colors.green, // Définir le fond vert
        child: ListView.builder(
          itemCount: lottieFiles.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: SizedBox(
                width: 150, // Augmenter la largeur
                height: 150, // Augmenter la hauteur
                child: Lottie.asset(lottieFiles[index]['file']!),
              ),
              title: Text(lottieFiles[index]['name']!),
            );
          },
        ),
      ),
    );
  }
}
