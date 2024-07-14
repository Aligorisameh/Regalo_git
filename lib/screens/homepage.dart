import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:regalofficial/app_localizations.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:audioplayers/audioplayers.dart';
import 'winners_page.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:async';
import 'dart:math';

void logMemoryUsage() {
  developer.log('Current memory usage: ${ProcessInfo.currentRss}');
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  Color loginColor = const Color(0xFF056608);
  Color signupColor = const Color(0xFF056608);
  Color ourPartnersColor = const Color(0xFF056608);
  Color aboutUsColor = const Color(0xFF056608);
  Color yourMessageColor = const Color(0xFF056608);
  Color previousWinnerColor = const Color(0xFF056608);

  late AudioPlayer _audioPlayer;

  final Random _random = Random();

  Timer? _congratsTimer;

  @override
  void initState() {
    super.initState();
    developer.log('HomePage initialized');
    _audioPlayer = AudioPlayer();
    _playAudio();

    _congratsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _congratsTimer?.cancel();
    super.dispose();
  }

  Future<void> _playAudio() async {
    try {
      await _audioPlayer.play(AssetSource('home.mp3'));
      developer.log('Audio started playing');
    } catch (e) {
      developer.log('Error in playing audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    developer.log('Building HomePage');
    return Scaffold(
      appBar: buildAppBar(context),
      body: buildAdsList(),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 250, 254, 254),
      title: Image.asset(
        'assets/images/logo---.png',
        height: 30,
      ),
      centerTitle: true,
      actions: [
        PopupMenuButton<MenuItem>(
          icon: const Icon(Icons.menu, color: Color(0xFF056608)),
          itemBuilder: (BuildContext context) {
            var localizations = AppLocalizations.of(context);
            return <PopupMenuEntry<MenuItem>>[
              buildPopupMenuItem(
                context,
                MenuItem.login,
                Icons.login,
                localizations!.translate('login'),
                loginColor,
                (isHovered) {
                  setState(() {
                    loginColor = isHovered
                        ? const Color(0xFF033D04)
                        : const Color(0xFF056608);
                  });
                },
              ),
              buildPopupMenuItem(
                context,
                MenuItem.signup,
                Icons.person_add,
                localizations.translate('signup'),
                signupColor,
                (isHovered) {
                  setState(() {
                    signupColor = isHovered
                        ? const Color(0xFF033D04)
                        : const Color(0xFF056608);
                  });
                },
              ),
              buildPopupMenuItem(
                context,
                MenuItem.ourpartners,
                Icons.group,
                localizations.translate('our_partners'),
                ourPartnersColor,
                (isHovered) {
                  setState(() {
                    ourPartnersColor = isHovered
                        ? const Color(0xFF033D04)
                        : const Color(0xFF056608);
                  });
                },
              ),
              buildPopupMenuItem(
                context,
                MenuItem.aboutUs,
                Icons.info,
                localizations.translate('about_us'),
                aboutUsColor,
                (isHovered) {
                  setState(() {
                    aboutUsColor = isHovered
                        ? const Color(0xFF033D04)
                        : const Color(0xFF056608);
                  });
                },
              ),
              buildPopupMenuItem(
                context,
                MenuItem.yourMessage,
                Icons.message,
                localizations.translate('your_message'),
                yourMessageColor,
                (isHovered) {
                  setState(() {
                    yourMessageColor = isHovered
                        ? const Color(0xFF033D04)
                        : const Color(0xFF056608);
                  });
                },
              ),
              buildPopupMenuItem(
                context,
                MenuItem.previousWinner,
                Icons.emoji_events,
                localizations.translate('previous_winner'),
                previousWinnerColor,
                (isHovered) {
                  setState(() {
                    previousWinnerColor = isHovered
                        ? const Color(0xFF033D04)
                        : const Color(0xFF056608);
                  });
                },
              ),
            ];
          },
          onSelected: (MenuItem result) {
            handleMenuSelection(context, result);
          },
        ),
      ],
    );
  }

  PopupMenuItem<MenuItem> buildPopupMenuItem(
      BuildContext context,
      MenuItem value,
      IconData icon,
      String text,
      Color color,
      Function(bool) onHover) {
    return PopupMenuItem<MenuItem>(
      value: value,
      child: MouseRegion(
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            text,
            style: TextStyle(color: color),
          ),
        ),
      ),
    );
  }

  void handleMenuSelection(BuildContext context, MenuItem result) {
    switch (result) {
      case MenuItem.login:
        Navigator.pushNamed(context, '/Signin');
        break;
      case MenuItem.signup:
        Navigator.pushNamed(context, '/signup');
        break;
      case MenuItem.ourpartners:
        Navigator.pushNamed(context, '/ourPartners');
        break;
      case MenuItem.aboutUs:
        Navigator.pushNamed(context, '/aboutUs');
        break;
      case MenuItem.yourMessage:
        Navigator.pushNamed(context, '/message');
        break;
      case MenuItem.previousWinner:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => WinnersPage()),
        );
        break;
    }
  }

  void randomizeAdsList(List<QueryDocumentSnapshot> ads) {
    ads.shuffle(_random);
  }

  Widget buildAdsList() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('companies')
            .where('isPublished', isEqualTo: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            developer.log('Error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<QueryDocumentSnapshot> ads = snapshot.data!.docs;

          developer.log("Number of ads found: ${ads.length}");

          if (ads.isEmpty) {
            developer.log('No ads found');
            return const Center(child: Text('No ads found'));
          }

          randomizeAdsList(ads);

          return buildStaggeredGridView(ads);
        },
      ),
    );
  }

  Widget buildStaggeredGridView(List<QueryDocumentSnapshot> ads) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: StaggeredGridView.countBuilder(
        crossAxisCount: 4,
        itemCount: ads.length,
        itemBuilder: (context, index) {
          var data = ads[index].data() as Map<String, dynamic>?;

          if (data == null) {
            developer.log("Invalid data at index $index");
            return Container();
          }

          String companyName = data['companyName'] ?? 'Unknown';
          String selectedType = data['selectedType'] ?? 'basic';
          int numberOfWinners = data.containsKey('numberOfWinners')
              ? data['numberOfWinners'] as int
              : 0;
          List<dynamic> imageUrls = data['imageUrls'] ?? [];
          Timestamp? endDateTimestamp = data['endDate'];
          DateTime? endDate = endDateTimestamp?.toDate();

          developer.log(
              "Data for ad $index: companyName: $companyName, selectedType: $selectedType, numberOfWinners: $numberOfWinners, imageUrl: $imageUrls, endDate: $endDate");

          return Frame(
            frameType: determineFrameType(selectedType),
            companyName: companyName,
            winners: numberOfWinners,
            imageUrls: imageUrls,
            endDate: endDate,
          );
        },
        staggeredTileBuilder: (int index) {
          var data = ads[index].data() as Map<String, dynamic>?;
          String selectedType = data != null && data.containsKey('selectedType')
              ? data['selectedType']
              : 'basic';
          return _buildTile(selectedType);
        },
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
      ),
    );
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
}

