/// Simple in-memory config — URL defaults to localhost.
/// Use the Settings screen to change it at runtime (persists for the session).
class ConfigService {
  static String _baseUrl = 'http://127.0.0.1:8000';

  static String getBaseUrl() => _baseUrl;

  static void setBaseUrl(String url) {
    _baseUrl = url.trim().replaceAll(RegExp(r'/$'), '');
  }
}
