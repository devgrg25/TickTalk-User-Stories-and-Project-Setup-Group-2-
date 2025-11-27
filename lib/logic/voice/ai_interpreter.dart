import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_command.dart';

class AiInterpreter {
  // 👉 Choose which backend to use
  static bool useCloudflare = true;

  // 👉 Change ONLY this URL each time Cloudflare Tunnel gives you a new one
  static String cloudflareUrl = "https://intimate-flag-slightly-orientation.trycloudflare.com";

  // 👉 Home local network (not used on eduroam)
  static String localUrl = "http://192.168.0.121:8000";

  // Auto-select based on demo setting
  static String get baseUrl => useCloudflare ? cloudflareUrl : localUrl;

  static Future<AiCommand?> interpret(String rawText) async {
    final url = Uri.parse("$baseUrl/interpret");

    try {
      print("🌐 AI request: $rawText");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": rawText}),
      );

      print("🌐 AI response: ${response.body}");

      if (response.statusCode != 200) {
        print("❌ AI HTTP error: ${response.statusCode}");
        return null;
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        print("❌ AI response was not JSON Map");
        return null;
      }

      final cmd = AiCommand.fromJson(data);

      // 🔥 NEW DEBUGGING — show steps if backend sent any
      if (cmd.steps != null) {
        print("🧩 Parsed ${cmd.steps!.length} routine steps");
      }

      return cmd;

    } catch (e) {
      print("❌ AI interpreter exception: $e");
      return null;
    }
  }

  static String _normalize(String text) {
    final fillers = ["uh", "umm", "like", "you know"];
    text = text.toLowerCase();
    for (final f in fillers) {
      text = text.replaceAll(f, "");
    }
    return text.trim();
  }
}
