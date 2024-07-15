import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:regalofficial/screens/QuizScreen.dart';
import 'package:regalofficial/screens/Player_Screen.dart';
import 'package:regalofficial/app_localizations.dart';

class VideoPage extends StatefulWidget {
  final String videoUrl;
  final String companyName;

  const VideoPage({Key? key, required this.videoUrl, required this.companyName})
      : super(key: key);

  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  bool _ticketGenerated = false;

  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _showCongratulations = false;

  Timer? _timer;
  Duration _videoDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;

  bool _videoEnded = false;
  final Completer<void> _creatingCompleter = Completer<void>();

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _checkIfQuizCompleted();
  }

  Future<void> _initializeVideo() async {
    try {
      print('Initializing VideoPlayerController with URL: ${widget.videoUrl}');
      _videoPlayerController = VideoPlayerController.network(widget.videoUrl)
        ..addListener(_updateVideoProgress)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _videoDuration = _videoPlayerController.value.duration;
              _chewieController = ChewieController(
                videoPlayerController: _videoPlayerController,
                autoPlay: true,
                looping: false,
                showControls: true, // Show default video controls
              );
            });
            _videoPlayerController.play();
            startTimer();
            if (!_creatingCompleter.isCompleted) {
              _creatingCompleter.complete();
            }
          }
        }).catchError((error) {
          print('VideoPlayerController initialization error: $error');
          if (!_creatingCompleter.isCompleted) {
            _creatingCompleter.completeError(error);
          }
        });
    } catch (error) {
      print('Error initializing video: $error');
      if (!_creatingCompleter.isCompleted) {
        _creatingCompleter.completeError(error);
      }
    }
  }

  void _updateVideoProgress() {
    if (!mounted) return;

    setState(() {
      _currentPosition = _videoPlayerController.value.position;
    });

    if (_videoPlayerController.value.position >=
            _videoPlayerController.value.duration &&
        !_videoEnded) {
      _onVideoEnd();
    }
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (Timer timer) {
      if (_videoPlayerController.value.position >=
          _videoPlayerController.value.duration) {
        timer.cancel();
      } else {
        setState(() {
          _currentPosition = _videoPlayerController.value.position;
        });
      }
    });
  }

  void _onVideoEnd() {
    _videoEnded = true;
    setState(() {
      _showCongratulations = true;
    });
    _saveWatchedVideo(); // Save the video details when it ends
  }

  Future<void> _saveWatchedVideo() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('watchedVideos').add({
        'playerId': user.uid,
        'videoUrl': widget.videoUrl,
        'companyName': widget.companyName,
        'watchedAt': FieldValue.serverTimestamp(),
        'quizCompleted': false, // Set quizCompleted to false initially
      });
    }
  }

  Future<void> _checkIfQuizCompleted() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('watchedVideos')
          .where('playerId', isEqualTo: user.uid)
          .where('videoUrl', isEqualTo: widget.videoUrl)
          .where('companyName', isEqualTo: widget.companyName)
          .where('quizCompleted', isEqualTo: true)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _ticketGenerated = true;
        });
      }
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

  void _showCongratulationsMessage() {
    Fluttertoast.showToast(
      msg: AppLocalizations.of(context)!.translate('congratulations_quiz'),
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black.withOpacity(0.8),
      textColor: const Color.fromARGB(255, 241, 181, 181),
    );
  }

  void _startQuiz() async {
    if (!_ticketGenerated) {
      try {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('companies')
            .where('videoUrl', isEqualTo: widget.videoUrl)
            .where('companyName', isEqualTo: widget.companyName)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          DocumentSnapshot adSnapshot = querySnapshot.docs.first;
          Map<String, dynamic> adData =
              adSnapshot.data() as Map<String, dynamic>;
          String adId = adSnapshot.id;

          List<Map<String, dynamic>> questions = [];
          List<List<String>> answers = [];
          List<int> correctAnswerIndex = [];

          List<dynamic> questionsData = adData['questions'];
          for (var questionData in questionsData) {
            questions.add(questionData as Map<String, dynamic>);
            List<String> choicesData = questionData['choices'].cast<String>();
            answers.add(choicesData);
            try {
              String correctAnswer = questionData['correctAnswer'].toString();
              int correctIndex = choicesData.indexOf(correctAnswer);
              if (correctIndex != -1) {
                correctAnswerIndex.add(correctIndex);
              } else {
                correctAnswerIndex
                    .add(0); // Default to the first choice if not found
              }
            } catch (e) {
              print('Error parsing correctAnswerIndex: $e');
              correctAnswerIndex
                  .add(0); // Default to the first choice if parsing fails
            }
          }

          if (questions.isNotEmpty &&
              answers.isNotEmpty &&
              correctAnswerIndex.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizScreen(
                  questions: questions,
                  answers: answers,
                  correctAnswerIndex: correctAnswerIndex,
                  adId: adId,
                  videoUrl: widget.videoUrl,
                  companyName: widget.companyName,
                ),
              ),
            ).then((_) => _updateQuizCompletion());
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .translate('quiz_data_missing_or_invalid')),
            ));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!
                .translate('no_corresponding_ad_found')),
          ));
        }
      } catch (e) {
        print('Error starting quiz: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!
            .translate('ticket_already_generated')),
      ));
    }
  }

  void _playVideo() {
    _videoPlayerController.play();
  }

  void _pauseVideo() {
    _videoPlayerController.pause();
  }

  void _stopVideo() {
    _videoPlayerController.seekTo(Duration.zero);
    _videoPlayerController.pause();
  }

  @override
  void dispose() {
    _videoPlayerController.removeListener(_updateVideoProgress);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('video')),
      ),
      body: FutureBuilder(
        future: _creatingCompleter.future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('FutureBuilder error: ${snapshot.error}');
            return Center(
                child: Text(AppLocalizations.of(context)!
                    .translate('error_loading_video')));
          } else {
            return Stack(
              children: [
                Center(
                  child: Chewie(
                    controller: _chewieController!,
                  ),
                ),
                if (_showCongratulations)
                  AnimatedOpacity(
                    opacity: _showCongratulations ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 500),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(20),
                            color: Colors.black.withOpacity(0.5),
                            child: Text(
                              AppLocalizations.of(context)!
                                  .translate('congratulations_quiz'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 20),
                          TextButton(
                            onPressed: _startQuiz,
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!
                                  .translate('start_quiz'),
                              style: TextStyle(
                                color: Colors.deepOrange, // Dark orange color
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Text(
                    '${_currentPosition.inMinutes}:${(_currentPosition.inSeconds % 60).toString().padLeft(2, '0')} / ${_videoDuration.inMinutes}:${(_videoDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.play_arrow),
                        color: Colors.white,
                        onPressed: _playVideo,
                      ),
                      IconButton(
                        icon: Icon(Icons.pause),
                        color: Colors.white,
                        onPressed: _pauseVideo,
                      ),
                      IconButton(
                        icon: Icon(Icons.stop),
                        color: Colors.white,
                        onPressed: _stopVideo,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 20,
                  left: 20,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlayerHomePage(),
                        ),
                      );
                    },
                    child: Text(
                      AppLocalizations.of(context)!.translate('back_to_player'),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
