import 'package:flutter/material.dart';
import 'package:regalofficial/screens/homePage.dart';
import 'package:regalofficial/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flag/flag.dart';

class HomeScreen extends StatelessWidget {
  final Function(Locale) setLocale;

  const HomeScreen({Key? key, required this.setLocale}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Locale currentLocale = Localizations.localeOf(context);
    Locale dropdownValue = currentLocale.languageCode == 'en'
        ? const Locale('en', 'US')
        : const Locale('ar', 'SA');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('welcome'),
          style: GoogleFonts.pacifico(
            textStyle: const TextStyle(
              color: Color(0xFF56AB2F), // Dark Green color
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Colors.white, // White background color
        actions: [
          DropdownButton<Locale>(
            value: dropdownValue,
            icon: const Icon(Icons.language,
                color: Color(0xFFA8E063)), // Light Green color
            items: [
              DropdownMenuItem(
                value: const Locale('en', 'US'),
                child: Row(
                  children: [
                    Flag.fromCode(FlagsCode.GB, height: 20, width: 30),
                    const SizedBox(width: 8),
                    const Text('English',
                        style: TextStyle(
                            color: Color(0xFF56AB2F))), // Dark Green color
                  ],
                ),
              ),
              DropdownMenuItem(
                value: const Locale('ar', 'SA'),
                child: Row(
                  children: [
                    Flag.fromCode(FlagsCode.SA, height: 20, width: 30),
                    const SizedBox(width: 8),
                    const Text('العربية',
                        style: TextStyle(
                            color: Color(0xFF56AB2F))), // Dark Green color
                  ],
                ),
              ),
            ],
            onChanged: (Locale? locale) {
              if (locale != null) {
                setLocale(locale);
              }
            },
          ),
        ],
      ),
      body: const HomePage(),
    );
  }
}
