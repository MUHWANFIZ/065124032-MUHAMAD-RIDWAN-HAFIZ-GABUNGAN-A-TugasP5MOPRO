import 'json_utils.dart';

class Post {
  const Post({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    required this.reactions,
    required this.views,
    required this.userId,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: asJsonInt(json['id']),
      title: asJsonString(json['title']),
      body: asJsonString(json['body']),
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((tag) => tag.toString())
          .toList(),
      reactions: Reactions.fromJson(
        json['reactions'] as Map<String, dynamic>?,
      ),
      views: asJsonInt(json['views']),
      userId: asJsonInt(json['userId']),
    );
  }

  final int id;
  final String title;
  final String body;
  final List<String> tags;
  final Reactions reactions;
  final int views;
  final int userId;

  int get likes => reactions.likes;
  int get dislikes => reactions.dislikes;

  String get preview {
    const maxLength = 140;
    if (body.length <= maxLength) return body;
    return '${body.substring(0, maxLength).trimRight()}…';
  }
}

class PostPage {
  const PostPage({required this.posts, required this.total});

  factory PostPage.fromJson(Map<String, dynamic> json) {
    final items = json['posts'] as List<dynamic>? ?? const [];
    return PostPage(
      posts: items
          .map((item) => Post.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: asJsonInt(json['total']),
    );
  }

  final List<Post> posts;
  final int total;
}

class Reactions {
  const Reactions({required this.likes, required this.dislikes});

  factory Reactions.fromJson(Map<String, dynamic>? json) {
    return Reactions(
      likes: asJsonInt(json?['likes']),
      dislikes: asJsonInt(json?['dislikes']),
    );
  }

  final int likes;
  final int dislikes;
}

