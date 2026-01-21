import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  final http.Client _client;
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Uri _u(String path, [Map<String, dynamic>? q]) {
    final base = ApiConfig.baseUrl;
    return Uri.parse('$base$path')
        .replace(queryParameters: q?.map((k, v) => MapEntry(k, '$v')));
  }

  Map<String, dynamic> _decodeObj(http.Response r) {
    final body = r.body.trim();
    if (body.isEmpty) return {};
    final data = jsonDecode(body);
    if (data is Map) return data.cast<String, dynamic>();
    throw ApiException(r.statusCode, 'Respuesta no es JSON object: $body');
  }

  List<dynamic> _decodeList(http.Response r) {
    final body = r.body.trim();
    if (body.isEmpty) return [];
    final data = jsonDecode(body);
    if (data is List) return data;
    throw ApiException(r.statusCode, 'Respuesta no es JSON list: $body');
  }

  void _throwIfError(http.Response r) {
    if (r.statusCode < 400) return;

    // Si el backend devuelve { "error": "..." } lo mostramos
    try {
      final obj = _decodeObj(r);
      final msg = (obj['error']?.toString().trim().isNotEmpty ?? false)
          ? obj['error'].toString()
          : r.body;
      throw ApiException(r.statusCode, msg);
    } on ApiException {
      rethrow; // NO lo vuelvas a envolver
    } catch (_) {
      // Si no se pudo parsear JSON, mostramos body crudo
      throw ApiException(r.statusCode, r.body);
    }
  }

  Future<Map<String, dynamic>> getObj(String path) async {
    final r = await _client.get(_u(path));
    _throwIfError(r);
    return _decodeObj(r);
  }

  Future<List<dynamic>> getList(String path) async {
    final r = await _client.get(_u(path));
    _throwIfError(r);
    return _decodeList(r);
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final r = await _client.post(
      _u(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _throwIfError(r);
    return _decodeObj(r);
  }

  Future<Map<String, dynamic>> patchJson(String path, Map<String, dynamic> body) async {
    final r = await _client.patch(
      _u(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _throwIfError(r);
    return _decodeObj(r);
  }

  Future<Map<String, dynamic>> deleteObj(String path) async {
    final r = await _client.delete(_u(path));
    _throwIfError(r);
    return _decodeObj(r);
  }
}
