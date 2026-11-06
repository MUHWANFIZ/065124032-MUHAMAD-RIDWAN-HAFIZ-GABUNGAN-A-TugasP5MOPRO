import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/comment.dart';
import '../models/post.dart';

class ApiService {
  ApiService({
    http.Client? client,
    this.baseUrl = 'https://dummyjson.com',
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  static const _postFields = 'title,body,tags,reactions,views,userId';

  Future<PostPage> fetchPosts({
    int limit = 10,
    int skip = 0,
    String query = '',
  }) async {
    final search = query.trim();
    final json = await _get(
      search.isEmpty ? '/posts' : '/posts/search',
      {
        if (search.isNotEmpty) 'q': search,
        'limit': '$limit',
        'skip': '$skip',
        'select': _postFields,
      },
    );

    return PostPage.fromJson(json);
  }

  Future<List<Comment>> fetchComments(int postId) async {
    final json = await _get('/comments/post/$postId', null);
    final items = json['comments'] as List<dynamic>? ?? const [];
    return items
        .map((item) => Comment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String>? queryParameters,
  ) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );

    http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const ApiException('Koneksi ke server timeout. Coba lagi.');
    } catch (_) {
      throw const ApiException('Tidak dapat terhubung ke server.');
    }

    if (response.statusCode != 200) {
      throw ApiException('Gagal memuat data (HTTP ${response.statusCode}).');
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object.');
      }
      return decoded;
    } catch (_) {
      throw const ApiException('Respons API tidak valid.');
    }
  }

  void dispose() => _client.close();
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
