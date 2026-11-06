import 'package:flutter/material.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../widgets/comment_tile.dart';
import '../widgets/state_views.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.post,
    required this.api,
  });

  final Post post;
  final ApiService api;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Future<List<Comment>> _comments;

  @override
  void initState() {
    super.initState();
    _comments = widget.api.fetchComments(widget.post.id);
  }

  void _reloadComments() {
    setState(() {
      _comments = widget.api.fetchComments(widget.post.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Post')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(
                post.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in post.tags)
                    Chip(
                      label: Text('#$tag'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _Stat(icon: Icons.favorite_border, label: '${post.likes}'),
                  _Stat(
                    icon: Icons.thumb_down_outlined,
                    label: '${post.dislikes}',
                  ),
                  _Stat(
                    icon: Icons.visibility_outlined,
                    label: '${post.views}',
                  ),
                  _Stat(
                    icon: Icons.person_outline,
                    label: 'User ${post.userId}',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                post.body,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Komentar',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<Comment>>(
                future: _comments,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    final error = snapshot.error;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: ErrorView(
                        message: error is ApiException
                            ? error.message
                            : 'Gagal memuat komentar.',
                        onRetry: _reloadComments,
                      ),
                    );
                  }

                  final comments = snapshot.data ?? const <Comment>[];
                  if (comments.isEmpty) {
                    return const EmptyView(
                      message: 'Belum ada komentar untuk postingan ini.',
                      icon: Icons.chat_bubble_outline,
                    );
                  }

                  return Column(
                    children: [
                      for (final comment in comments)
                        CommentTile(comment: comment),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
        ),
      ],
    );
  }
}
