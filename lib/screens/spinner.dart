import 'package:flutter/material.dart';
import 'package:regalofficial/app_localizations.dart';

class CategorySelectionPage extends StatefulWidget {
  @override
  _CategorySelectionPageState createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('select_category'),
          style: TextStyle(color: Color(0xFFFF8008)),
        ),
        backgroundColor: Color(0xFF56AB2F),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              AppLocalizations.of(context)!.translate('select_a_category'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5E61F4),
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCategory,
                  hint: Text(
                    AppLocalizations.of(context)!
                        .translate('select_a_category'),
                    style: TextStyle(color: Color(0xFFCB2B93)),
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCategory = newValue;
                    });
                  },
                  items: <String>[
                    'Famous',
                    'geography',
                    'sport',
                    'general_culture',
                    'history'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        AppLocalizations.of(context)!.translate(value),
                        style: TextStyle(color: Color(0xFF9546C4)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFFF8008),
        onPressed: () {
          Navigator.pop(context, selectedCategory);
        },
        child: Icon(Icons.check, color: Colors.white),
      ),
    );
  }
}
