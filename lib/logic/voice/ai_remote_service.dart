import 'dart:convert';
import 'package:http/http.dart' as http;

class AiRemoteService {
  // Toggle between Cloudflare tunnel or local LAN
  static bool useCloudflare = true;

  // 👉 Update this URL whenever Cloudflare gives you a new one
  static String cloudflareUrl = "https://birth-detection-mines-incorporated.trycloudflare.com";

  // 👉 Local testing at home (LAN)
  static const String localUrl = "http://192.168.0.121:8000";

  static String get baseUrl => useCloudflare ? cloudflareUrl : localUrl;

  static Future<Map<String, dynamic>?> interpret(String text) async {
    try {
      final uri = Uri.parse("$baseUrl/interpret");

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
