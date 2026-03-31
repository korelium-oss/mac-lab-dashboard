import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config_service.dart';

/// Central API service connecting Flutter app → FastAPI (mac-lab-backend)
class ApiService {
  static String get _base => ConfigService.getBaseUrl();

  // ---------------------------------------------------------------------------
  // STATUS
  // ---------------------------------------------------------------------------
  static Future<Map<String, bool>> fetchStatus() async {
    final res = await http
        .get(Uri.parse('$_base/status'))
        .timeout(const Duration(seconds: 60));
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final raw = decoded['machines'] as Map<String, dynamic>;
    return raw.map((k, v) => MapEntry(k, v == true));
  }

  // ---------------------------------------------------------------------------
  // POWER — SINGLE
  // ---------------------------------------------------------------------------
  static Future<void> reboot(String host) async =>
      http.post(Uri.parse('$_base/reboot/$host'));

  static Future<void> shutdown(String host) async =>
      http.post(Uri.parse('$_base/shutdown/$host'));

  static Future<void> sleep(String host) async =>
      http.post(Uri.parse('$_base/sleep/$host'));

  // ---------------------------------------------------------------------------
  // POWER — LAB-WIDE
  // ---------------------------------------------------------------------------
  static Future<void> rebootAll() async =>
      http.post(Uri.parse('$_base/reboot-all'));

  static Future<void> shutdownAll() async =>
      http.post(Uri.parse('$_base/shutdown-all'));

  static Future<void> sleepAll() async =>
      http.post(Uri.parse('$_base/sleep-all'));

  static Future<void> wake(String host) async =>
      http.post(Uri.parse('$_base/wake/$host'));

  static Future<void> wakeAll() async =>
      http.post(Uri.parse('$_base/wake-all'));

  static Future<void> killAll() async =>
      http.post(Uri.parse('$_base/emergency/kill'));

  // ---------------------------------------------------------------------------
  // PACKAGE — REMOVE
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> removePkg({
    required int id,
    required String type,
    required String name,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/pkg/remove/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'type': type, 'name': name}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // NOTIFY (silent desktop notification)
  // ---------------------------------------------------------------------------
  static Future<void> notifyHost(String host, String message) async =>
      http.post(
        Uri.parse('$_base/notify/$host'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

  static Future<void> notifyAll(String message) async =>
      http.post(
        Uri.parse('$_base/notify-all'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

  // ---------------------------------------------------------------------------
  // ALERT (notification + sound)
  // ---------------------------------------------------------------------------
  static Future<void> alertHost(String host, String message) async =>
      http.post(
        Uri.parse('$_base/alert/$host'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

  static Future<void> alertAll(String message) async =>
      http.post(
        Uri.parse('$_base/alert-all'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

  // ---------------------------------------------------------------------------
  // BREW — STREAMING INSTALL
  // ---------------------------------------------------------------------------
  static Future<Stream<String>> installStream({
    required String macId,
    required String type,
    required String name,
  }) async {
    final uri =
        Uri.parse('$_base/brew/install/$macId/stream?type=$type&name=$name');
    final request = http.Request('GET', uri);
    final response = await request.send();
    return response.stream.transform(utf8.decoder);
  }

  // ---------------------------------------------------------------------------
  // BREW — STOP
  // ---------------------------------------------------------------------------
  static Future<void> stopInstall(String macId) async =>
      http.post(Uri.parse('$_base/brew/stop/$macId'));
}
