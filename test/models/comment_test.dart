import 'package:flutter_test/flutter_test.dart';
import 'package:tugas_pertemuan5/models/comment.dart';

void main() {
  group('Comment.fromJson', () {
    test('maps the comment and its nested user', () {
      final comment = Comment.fromJson(const {
        'id': 93,
        'body': 'These are fabulous ideas!',
        'postId': 1,
        'likes': 7,
        'user': {
          'id': 190,
          'username': 'leahw',
          'fullName': 'Leah Gutierrez',
        },
      });

      expect(comment.id, 93);
      expect(comment.body, 'These are fabulous ideas!');
      expect(comment.postId, 1);
      expect(comment.likes, 7);
      expect(comment.user.id, 190);
      expect(comment.user.username, 'leahw');
      expect(comment.user.fullName, 'Leah Gutierrez');
    });

    test('uses a placeholder user when the payload omits it', () {
      final comment = Comment.fromJson(const {
        'id': 1,
        'body': 'Anonymous thoughts.',
        'postId': 2,
        'likes': 0,
      });

      expect(comment.user.fullName, 'Anonymous');
      expect(comment.user.initials, 'A');
    });
  });
}
