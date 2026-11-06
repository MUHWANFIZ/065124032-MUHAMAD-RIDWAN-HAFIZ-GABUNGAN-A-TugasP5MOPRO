import 'json_utils.dart';

class Comment {
  const Comment({
    required this.id,
    required this.body,
    required this.postId,
    required this.likes,
    required this.user,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: asJsonInt(json['id']),
      body: asJsonString(json['body']),
      postId: asJsonInt(json['postId']),
      likes: asJsonInt(json['likes']),
      user: CommentUser.fromJson(json['user'] as Map<String, dynamic>?),
    );
  }

  final int id;
  final String body;
  final int postId;
  final int likes;
  final CommentUser user;
}

class CommentUser {
  const CommentUser({
    required this.id,
    required this.username,
    required this.fullName,
  });

  factory CommentUser.fromJson(Map<String, dynamic>? json) {
    final fullName = json?['fullName']?.toString().trim();
    return CommentUser(
      id: asJsonInt(json?['id']),
      username: asJsonString(json?['username']),
      fullName: (fullName == null || fullName.isEmpty) ? 'Anonymous' : fullName,
    );
  }

  final int id;
  final String username;
  final String fullName;

  String get initials {
    final parts = fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.map((part) => part[0].toUpperCase()).join();
  }
}
