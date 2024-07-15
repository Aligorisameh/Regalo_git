import 'package:flutter/material.dart';
import 'package:regalofficial/homePage.dart';
import 'package:regalofficial/screens/signup_screen.dart';
import 'package:regalofficial/screens/signin_screen.dart';
import 'package:regalofficial/screens/signin.dart';
import 'package:regalofficial/screens/our_partners.dart';
import 'package:regalofficial/screens/message_page.dart';
import 'package:regalofficial/screens/aboutUsPage.dart';

// import other screens as needed

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
            builder: (_) => HomeScreen(setLocale: (Locale locale) {}));
      case '/Signin':
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      case '/signin':
        return MaterialPageRoute(builder: (_) => const SignIn());
      case '/signup':
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case '/ourPartners':
        return MaterialPageRoute(builder: (_) => OurPartnersPage());
      case '/message':
        return MaterialPageRoute(builder: (_) => MessagePage());
      case '/aboutUs':
        return MaterialPageRoute(builder: (_) => AboutUsPage());

      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('404 - Not Found'),
        ),
      ),
    );
  }
}
