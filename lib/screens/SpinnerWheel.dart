import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:math';
import 'package:lottie/lottie.dart';
import 'package:regalofficial/app_localizations.dart';

class SpinnerWheel extends StatefulWidget {
  @override
  _SpinnerWheelState createState() => _SpinnerWheelState();
}

class _SpinnerWheelState extends State<SpinnerWheel>
    with SingleTickerProviderStateMixin {
  final StreamController<int> selected = StreamController<int>.broadcast();
  int currentSelected = 0;
  List<String> categories = [];
  List<Map<String, dynamic>> questions = [];
  bool showStartQuizButton = false;
  bool showSpinAgainButton = false;
  bool isQuizFinished = false;
  int currentQuestionIndex = 0;
  bool showQuestion = false;
  List<bool> answersCorrect = [];
  String? playerId;
  String? selectedAnswer;
  bool showCorrectAnswer = false;
  DateTime? lastSpinTime;
  String selectedLanguage = 'en';

  late AudioPlayer _audioPlayer;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    fetchPlayerId();
    fetchCategories();
    _audioPlayer = AudioPlayer();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    selected.close();
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchPlayerId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        playerId = user.uid;
      });
      print("Player ID: $playerId");
      await fetchPlayerData();
    } else {
      print("No user is signed in.");
    }
  }

  Future<void> fetchPlayerData() async {
    if (playerId != null) {
      DocumentSnapshot playerDoc = await FirebaseFirestore.instance
          .collection('players')
          .doc(playerId)
          .get();
      if (playerDoc.exists) {
        var data = playerDoc.data() as Map<String, dynamic>;
        if (data.containsKey('lastSpinTime')) {
          Timestamp lastSpinTimestamp = data['lastSpinTime'];
          setState(() {
            lastSpinTime = lastSpinTimestamp.toDate();
          });
        } else {
          setState(() {
            lastSpinTime = null;
          });
        }

        if (data.containsKey('points')) {
          print("Player Points: ${data['points']}");
        } else {
          print("No points data found for player.");
        }

        if (data.containsKey('language')) {
          String language = data['language'];
          if (language == 'en' || language == 'ar') {
            setState(() {
              selectedLanguage = language;
            });
          } else {
            setState(() {
              selectedLanguage =
                  'en'; // Default to English if the value is invalid
            });
          }
          print("Fetched Language: $selectedLanguage");
        }
      } else {
        print("Player document does not exist. Creating new player document.");
        await FirebaseFirestore.instance
            .collection('players')
            .doc(playerId)
            .set({
          'playerId': playerId,
          'points': 0,
          'lastSpinTime': null,
          'language': selectedLanguage,
        });
      }
      print("Last Spin Time: $lastSpinTime");
      print("Selected Language: $selectedLanguage");
    }
  }

  Future<void> updatePlayerLanguage(String language) async {
    if (playerId != null) {
      await FirebaseFirestore.instance
          .collection('players')
          .doc(playerId)
          .update({'language': language});
      print("Player language updated to: $language");
    }
  }

  Future<void> fetchCategories() async {
    print("Fetching categories for language: $selectedLanguage");
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('QuizzAdmin')
        .where('language',
            isEqualTo: selectedLanguage == 'en' ? 'English' : 'Arabic')
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        categories = querySnapshot.docs
            .map((doc) => doc['category'] as String? ?? 'Unknown')
            .toList();
      });
      print("Categories fetched: $categories");
    } else {
      print("No categories found for the selected language.");
      setState(() {
        categories = [];
      });
    }
  }

  Future<void> fetchQuestions(String category) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('QuizzAdmin')
        .where('category', isEqualTo: category)
        .get();
    setState(() {
      questions = querySnapshot.docs
          .expand((doc) => (doc['questions'] as List<dynamic>)
              .map((question) => question as Map<String, dynamic>))
          .toList();
      currentQuestionIndex = 0;
      showQuestion = true;
      answersCorrect = List<bool>.filled(questions.length, false);
      showCorrectAnswer = false;
      selectedAnswer = null;
    });
    print("Questions fetched: $questions");
  }

  void startQuiz() {
    fetchQuestions(categories[currentSelected]);
    setState(() {
      lastSpinTime = DateTime.now();
      FirebaseFirestore.instance.collection('players').doc(playerId).update({
        'lastSpinTime': Timestamp.now(),
      });
    });
  }

  Future<void> playAudio(String sound) async {
    try {
      print("Attempting to play: $sound");
      await _audioPlayer.setSource(AssetSource(sound));
      await _audioPlayer.resume();
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  void answerQuestion(String selectedChoice) {
    setState(() {
      selectedAnswer = selectedChoice;
      if (selectedChoice == questions[currentQuestionIndex]['correctAnswer']) {
        answersCorrect[currentQuestionIndex] = true;
        print("Correct answer selected, playing correct-answer.mp3");
        playAudio('audio/correct-answer.mp3');
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Color(0xFFA8E063),
              title: Text(
                  AppLocalizations.of(context)!.translate('correct_answer'),
                  style: TextStyle(color: Color(0xFF56AB2F))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset('assets/correct_answer.json',
                      width: 100, height: 100),
                  Text(
                    'Bravo! Vous avez répondu correctement.',
                    style: TextStyle(color: Color(0xFF56AB2F)),
                  ),
                  SizedBox(height: 20),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK', style: TextStyle(color: Color(0xFF56AB2F))),
                ),
              ],
            );
          },
        );
      } else {
        answersCorrect[currentQuestionIndex] = false;
        print("Wrong answer selected, playing wrong-answer.mp3");
        playAudio('audio/wrong-answer.mp3');
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.red.withOpacity(0.5),
              title: Text('Mauvaise Réponse!',
                  style: TextStyle(color: Colors.black)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset('assets/error.json', width: 100, height: 100),
                  Text('Désolé, ce n\'est pas la bonne réponse.',
                      style: TextStyle(color: Colors.black)),
                  Text(
                      'La bonne réponse est: ${questions[currentQuestionIndex]['correctAnswer']}',
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK', style: TextStyle(color: Colors.black)),
                ),
              ],
            );
          },
        );
      }

      if (currentQuestionIndex < questions.length - 1) {
        Future.delayed(Duration(seconds: 3), () {
          setState(() {
            currentQuestionIndex++;
            selectedAnswer = null;
            showCorrectAnswer = false;
          });
        });
      } else {
        Future.delayed(Duration(seconds: 3), () {
          setState(() {
            showQuestion = false;
            showStartQuizButton = false;
            isQuizFinished = true;
            checkQuizResult();
          });
        });
      }
    });
  }

  Future<void> checkQuizResult() async {
    int correctAnswers = answersCorrect.where((correct) => correct).length;
    int incorrectAnswers = answersCorrect.where((correct) => !correct).length;

    print(
        "Correct Answers: $correctAnswers, Incorrect Answers: $incorrectAnswers");

    if (correctAnswers >= 2 && correctAnswers < questions.length) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.green.withOpacity(0.5),
            title: Text(
                AppLocalizations.of(context)!.translate('quiz_finished'),
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset('assets/emoji_end_question.json',
                    width: 100, height: 100),
                Text(
                    AppLocalizations.of(context)!
                        .translate('correct_answers_message'),
                    style: TextStyle(color: Colors.white)),
                SizedBox(height: 20),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );

      // Updating the points in Firestore
      DocumentReference playerRef =
          FirebaseFirestore.instance.collection('players').doc(playerId);

      DocumentSnapshot playerDoc = await playerRef.get();
      if (playerDoc.exists) {
        int currentPoints = playerDoc['points'];
        print("Current Points: $currentPoints");
        await playerRef.update({
          'points': currentPoints + 5,
        }).then((_) {
          print(
              'Points updated successfully. New points: ${currentPoints + 5}');
          // Show the SnackBar after successful update
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bravo! You earned 5 points.')),
          );
        }).catchError((error) {
          // Handle error if update fails
          print('Error updating points: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update points: $error')),
          );
        });
      } else {
        await playerRef.set({
          'points': 5,
        }).then((_) {
          print('Points set successfully. New points: 5');
          // Show the SnackBar after successful update
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bravo! You earned 5 points.')),
          );
        }).catchError((error) {
          // Handle error if set fails
          print('Error setting points: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to set points: $error')),
          );
        });
      }
    } else if (correctAnswers == questions.length) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.green.withOpacity(0.5),
            title: Text(
                AppLocalizations.of(context)!.translate('quiz_finished'),
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset('assets/celebration1.json',
                    width: 100, height: 100),
                Text(
                    AppLocalizations.of(context)!
                        .translate('all_correct_message'),
                    style: TextStyle(color: Colors.white)),
                SizedBox(height: 20),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Congratulations! You answered all questions correctly.')),
      );
    } else if (incorrectAnswers >= 2) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.red.withOpacity(0.5),
            title: Text(
                AppLocalizations.of(context)!.translate('quiz_finished'),
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset('assets/all_question_error.json',
                    width: 100, height: 100),
                Text(
                    AppLocalizations.of(context)!
                        .translate('too_many_incorrect'),
                    style: TextStyle(color: Colors.white)),
                SizedBox(height: 20),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Sorry, you answered too many questions incorrectly.')),
      );
    }

    Navigator.of(context)
        .pop(); // Close the quiz screen and return to the spinner
  }

  bool canSpin() {
    if (lastSpinTime == null) return true;
    final nextSpinTime = lastSpinTime!.add(Duration(hours: 24));
    return DateTime.now().isAfter(nextSpinTime);
  }

  void handleSpin() {
    if (canSpin()) {
      playAudio('audio/spin_sound.mp3');
      setState(() {
        final random = Random();
        currentSelected = random.nextInt(categories.length); // Random selection
        selected.add(currentSelected);
        showStartQuizButton = true;
        showSpinAgainButton = true;
        isQuizFinished = false;
      });
      playAudio('audio/select_sound.mp3');
      _animationController.forward(from: 0.0);
    } else {
      final nextSpinTime = lastSpinTime!.add(Duration(hours: 24));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Come back tomorrow! You can spin again after ${nextSpinTime.toLocal().toString().split(' ')[0]} ${nextSpinTime.toLocal().toString().split(' ')[1].split('.')[0]}.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: EdgeInsets.all(20),
          duration: Duration(seconds: 5),
          elevation: 10,
          padding: EdgeInsets.all(20),
        ),
      );
    }
  }

  void onLanguageChanged(String? language) {
    if (language != null) {
      setState(() {
        selectedLanguage = language;
      });
      updatePlayerLanguage(language);
      fetchCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('app_title')),
        backgroundColor: Color(0xFF56AB2F), // Dark Green
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (categories.isEmpty)
            Center(
                child: Text(
                    AppLocalizations.of(context)!
                        .translate('not_enough_categories'),
                    style:
                        TextStyle(fontFamily: 'Comic Sans MS', fontSize: 18)))
          else if (showQuestion)
            buildQuiz()
          else
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FortuneWheel(
                    selected: selected.stream,
                    items: categories.map((category) {
                      int index = categories.indexOf(category);
                      return FortuneItem(
                        style: FortuneItemStyle(
                          color: index % 2 == 0
                              ? Color(0xFFFF8008)
                              : Color(0xFFFFC837), // Orange Gradient
                          borderColor: Colors.white,
                          borderWidth: 3,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star, size: 30, color: Colors.white),
                            SizedBox(height: 10),
                            Text(
                              category,
                              style: TextStyle(
                                  color: index == currentSelected &&
                                          !isQuizFinished
                                      ? Colors.red
                                      : Colors.white,
                                  fontFamily: 'Comic Sans MS',
                                  fontSize: 18),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onAnimationEnd: () {
                      setState(() {
                        showStartQuizButton = true;
                        showSpinAgainButton = true;
                        isQuizFinished = false;
                      });
                    },
                  ),
                  Positioned(
                    top: 10,
                    child: ScaleTransition(
                      scale: _animationController,
                      child: Text(
                        '${categories[currentSelected]} Selected! 🎉',
                        style: TextStyle(
                            color: Colors.orange,
                            fontSize: 24,
                            fontFamily: 'Comic Sans MS',
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    child: Icon(
                      Icons.celebration,
                      size: 50,
                      color: Colors.yellow,
                    ),
                  ),
                ],
              ),
            ),
          if (!showQuestion)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                AppLocalizations.of(context)!.translate('preferred_language'),
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Comic Sans MS',
                ),
              ),
            ),
          if (!showQuestion)
            DropdownButton<String>(
              value: selectedLanguage,
              onChanged: onLanguageChanged,
              items: <String>['en', 'ar']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value == 'en' ? 'English' : 'Arabic'),
                );
              }).toList(),
            ),
          if (showSpinAgainButton && !showQuestion && canSpin())
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Type here to choose the category:',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Comic Sans MS',
                ),
              ),
            ),
          if (showSpinAgainButton && !showQuestion && canSpin())
            ElevatedButton(
              onPressed: handleSpin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen, // Light green color
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                elevation: 10, // Adding shadow
              ),
              child: Text(AppLocalizations.of(context)!.translate('spin_again'),
                  style: TextStyle(
                      fontFamily: 'Comic Sans MS',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)), // Styled text
            ),
          if (showStartQuizButton && !showQuestion && canSpin())
            ElevatedButton(
              onPressed: startQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF8008), // Bright color
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                elevation: 10, // Adding shadow
              ),
              child: Text(
                  '${AppLocalizations.of(context)!.translate('start_quiz')} ${categories[currentSelected]}',
                  style: TextStyle(
                      fontFamily: 'Comic Sans MS',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)), // Styled text
            ),
          if (!canSpin() && !showQuestion)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                AppLocalizations.of(context)!.translate('come_back_tomorrow'),
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontFamily: 'Comic Sans MS'),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildQuiz() {
    if (questions.isEmpty) {
      return Center(
          child: Text(AppLocalizations.of(context)!.translate('no_questions'),
              style: TextStyle(fontFamily: 'Comic Sans MS')));
    } else {
      Map<String, dynamic> question = questions[currentQuestionIndex];
      List<String> choices =
          List<String>.from(question['choices'] ?? ['Unknown Choice']);
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            color: Color(0xFFA8E063),
            child: Text(
              question['question'] as String? ?? 'Unknown Question',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Comic Sans MS',
                  color: Colors.black),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 20),
          ...choices.map((choice) {
            Color buttonColor;
            if (selectedAnswer == null) {
              buttonColor = Colors.blue;
            } else if (choice == question['correctAnswer']) {
              buttonColor = Colors.green;
            } else if (choice == selectedAnswer) {
              buttonColor = Colors.red;
            } else {
              buttonColor = Colors.blue;
            }
            return Center(
              child: ElevatedButton(
                onPressed: selectedAnswer == null
                    ? () => answerQuestion(choice)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: Text(choice,
                    style: TextStyle(
                        fontFamily: 'Comic Sans MS', color: Colors.black)),
              ),
            );
          }).toList(),
          if (showCorrectAnswer)
            Text(
                '${AppLocalizations.of(context)!.translate('correct_answer')}: ${question['correctAnswer']}',
                style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Comic Sans MS')),
        ],
      );
    }
  }
}