class Frame extends StatefulWidget {
  final FrameType frameType;
  final String companyName;
  final int winners;
  final List<dynamic> imageUrls;
  final DateTime? endDate;

  const Frame({
    super.key,
    required this.frameType,
    required this.companyName,
    required this.winners,
    required this.imageUrls,
    this.endDate,
  });

  @override
  State<Frame> createState() => _FrameState();
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
      if (_currentPage < widget.imageUrls.length - 1) {
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
        frameSize = 300.0;
        frameColor = const Color.fromARGB(255, 201, 167, 13);
        fontSize = 14;
        break;
      case FrameType.silver:
        frameSize = 200.0;
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
        developer.log("Tapped on frame. Navigating to '/signin'");
        Navigator.of(context).pushNamed('/signin');
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
                  child: widget.imageUrls.isNotEmpty
                      ? PageView.builder(
                          controller: _pageController,
                          itemCount: widget.imageUrls.length,
                          itemBuilder: (context, index) {
                            String imageUrl = widget.imageUrls[index];
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
                                  'assets/images/default.png',
                                  fit: BoxFit.cover,
                                );
                              },
                            );
                          },
                        )
                      : Image.asset(
                          'assets/images/default.png',
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

enum MenuItem {
  login,
  signup,
  ourpartners,
  aboutUs,
  yourMessage,
  previousWinner,
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
