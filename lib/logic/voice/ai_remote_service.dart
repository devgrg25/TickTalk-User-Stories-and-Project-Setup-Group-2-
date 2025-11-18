import 'dart:convert';
import 'package:http/http.dart' as http;

class AiRemoteService {
  /// For emulator/desktop only.
  /// If testing on Android device later, we will replace with your LAN IP.
  static const String _baseUrl = "http://192.168.0.121";

  static Future<Map<String, dynamic>?> interpret(String text) async {
    try {
      final uri = Uri.parse("$_baseUrl/interpret");
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": text}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("❌ Backend error: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Network error: $e");
      return null;
    }
  }
}
