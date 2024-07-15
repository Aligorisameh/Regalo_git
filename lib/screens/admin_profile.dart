import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:regalofficial/main.dart';
import 'package:regalofficial/screens/signin_screen.dart';
import 'company_status_page.dart';
import 'pending_requests_page.dart';
import 'all_ads_page.dart';
import 'tickets_page.dart';
import 'quizz_admin_page.dart';
import 'admin_messages_email.dart';
import 'user_list_page.dart';
import 'winners_page.dart'; // Import WinnersPage
import 'package:regalofficial/app_localizations.dart';
import 'user_chat_list.dart'; // Import ChatPage
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import local notifications

class AdminHomePage extends StatefulWidget {
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  String _selectedMenuItem = 'Home';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String currentUserEmail = 'No user logged in'; // Default value
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _registerDeviceToken();
    _initializeFirebaseMessaging();
    _fetchCurrentUserEmailAndCheckAdmin(); // Call it here
  }

  Future<void> _fetchCurrentUserEmailAndCheckAdmin() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        setState(() {
          currentUserEmail = user.email ?? 'No user logged in';
          isAdmin = user.email == 'evolutionn.informatique@gmail.com';
        });
        print('Fetched user email: $currentUserEmail');
        print('Is admin: $isAdmin');
      } else {
        setState(() {
          currentUserEmail = 'No user logged in';
          isAdmin = false;
        });
        print('No user is currently signed in.');
      }
    } catch (e) {
      print('Error fetching user email and checking admin status: $e');
    }
  }

  Future<void> _registerDeviceToken() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final String? deviceToken = await _firebaseMessaging.getToken();
        if (deviceToken != null) {
          await FirebaseFirestore.instance
              .collection('adminDevices')
              .doc(user.uid)
              .set({'token': deviceToken});
        }
      }
    } catch (e) {
      print('Error registering device token: $e');
    }
  }

  void _initializeFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'your_channel_id',
              'your_channel_name',
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      setState(() {
        currentUserEmail = 'No user logged in';
        isAdmin = false;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
      print('User logged out');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${AppLocalizations.of(context)!.translate('admin_home')} - $currentUserEmail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
          IconButton(
            icon: const Icon(Icons.business),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CompanyStatusPage()),
              );
            },
          ),
        ],
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildAnimatedMenu(),
          ),
          Expanded(
            flex: 2,
            child: _buildSelectedContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedMenu() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 2.0,
        children: [
          _buildAnimatedButton(
              AppLocalizations.of(context)!.translate('view_users_list'),
              Icons.list),
          _buildAnimatedButton(
              AppLocalizations.of(context)!.translate('view_pending_requests'),
              Icons.pending),
          _buildAnimatedButton(
              AppLocalizations.of(context)!.translate('view_all_ads'),
              Icons.ad_units),
          _buildAnimatedButton(
              AppLocalizations.of(context)!.translate('view_all_tickets'),
              Icons.confirmation_number),
          _buildAnimatedButton(
              AppLocalizations.of(context)!.translate('add_quizz'), Icons.quiz),
          _buildAnimatedButton(
              AppLocalizations.of(context)!.translate('view_all_messages'),
              Icons.message),
          _buildAnimatedButton(
              AppLocalizations.of(context)!.translate('start_a_chat'),
              Icons.chat),
          _buildAnimatedButton(
              AppLocalizations.of(context)!.translate('view_winners'),
              Icons.emoji_events), // New button for winners
        ],
      ),
    );
  }

  Widget _buildAnimatedButton(String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMenuItem = label;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green, Colors.blue, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedContent() {
    if (_selectedMenuItem == 'Home') {
      return Center(
        child: Image.asset('assets/images/logo---.png', height: 100),
      );
    }

    switch (_selectedMenuItem) {
      case 'View Users List':
        return UserListPage();
      case 'View Pending Requests':
        return PendingRequestsPage(currentUserEmail: currentUserEmail);
      case 'View All Ads':
        return AllAdsPage();
      case 'View All Tickets':
        return TicketsPage();
      case 'Add Quizz':
        return QuizzAdminPage();
      case 'View All Messages':
        return AdminMessagesPage();
      case 'Start a Chat':
        return UserSelectionPage();
      case 'View Winners':
        return WinnersPage(); // Handle the new menu item
      default:
        return const SizedBox();
    }
  }
}
