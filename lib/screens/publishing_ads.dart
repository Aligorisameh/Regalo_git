import 'package:flutter/material.dart';

class PublishAdPage extends StatelessWidget {
  final String companyName;
  final String adType;

  const PublishAdPage({
    Key? key,
    required this.companyName,
    required this.adType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Publish Ad'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Company Name: $companyName',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              'Ad Type: $adType',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement the publish logic here
                print('Ad published!');
              },
              child: Text('Publish'),
            ),
          ],
        ),
      ),
    );
  }
}
