import 'dart:math';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:regalofficial/screens/Player_screen.dart';
import 'package:regalofficial/screens/VideoPage.dart';
import 'package:regalofficial/app_localizations.dart';

class Player {
  final String playerId;
  List<String> ticketNumbers;
  int points;

  Player(this.playerId, this.ticketNumbers, this.points);

  Player.fromFirestore(DocumentSnapshot snapshot)
      : playerId = snapshot.id,
        ticketNumbers = (snapshot.data() as Map<String, dynamic>)
                .containsKey('ticketNumbers')
            ? List<String>.from(
                (snapshot.data() as Map<String, dynamic>)['ticketNumbers'])
            : [],
        points = (snapshot.data() as Map<String, dynamic>).containsKey('points')
            ? (snapshot.data() as Map<String, dynamic>)['points']
            : 0;

  Map<String, dynamic> toFirestore() {
    return {
      'ticketNumbers': ticketNumbers,
      'points': points,
    };
  }
}

class QuizScreen extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final List<List<String>> answers;
  final List<int> correctAnswerIndex;
  final String adId;
  final String videoUrl;
  final String companyName;

  QuizScreen({
    Key? key,
    required this.questions,
    required this.answers,
    required this.correctAnswerIndex,
    required this.adId,
    required this.videoUrl,
    required this.companyName,
  }) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  List<int> _selectedAnswerIndices = [];
  int _currentQuestionIndex = 0;
  bool _answeredCorrectly = false;
  bool _showCorrectAnswer = false;
  int _correctAnswersCount = 0;
  bool _isAnswered = false;
  bool _quizStarted = false; // Track if the quiz has started
  late FirebaseFirestore _firestore;
  late FirebaseAuth _auth;
  List<Player> players = [];
  String? playerId;
  String playerName = "Player";
  late AnimationController _animationController;
  late Animation<Offset> _animation;
  String _currentAnimation = '';
  late AudioPlayer _audioPlayer; // Declare AudioPlayer
  String companyBio = ''; // To store the company bio

  @override
  void initState() {
    super.initState();
    _initFirestore();
    _initAuth();
    _fetchPlayerName();
    _selectedAnswerIndices = List<int>.filled(widget.questions.length, -1);

    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animation = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _audioPlayer = AudioPlayer(); // Initialize AudioPlayer

    _fetchCompanyBio(); // Fetch company bio
  }

  void _initFirestore() {
    _firestore = FirebaseFirestore.instance;
  }

  void _initAuth() {
    _auth = FirebaseAuth.instance;
    _fetchPlayerId();
  }

  void _fetchPlayerId() {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        playerId = user.uid;
      });
      _initializePlayerIfNeeded(playerId!);
    }
  }

  void _fetchPlayerName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          playerName = userDoc['username'] ?? 'Player';
        });
      }
    }
  }

  Future<void> _initializePlayerIfNeeded(String playerId) async {
    DocumentSnapshot playerDoc =
        await _firestore.collection('players').doc(playerId).get();
    if (!playerDoc.exists ||
        !(playerDoc.data() as Map<String, dynamic>)
            .containsKey('ticketNumbers') ||
        !(playerDoc.data() as Map<String, dynamic>).containsKey('points')) {
      await _firestore.collection('players').doc(playerId).set({
        'ticketNumbers': [],
        'points': 0,
      }, SetOptions(merge: true));
    }
  }

  Future<bool> checkIfPlayerHasTicketForAd(String playerId, String adId) async {
    QuerySnapshot ticketQuery = await _firestore
        .collection('tickets')
        .where('playerId', isEqualTo: playerId)
        .where('adId', isEqualTo: adId)
        .get();

    return ticketQuery.docs.isNotEmpty;
  }

  void generateTicketAndAwardPoints(
      String playerId, String adId, String adType) async {
    print("Ad Type: $adType"); // Debugging line
    String ticket = generateTicket();
    int pointsToAdd = 0;
    String message = '';

    DocumentSnapshot adDoc =
        await _firestore.collection('companies').doc(adId).get();
    if (!adDoc.exists) {
      print('Ad document does not exist');
      return;
    }
    String companyName = adDoc['companyName'] ?? '';
    int adNumber =
        (adDoc.data() as Map<String, dynamic>?)?.containsKey('adNumber') == true
            ? adDoc['adNumber']
            : 0;

    switch (adType) {
      case 'gold':
        pointsToAdd = 30;
        message = AppLocalizations.of(context)!
            .translate('congratulationsMessage')
            .replaceAll('{points}', pointsToAdd.toString());
        break;
      case 'silver':
        pointsToAdd = 20;
        message = AppLocalizations.of(context)!
            .translate('congratulationsMessage')
            .replaceAll('{points}', pointsToAdd.toString());
        break;
      case 'basic':
        pointsToAdd = 5;
        message = AppLocalizations.of(context)!
            .translate('congratulationsMessage')
            .replaceAll('{points}', pointsToAdd.toString());
        break;
      default:
        pointsToAdd = 0;
    }

    DocumentSnapshot playerDoc =
        await _firestore.collection('players').doc(playerId).get();
    List<String> currentTickets = playerDoc.exists
        ? List<String>.from(
            (playerDoc.data() as Map<String, dynamic>)['ticketNumbers'] ?? [])
        : [];
    int currentPoints = playerDoc.exists
        ? (playerDoc.data() as Map<String, dynamic>)['points'] ?? 0
        : 0;

    currentTickets.add(ticket);
    int updatedPoints = currentPoints + pointsToAdd;

    await _firestore.collection('tickets').add({
      'companyName': companyName,
      'ticketNumber': ticket,
      'adNumber': adNumber,
      'playerName': playerName,
      'playerId': playerId,
      'adId': adId,
    });

    await _firestore.collection('players').doc(playerId).set({
      'ticketNumbers': currentTickets,
      'points': updatedPoints,
    }, SetOptions(merge: true));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DefaultTextStyle(
              style: const TextStyle(fontSize: 20.0, color: Colors.black),
              child: AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(message),
                ],
                totalRepeatCount: 1,
              ),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => PlayerHomePage()),
                  (route) => false,
                );
              },
              child: Text(AppLocalizations.of(context)!.translate('close')),
            ),
          ],
        ),
      ),
    );
  }

  String generateTicket() {
    final random = Random();
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(13, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  void showTicketDialog(BuildContext context, String ticket) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('yourTicket')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!
                    .translate('yourTicketNumber')
                    .replaceAll('{ticket}', ticket),
              ),
              SizedBox(height: 10),
              Lottie.asset(
                'assets/celebration1.json',
                width: 100,
                height: 100,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Future.delayed(Duration(seconds: 4), () {
                  Navigator.of(context).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPage(
                        videoUrl: widget.videoUrl,
                        companyName: widget.companyName,
                      ),
                    ),
                    (route) => false,
                  );
                });
              },
              child: Text(AppLocalizations.of(context)!.translate('close')),
            ),
          ],
        );
      },
    );
  }

  void _showCorrectAnswerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('correctAnswer')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!
                    .translate('correctAnswer')
                    .replaceAll(
                        '{answer}',
                        widget.answers[_currentQuestionIndex]
                            [widget.correctAnswerIndex[_currentQuestionIndex]]),
                style: TextStyle(fontSize: 16, color: Colors.green),
              ),
              SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)!.translate('explanation'),
                style: TextStyle(fontSize: 16, color: Colors.blue),
              ),
              SizedBox(height: 5),
              Text(
                widget.questions[_currentQuestionIndex]['explanation'] ??
                    AppLocalizations.of(context)!
                        .translate('noExplanationAvailable'),
                style: TextStyle(fontSize: 16, color: Colors.blue),
              ),
              SizedBox(height: 10),
              Lottie.asset(
                _currentAnimation,
                width: 100,
                height: 100,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.translate('close')),
            ),
          ],
        );
      },
    );
  }

  void _playAudio(String soundPath) async {
    await _audioPlayer.setSource(AssetSource(soundPath));
    await _audioPlayer.resume();
  }

  void _checkAnswer(int selectedAnswerIndex) {
    if (_isAnswered) return;

    setState(() {
      _selectedAnswerIndices[_currentQuestionIndex] = selectedAnswerIndex;
      _isAnswered = true;

      int correctIndex = widget.correctAnswerIndex[_currentQuestionIndex];

      _answeredCorrectly = (selectedAnswerIndex == correctIndex);
      if (_answeredCorrectly) {
        _correctAnswersCount++;
        _currentAnimation = 'assets/4.json';
        _playAudio('audio/correct-answer.mp3');
      } else {
        _currentAnimation = 'assets/error.json';
        _playAudio('audio/wrong-answer2.mp3');
      }

      _animationController.forward(from: 0);
    });

    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _showCorrectAnswer = true;
        _showCorrectAnswerDialog();
      });
    });
  }

  void _nextQuestion() {
    if (!_isAnswered) return;

    setState(() {
      _currentQuestionIndex++;
      _answeredCorrectly = false;
      _isAnswered = false;
      _showCorrectAnswer = false;
      _currentAnimation = '';
    });
  }

  void _finishQuiz() async {
    if (_correctAnswersCount >= 2) {
      if (playerId != null) {
        generateTicketAndAwardPoints(playerId!, widget.adId, 'basic');
        String ticket = generateTicket();
        setState(() {
          _currentAnimation = 'assets/celebrations.json';
        });
        _playAudio('audio/bravo.wav'); // Play clap sound
        Future.delayed(Duration(seconds: 1), () {
          showTicketDialog(context, ticket);
        });
        await _updateQuizCompletion();
      }
    } else {
      setState(() {
        _currentAnimation = 'assets/all_question_error.json';
      });
      _playAudio('audio/wrong-answer2.mp3'); // Play cry sound
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: DefaultTextStyle(
            style: const TextStyle(fontSize: 20.0, color: Colors.black),
            child: AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                    AppLocalizations.of(context)!.translate('atLeast2Correct')),
              ],
              totalRepeatCount: 1,
              onFinished: () {
                Future.delayed(Duration(seconds: 4), () {
                  Navigator.of(context).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPage(
                        videoUrl: widget.videoUrl,
                        companyName: widget.companyName,
                      ),
                    ),
                    (route) => false,
                  );
                });
              },
            ),
          ),
        ),
      );
    }
  }

  Future<void> _updateQuizCompletion() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('watchedVideos')
          .where('playerId', isEqualTo: user.uid)
          .where('videoUrl', isEqualTo: widget.videoUrl)
          .where('companyName', isEqualTo: widget.companyName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot watchedVideoDoc = querySnapshot.docs.first;
        await FirebaseFirestore.instance
            .collection('watchedVideos')
            .doc(watchedVideoDoc.id)
            .update({'quizCompleted': true});
      }
    }
  }

  void _fetchCompanyBio() async {
    DocumentSnapshot adDoc =
        await _firestore.collection('companyRequests').doc(widget.adId).get();
    if (adDoc.exists) {
      setState(() {
        companyBio = (adDoc.data() as Map<String, dynamic>).containsKey('bio')
            ? adDoc['bio']
            : 'Bio not available';
      });
    } else {
      setState(() {
        companyBio = 'Bio not available';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('quiz'),
          style: TextStyle(color: Colors.orange),
        ),
        backgroundColor: Colors.green[900],
      ),
      body: Stack(
        children: [
          if (!_quizStarted) // Check if the quiz has started
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Are you ready !!\n\nFor claim the ticket number and gain the points, you need to answer well at least 2 questions',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20),
                  Lottie.asset(
                    'assets/wait.json', // Path to your wait.json animation
                    width: 100,
                    height: 100,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _quizStarted = true;
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.white),
                    ),
                    child: Text(
                      'Start Quiz',
                      style: TextStyle(
                        color: Colors.green[900], // Dark green text color
                        fontSize: 20,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    widget.companyName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    companyBio,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!
                        .translate('question')
                        .replaceAll(
                            '{number}', (_currentQuestionIndex + 1).toString()),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.lightGreen,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.questions[_currentQuestionIndex]['question'] ?? '',
                    style: TextStyle(fontSize: 16, color: Colors.lightGreen),
                  ),
                  SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(
                        widget.answers[_currentQuestionIndex].length, (index) {
                      return ElevatedButton(
                        onPressed: () {
                          _checkAnswer(index);
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color?>(
                            _selectedAnswerIndices[_currentQuestionIndex] ==
                                    index
                                ? (_answeredCorrectly
                                    ? Colors.green
                                    : Colors.red)
                                : _showCorrectAnswer &&
                                        (index ==
                                            widget.correctAnswerIndex[
                                                _currentQuestionIndex])
                                    ? Colors.green
                                    : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          widget.answers[_currentQuestionIndex][index],
                          style: TextStyle(
                            color:
                                _selectedAnswerIndices[_currentQuestionIndex] ==
                                            index ||
                                        (_showCorrectAnswer &&
                                            (index ==
                                                widget.correctAnswerIndex[
                                                    _currentQuestionIndex]))
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 20),
                  if (_currentQuestionIndex < widget.questions.length - 1)
                    ElevatedButton(
                      onPressed: _nextQuestion,
                      child: Text(AppLocalizations.of(context)!
                          .translate('nextQuestion')),
                    ),
                  if (_currentQuestionIndex == widget.questions.length - 1)
                    ElevatedButton(
                      onPressed: _finishQuiz,
                      child: Text(AppLocalizations.of(context)!
                          .translate('finishQuiz')),
                    ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          if (_currentAnimation.isNotEmpty)
            Align(
              alignment: Alignment.center,
              child: SlideTransition(
                position: _animation,
                child: Lottie.asset(
                  _currentAnimation,
                  width: 100,
                  height: 100,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
