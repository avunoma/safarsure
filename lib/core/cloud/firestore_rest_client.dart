import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:safarsure/core/cloud/firestore_rest_codec.dart';

/// Firestore REST client for shared demo cloud (no google-services.json needed).
class FirestoreRestClient {
  FirestoreRestClient({
    required this.projectId,
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String projectId;
  final String apiKey;
  final http.Client _client;

  DateTime? _listBackoffUntil;

  String get _base =>
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  Uri _uri(String path, [Map<String, String>? extraQuery]) {
    return Uri.parse('$_base/$path').replace(
      queryParameters: {
        'key': apiKey,
        ...?extraQuery,
      },
    );
  }

  Uri _uriWithMask(String path, Map<String, dynamic> data) {
    final params = <String>[
      'key=${Uri.encodeQueryComponent(apiKey)}',
      for (final key in data.keys)
        'updateMask.fieldPaths=${Uri.encodeQueryComponent(key)}',
    ];
    return Uri.parse('$_base/$path?${params.join('&')}');
  }

  bool get _inListBackoff =>
      _listBackoffUntil != null && DateTime.now().isBefore(_listBackoffUntil!);

  void _applyListBackoff([Duration duration = const Duration(seconds: 30)]) {
    _listBackoffUntil = DateTime.now().add(duration);
  }

  Future<void> setDocument(String path, Map<String, dynamic> data) async {
    final body = jsonEncode({'fields': encodeFirestoreFields(data)});
    final uri = _uriWithMask(path, data);
    final response = await _client.patch(uri, headers: _headers, body: body);

    if (response.statusCode == 429) {
      _applyListBackoff();
      return;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Firestore write failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>?> getDocument(String path) async {
    if (_inListBackoff) return null;

    final response = await _client.get(_uri(path), headers: _headers);
    if (response.statusCode == 404) return null;
    if (response.statusCode == 429) {
      _applyListBackoff();
      return null;
    }
    if (response.statusCode != 200) {
      throw StateError(
        'Firestore read failed (${response.statusCode}): ${response.body}',
      );
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return decodeFirestoreDocument(json);
  }

  Future<List<Map<String, dynamic>>> listCollection(String collectionPath) async {
    if (_inListBackoff) return [];

    final response = await _client.get(_uri(collectionPath), headers: _headers);
    if (response.statusCode == 429) {
      _applyListBackoff();
      return [];
    }
    if (response.statusCode != 200) {
      throw StateError(
        'Firestore list failed (${response.statusCode}): ${response.body}',
      );
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final docs = json['documents'] as List<dynamic>? ?? [];
    return docs
        .map((d) => decodeFirestoreDocument(d as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> listSubcollection(
    String parentPath,
    String subcollection,
  ) async {
    return listCollection('$parentPath/$subcollection');
  }

  Map<String, String> get _headers => {'Content-Type': 'application/json'};
}
