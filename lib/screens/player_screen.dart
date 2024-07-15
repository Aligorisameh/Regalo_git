import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:regalofficial/screens/VideoPage.dart';
import 'package:regalofficial/screens/SpinnerWheel.dart';
import 'package:regalofficial/screens/ShowroomPage.dart';
import 'package:regalofficial/screens/MyTicketsPage.dart';
import 'package:regalofficial/screens/user_Profile_Page.dart';
import 'package:regalofficial/screens/signin.dart';
import 'package:regalofficial/app_localizations.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';

import 'chat_page.dart';

class PlayerHomePage extends StatefulWidget {
  @override
  _PlayerHomePageState createState() => _PlayerHomePageState();
}

class _PlayerHomePageState extends State<PlayerHomePage> {
  String playerName = 'Player';
  String? playerProfilePicture;
  List<QueryDocumentSnapshot> ads = [];
  int playerPoints = 0;
  String? playerId;
  bool isLoading = true;
  DateTime? lastSpinTime;
  StreamController<int> selected = StreamController<int>();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    fetchPlayerId();
    _playWelcomeAudio();
  }

  @override
  void dispose() {
    selected.close();
    super.dispose();
  }

  Future<void> _playWelcomeAudio() async {
    try {
      await _audioPlayer.setSource(AssetSource('welcomee.wav'));
      await _audioPlayer.resume();
    } catch (e) {
      print('Failed to play welcome audio: $e');
    }
  }

  Future<void> fetchPlayerId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        playerId = user.uid;
      });
      await fetchPlayerData();
      await fetchAdsData();
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchPlayerData() async {
    if (playerId != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(playerId)
          .get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          playerName = userData['username'] ?? 'Player';
          playerProfilePicture = userData['profilePicture'];
        });
      }

      DocumentSnapshot playerDoc = await FirebaseFirestore.instance
          .collection('players')
          .doc(playerId)
          .get();
      if (playerDoc.exists) {
        var playerData = playerDoc.data() as Map<String, dynamic>;
        setState(() {
          playerPoints = playerData['points'] ?? 0;
          if (playerData.containsKey('lastSpinTime')) {
            lastSpinTime = (playerData['lastSpinTime'] as Timestamp).toDate();
          } else {
            lastSpinTime = null;
          }
          if (playerData.containsKey('ticketNumbers')) {
            playerData['ticketNumbers'] ??= [];
          }
        });
      } else {
        await FirebaseFirestore.instance
            .collection('players')
            .doc(playerId)
            .set({
          'ticketNumbers': [],
          'points': 0,
        }, SetOptions(merge: true));
      }
    }
  }

  Future<void> fetchAdsData() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .where('isPublished', isEqualTo: true)
        .get();
    setState(() {
      ads = querySnapshot.docs;
    });
  }

  Future<void> fetchPlayerPoints() async {
    if (playerId != null) {
      DocumentSnapshot playerDoc = await FirebaseFirestore.instance
          .collection('players')
          .doc(playerId)
          .get();
      if (playerDoc.exists) {
        var playerData = playerDoc.data() as Map<String, dynamic>;
        setState(() {
          playerPoints = playerData['points'] ?? 0;
        });
      }
    }
  }

  void showTotalPoints() async {
    await fetchPlayerPoints();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFA8E063),
          title: Text(
            AppLocalizations.of(context)!.translate('total_points'),
            style: TextStyle(color: Colors.black),
          ),
          content: Text(
            '${AppLocalizations.of(context)!.translate('your_total_points')}: $playerPoints',
            style: TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                AppLocalizations.of(context)!.translate('close'),
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> hasTicketForAd(String adId) async {
    if (playerId == null) return false;

    QuerySnapshot ticketQuery = await FirebaseFirestore.instance
        .collection('tickets')
        .where('playerId', isEqualTo: playerId)
        .where('adId', isEqualTo: adId)
        .get();

    return ticketQuery.docs.isNotEmpty;
  }

  void showAlreadyParticipatedMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFA8E063),
          title: Text(
            AppLocalizations.of(context)!.translate('already_participated'),
            style: TextStyle(color: Colors.black),
          ),
          content: Text(
            AppLocalizations.of(context)!
                .translate('already_participated_message'),
            style: TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                AppLocalizations.of(context)!.translate('close'),
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> pickAndUploadImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      await uploadImageToFirebase(image);
    }
  }

  Future<void> uploadImageToFirebase(XFile image) async {
    try {
      String fileName = 'profile_pictures/$playerId/${image.name}';
      Reference storageReference =
          FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageReference.putFile(File(image.path));

      await uploadTask.whenComplete(() => null);
      String imageUrl = await storageReference.getDownloadURL();

      DocumentReference playerDocRef =
          FirebaseFirestore.instance.collection('players').doc(playerId);
      DocumentReference userDocRef =
          FirebaseFirestore.instance.collection('users').doc(playerId);

      DocumentSnapshot playerDoc = await playerDocRef.get();
      if (playerDoc.exists) {
        await playerDocRef.update({'profilePicture': imageUrl});
      } else {
        await playerDocRef.set({'profilePicture': imageUrl});
      }

      DocumentSnapshot userDoc = await userDocRef.get();
      if (userDoc.exists) {
        await userDocRef.update({'profilePicture': imageUrl});
      } else {
        await userDocRef.set({'profilePicture': imageUrl});
      }

      setState(() {
        playerProfilePicture = imageUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Profile picture updated successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF56AB2F),
        title: Text(
          AppLocalizations.of(context)!.translate('player_home'),
          style: TextStyle(color: Color(0xFFFF8008)),
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: Icon(Icons.menu, color: Color(0xFFFF8008)),
            onSelected: (String choice) {
              switch (choice) {
                case 'Logout':
                  _logout(context);
                  break;
                case 'Showroom':
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ShowroomPage(),
                  ));
                  break;
                case 'User profile':
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => UserProfilePage(),
                  ));
                  break;
                case 'Total points':
                  showTotalPoints();
                  break;
                case 'About us':
                  break;
                case 'Messages':
                  break;
                case 'My Tickets':
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => MyTicketsPage(),
                  ));
                  break;
                case 'Chat with Admin':
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChatPage(
                      chatId: 'admin_${FirebaseAuth.instance.currentUser?.uid}',
                      receiverEmail:
                          FirebaseAuth.instance.currentUser?.email ?? '',
                      receiverType: 'Player',
                    ),
                  ));
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'Showroom',
                  child: Text(
                    AppLocalizations.of(context)!.translate('showroom'),
                    style: TextStyle(color: Color(0xFFFF8008)),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'User profile',
                  child: Text(
                    AppLocalizations.of(context)!.translate('user_profile'),
                    style: TextStyle(color: Color(0xFFFF8008)),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'Total points',
                  child: Text(
                    AppLocalizations.of(context)!.translate('total_points'),
                    style: TextStyle(color: Color(0xFFFF8008)),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'About us',
                  child: Text(
                    AppLocalizations.of(context)!.translate('about_us'),
                    style: TextStyle(color: Color(0xFFFF8008)),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'Messages',
                  child: Text(
                    AppLocalizations.of(context)!.translate('messages'),
                    style: TextStyle(color: Color(0xFFFF8008)),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'My Tickets',
                  child: Text(
                    AppLocalizations.of(context)!.translate('my_tickets'),
                    style: TextStyle(color: Color(0xFFFF8008)),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'Chat with Admin',
                  child: Text(
                    AppLocalizations.of(context)!.translate('chat_with_admin'),
                    style: TextStyle(color: Color(0xFFFF8008)),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'Logout',
                  child: Text(
                    AppLocalizations.of(context)!.translate('logout'),
                    style: TextStyle(color: Color(0xFFFF8008)),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Color(0xFFA8E063)
                .withOpacity(0.3), // Semi-transparent background
          ),
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 60, 20, 0), // Adjusted padding
              child: Column(
                children: <Widget>[
                  GestureDetector(
                    onTap: pickAndUploadImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: playerProfilePicture != null
                          ? NetworkImage(playerProfilePicture!)
                          : AssetImage('assets/images/default.png')
                              as ImageProvider,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context)!.translate('hello'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF8008),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    playerName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF8008),
                    ),
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => SpinnerWheel(),
                      ));
                    },
                    child: Lottie.asset(
                      'assets/spinner.json',
                      width: 100,
                      height: 100,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context)!.translate('earn_more_points'),
                    style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFFFF8008)),
                  ),
                  SizedBox(height: 20),
                  _buildAds(),
                ],
              ),
            ),
          ),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildAds() {
    if (ads.isEmpty) {
      return Text('No ads found');
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: StaggeredGridView.countBuilder(
          crossAxisCount: 4,
          itemCount: ads.length,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            var ad = ads[index];
            Map<String, dynamic>? adData = ad.data() as Map<String, dynamic>?;
            String companyName = adData?['companyName'] ?? 'Unknown';
            String selectedType = adData?['selectedType'] ?? 'basic';
            int numberOfWinners = adData?['numberOfWinners'] ?? 0;
            List<dynamic>? imageUrls = adData?['imageUrls'];
            FrameType frameType = determineFrameType(selectedType);
            String videoUrl = adData?['videoUrl'] ?? '';
            DateTime? endDate = adData?['endDate']?.toDate();

            return Frame(
              frameType: frameType,
              companyName: companyName,
              winners: numberOfWinners,
              imageUrls: imageUrls,
              endDate: endDate,
              onTap: () async {
                if (endDate != null && endDate.isBefore(DateTime.now())) {
                  showExpiredMessage(context);
                } else {
                  bool hasTicket = await hasTicketForAd(ad.id);
                  if (hasTicket) {
                    showAlreadyParticipatedMessage();
                  } else {
                    int pointsRequired;
                    switch (frameType) {
                      case FrameType.gold:
                        pointsRequired = 50;
                        break;
                      case FrameType.silver:
                        pointsRequired = 30;
                        break;
                      case FrameType.basic:
                        pointsRequired = 0;
                        break;
                    }

                    if (playerPoints >= pointsRequired) {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => VideoPage(
                          videoUrl: videoUrl,
                          companyName: companyName,
                        ),
                      ));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'You need more than $pointsRequired points to access this frame.'),
                      ));
                    }
                  }
                }
              },
              adType: selectedType, // Pass the adType
            );
          },
          staggeredTileBuilder: (int index) {
            var ad = ads[index];
            Map<String, dynamic>? adData = ad.data() as Map<String, dynamic>?;
            String selectedType = adData?['selectedType'] ?? 'basic';
            return _buildTile(selectedType);
          },
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
        ),
      );
    }
  }

  StaggeredTile _buildTile(String selectedType) {
    switch (selectedType) {
      case 'gold':
        return const StaggeredTile.fit(2);
      case 'silver':
        return const StaggeredTile.fit(2);
      default:
        return const StaggeredTile.fit(2);
    }
  }

  void showExpiredMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red.withOpacity(0.5),
          title: Text(
            AppLocalizations.of(context)!.translate('ads_expired'),
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            AppLocalizations.of(context)!.translate('ads_expired_message'),
            style: TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                AppLocalizations.of(context)!.translate('close'),
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

class Frame extends StatefulWidget {
  final FrameType frameType;
  final String companyName;
  final int winners;
  final List<dynamic>? imageUrls;
  final DateTime? endDate;
  final VoidCallback onTap;
  final String adType; // Add adType parameter

  const Frame({
    Key? key,
    required this.frameType,
    required this.companyName,
    required this.winners,
    this.imageUrls,
    this.endDate,
    required this.onTap,
    required this.adType, // Initialize adType
  }) : super(key: key);

  @override
  _FrameState createState() => _FrameState();
}

class _FrameState extends State<Frame> {
  late final PageController _pageController;
  late final Timer _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    developer.log('Frame initialized for ${widget.companyName}');
    _pageController = PageController(initialPage: _currentPage);
    _timer = Timer.periodic(const Duration(seconds: 2), (Timer timer) {
      if (_currentPage < (widget.imageUrls?.length ?? 0) - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
    developer.log('Frame disposed for ${widget.companyName}');
  }

  @override
  Widget build(BuildContext context) {
    double frameSize;
    Color frameColor;
    double fontSize;

    developer.log(
        "Building Frame with companyName: ${widget.companyName}, winners: ${widget.winners}, imageUrls: ${widget.imageUrls}, endDate: ${widget.endDate}");

    var localizations = AppLocalizations.of(context);

    switch (widget.frameType) {
      case FrameType.gold:
        frameSize = 200.0;
        frameColor = const Color.fromARGB(255, 201, 167, 13);
        fontSize = 14;
        break;
      case FrameType.silver:
        frameSize = 150.0;
        frameColor = const Color.fromARGB(255, 181, 180, 180);
        fontSize = 12;
        break;
      case FrameType.basic:
        frameSize = 100.0;
        frameColor = const Color.fromARGB(255, 120, 96, 87);
        fontSize = 10;
        break;
      default:
        frameSize = 100.0;
        frameColor = Colors.grey;
        fontSize = 10;
        break;
    }

    return GestureDetector(
      onTap: () {
        print('Ad type: ${widget.adType}'); // Print ad type
        if (widget.endDate != null &&
            widget.endDate!.isBefore(DateTime.now())) {
          showExpiredMessage(context);
        } else {
          widget.onTap();
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          width: double.infinity,
          height: frameSize,
          color: frameColor,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: frameSize * 0.9,
                  child: widget.imageUrls != null &&
                          widget.imageUrls!.isNotEmpty
                      ? PageView.builder(
                          controller: _pageController,
                          itemCount: widget.imageUrls!.length,
                          itemBuilder: (context, index) {
                            String imageUrl = widget.imageUrls![index];
                            return Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded /
                                            (progress.expectedTotalBytes ?? 1)
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                developer.log('Error loading image: $error');
                                return Image.asset(
                                  'assets/images/default.png', // Default image path
                                  fit: BoxFit.cover,
                                );
                              },
                            );
                          },
                        )
                      : Image.asset(
                          'assets/images/default.png', // Default image path
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Container(
                  color: const Color(0xFFA8E063).withOpacity(0.5),
                  child: Text(
                    widget.companyName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                      color: const Color(0xFFFF8008),
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Container(
                  color: const Color(0xFFA8E063).withOpacity(0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${localizations!.translate('winners')}: ${widget.winners}',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: fontSize - 2,
                          color: const Color(0xFFFF8008),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (widget.endDate != null)
                        CountdownTimer(
                          endTime: widget.endDate!.millisecondsSinceEpoch,
                          widgetBuilder: (_, time) {
                            if (time == null) {
                              return Text(
                                'Expired',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  backgroundColor: Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              );
                            } else {
                              return Text(
                                '${localizations.translate('ends_in')}: ${time.days ?? 0}d ${time.hours ?? 0}h ${time.min ?? 0}m ${time.sec ?? 0}s',
                                style: TextStyle(
                                  fontSize: fontSize - 2,
                                  color: const Color(0xFFFF8008),
                                ),
                                textAlign: TextAlign.center,
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showExpiredMessage(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.red.withOpacity(0.5),
        title: Text(
          AppLocalizations.of(context)!.translate('ads_expired'),
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          AppLocalizations.of(context)!.translate('ads_expired_message'),
          style: TextStyle(color: Colors.white),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              AppLocalizations.of(context)!.translate('close'),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}

Future<void> _logout(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  Navigator.of(context).pushReplacement(MaterialPageRoute(
    builder: (context) => SignIn(),
  ));
}

enum FrameType { gold, silver, basic }

FrameType determineFrameType(String selectedType) {
  switch (selectedType.toLowerCase()) {
    case 'gold':
      return FrameType.gold;
    case 'silver':
      return FrameType.silver;
    case 'basic':
      return FrameType.basic;
    default:
      return FrameType.basic;
  }
}
