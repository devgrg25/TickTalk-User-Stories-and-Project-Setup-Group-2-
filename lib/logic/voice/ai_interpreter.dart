import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_command.dart';

class AiInterpreter {
  static bool useCloudflare = true;

  static String cloudflareUrl =
      "https://agenda-term-against-fate.trycloudflare.com";
  static String localUrl = "http://192.168.0.121:8000";

  static String get baseUrl => useCloudflare ? cloudflareUrl : localUrl;

  static Map<String, dynamic>? lastRawJson;

  // NORMAL MODE
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
      lastRawJson = jsonDecode(response.body);

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) return null;

      return AiCommand.fromJson(json);

    } catch (e) {
      print("❌ AI Interpreter Exception: $e");
      return null;
    }
  }

  // SUMMARY MODE
  static Future<AiCommand?> interpretSummary({
    required String rawText,
    required int totalMs,
    required List<int> lapsMs,
  }) async {
    final url = Uri.parse("$baseUrl/interpret");

    final payload = {
      "text": rawText,
      "totalMs": totalMs,
      "lapsMs": lapsMs,
    };

    print("🌐 AI summary request: $payload");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      print("🌐 AI summary response: ${response.body}");
      lastRawJson = jsonDecode(response.body);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return null;

      return AiCommand.fromJson(data);

    } catch (e) {
      print("❌ AI Summary Interpreter Exception: $e");
      return null;
    }
  }
}
