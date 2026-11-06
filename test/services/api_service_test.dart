import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tugas_pertemuan5/services/api_service.dart';

void main() {
  group('ApiService.fetchPosts', () {
    test('requests the paginated post list and parses the page', () async {
      late Uri requested;
      final service = ApiService(
        client: MockClient((request) async {
          requested = request.url;
          return http.Response(
            jsonEncode({
              'posts': [
                {
                  'id': 1,
                  'title': 'First post',
                  'body': 'Body',
                  'tags': <String>[],
                  'reactions': {'likes': 3, 'dislikes': 1},
                  'views': 12,
                  'userId': 9,
                },
              ],
              'total': 251,
              'skip': 10,
              'limit': 10,
            }),
            200,
          );
        }),
      );

      final page = await service.fetchPosts(limit: 10, skip: 10);

      expect(requested.path, '/posts');
      expect(requested.queryParameters['limit'], '10');
      expect(requested.queryParameters['skip'], '10');
      expect(page.posts.single.title, 'First post');
      expect(page.total, 251);
    });

    test('uses the search endpoint when a query is provided', () async {
      late Uri requested;
      final service = ApiService(
        client: MockClient((request) async {
          requested = request.url;
          return http.Response(
            jsonEncode({
              'posts': <dynamic>[],
              'total': 0,
              'skip': 0,
              'limit': 10,
            }),
            200,
          );
        }),
      );

      await service.fetchPosts(query: 'love');

      expect(requested.path, '/posts/search');
      expect(requested.queryParameters['q'], 'love');
      expect(requested.queryParameters['limit'], '10');
    });

    test('throws ApiException when the server responds with an error',
        () async {
      final service = ApiService(
        client: MockClient((request) async => http.Response('nope', 500)),
      );

      expect(
        service.fetchPosts(),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            contains('500'),
          ),
        ),
      );
    });
  });

  group('ApiService.fetchComments', () {
    test('requests comments by post id and parses them', () async {
      late Uri requested;
      final service = ApiService(
        client: MockClient((request) async {
          requested = request.url;
          return http.Response(
            jsonEncode({
              'comments': [
                {
                  'id': 93,
                  'body': 'These are fabulous ideas!',
                  'postId': 1,
                  'likes': 7,
                  'user': {
                    'id': 190,
                    'username': 'leahw',
                    'fullName': 'Leah Gutierrez',
                  },
                },
              ],
              'total': 1,
            }),
            200,
          );
        }),
      );

      final comments = await service.fetchComments(1);

      expect(requested.path, '/comments/post/1');
      expect(comments.single.body, 'These are fabulous ideas!');
      expect(comments.single.user.fullName, 'Leah Gutierrez');
    });
  });
}
