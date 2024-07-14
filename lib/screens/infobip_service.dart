import 'dart:convert';
import 'package:http/http.dart' as http;

class InfobipService {
  final String apiKey =
      '64a170c10ca1fdd65eff04e72b735212-dc1a4c89-306d-4b1f-aec0-1278c2a22b79';
  final String baseUrl = 'https://2v2zvp.api.infobip.com';

  Future<bool> sendOtp(String phoneNumber) async {
    final url = '$baseUrl/otp/1/sms';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'App $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'to': phoneNumber,
        'message': 'Your OTP code is {{otp}}',
        'from': 'InfoSMS',
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    final url = '$baseUrl/otp/1/verify';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'App $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'to': phoneNumber,
        'otp': otp,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
}
