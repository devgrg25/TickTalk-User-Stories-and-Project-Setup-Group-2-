import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_command.dart';

class AiInterpreter {
  static bool useCloudflare = true;

  static String cloudflareUrl =
      "https://explosion-bulk-shows-condition.trycloudflare.com";

  static String localUrl = "http://192.168.0.121:8000";

  static String get baseUrl => useCloudflare ? cloudflareUrl : localUrl;

  static Map<String, dynamic>? lastRawJson;

  // -------------------------------------------------------------
  // NORMAL MODE
  // -------------------------------------------------------------
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
        print("❌ Backend status ${response.statusCode}");
        return null;
      }

      final json = jsonDecode(response.body);
      lastRawJson = json;

      // must be object
      if (json is! Map<String, dynamic>) {
        print("❌ AI response is not JSON object");
        return null;
      }

      // ignore backend error messages
      final type = json["type"];
      if (type == null || type == "" || type == "error") {
        print("⚠️ AI returned error or unknown type: ${json["message"]}");
        return null;
      }

      // success → build command
      try {
        return AiCommand.fromJson(json);
      } catch (e) {
        print("❌ Failed to parse AiCommand: $e");
        return null;
      }

    } catch (e) {
      print("❌ AI Interpreter Exception: $e");
      return null;
    }
  }

  // -------------------------------------------------------------
  // SUMMARY MODE
  // -------------------------------------------------------------
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

      if (response.statusCode != 200) {
        print("❌ Backend status ${response.statusCode}");
        return null;
      }

      final json = jsonDecode(response.body);
      lastRawJson = json;

      // not an object? ignore
      if (json is! Map<String, dynamic>) {
        print("❌ AI summary response not JSON object");
        return null;
      }

      // error handling
      final type = json["type"];
      if (type == null || type == "" || type == "error") {
        print("⚠️ Summary error: ${json["message"]}");
        return null;
      }

      // build command
      try {
        return AiCommand.fromJson(json);
      } catch (e) {
        print("❌ Failed to parse summary AiCommand: $e");
        return null;
      }

    } catch (e) {
      print("❌ AI Summary Interpreter Exception: $e");
      return null;
    }
  }
}
