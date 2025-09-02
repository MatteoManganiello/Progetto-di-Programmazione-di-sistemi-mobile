import 'dart:convert';
import 'package:http/http.dart' as http;

/// Classe di supporto per chiamate HTTP REST.
/// Puoi usarla per GET/POST centralizzando baseUrl e gestione errori.
class BaseApi {
  final String baseUrl;
  final Map<String, String> defaultHeaders;

  BaseApi({
    required this.baseUrl,
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  });

  /// GET che ritorna una [Map] JSON decodificata
  Future<Map<String, dynamic>> getJson(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final r = await http.get(uri, headers: defaultHeaders);

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('Errore GET $endpoint [${r.statusCode}]');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postJson(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final r = await http.post(
      uri,
      headers: defaultHeaders,
      body: body != null ? jsonEncode(body) : null,
    );

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('Errore POST $endpoint [${r.statusCode}]');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}
