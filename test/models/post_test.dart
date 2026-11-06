import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_pertemuan5/models/post.dart';

void main() {
  group('Post.fromJson', () {
    test('maps every field from the DummyJSON payload', () {
      final post = Post.fromJson(const {
        'id': 1,
        'title': 'His mother had always taught him',
        'body': 'His mother had always taught him not to think of himself as better.',
        'tags': ['history', 'american', 'crime'],
        'reactions': {'likes': 192, 'dislikes': 25},
        'views': 305,
        'userId': 121,
      });

      expect(post.id, 1);
      expect(post.title, 'His mother had always taught him');
      expect(post.body, startsWith('His mother had always taught him'));
      expect(post.tags, ['history', 'american', 'crime']);
      expect(post.likes, 192);
      expect(post.dislikes, 25);
      expect(post.views, 305);
      expect(post.userId, 121);
    });

    test('falls back to safe defaults for missing collections and counters',
        () {
      final post = Post.fromJson(const {
        'id': 2,
        'title': 'Minimal post',
        'body': 'Only the required fields are present.',
        'userId': 7,
      });

      expect(post.tags, isEmpty);
      expect(post.likes, 0);
      expect(post.dislikes, 0);
      expect(post.views, 0);
    });
  });

  group('PostPage.fromJson', () {
    test('maps the post list and total count', () {
      final page = PostPage.fromJson(const {
        'posts': [
          {
            'id': 1,
            'title': 'First',
            'body': 'Body',
            'tags': <String>[],
            'reactions': {'likes': 1, 'dislikes': 0},
            'views': 10,
            'userId': 5,
          },
          {
            'id': 2,
            'title': 'Second',
            'body': 'Body',
            'tags': <String>[],
            'reactions': {'likes': 2, 'dislikes': 1},
            'views': 20,
            'userId': 6,
          },
        ],
        'total': 251,
        'skip': 0,
        'limit': 2,
      });

      expect(page.posts, hasLength(2));
      expect(page.posts.first.title, 'First');
      expect(page.total, 251);
    });

    test('treats a missing list as empty', () {
      final page = PostPage.fromJson(const {'total': 0});

      expect(page.posts, isEmpty);
      expect(page.total, 0);
    });
  });
}
