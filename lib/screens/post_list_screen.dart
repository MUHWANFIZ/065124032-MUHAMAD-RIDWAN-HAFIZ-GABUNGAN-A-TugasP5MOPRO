import 'dart:async';

import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/api_service.dart';
import '../widgets/post_card.dart';
import '../widgets/state_views.dart';
import 'post_detail_screen.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  static const _pageSize = 10;
  static const _searchPageSize = 30;

  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _debounce;
  List<Post> _posts = const [];
  int _total = 0;
  String _query = '';
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  int _requestId = 0;
  String? _error;

  int get _currentPageSize => _query.isEmpty ? _pageSize : _searchPageSize;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchControllerChanged);
    _fetchFirstPage(++_requestId);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _api.dispose();
    super.dispose();
  }

  void _onSearchControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final next = value.trim();
      if (next == _query) return;
      _query = next;
      _loadFirstPage();
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    if (_query.isEmpty) return;
    _query = '';
    _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    final requestId = ++_requestId;
    setState(() {
      _isInitialLoading = true;
      _isLoadingMore = false;
      _error = null;
      _posts = const [];
      _total = 0;
    });
    await _fetchFirstPage(requestId);
  }

  Future<void> _refresh() async {
    final requestId = ++_requestId;
    setState(() {
      _isLoadingMore = false;
      _error = null;
    });
    await _fetchFirstPage(requestId);
  }

  Future<void> _fetchFirstPage(int requestId) async {
    try {
      final page = await _api.fetchPosts(
        limit: _currentPageSize,
        skip: 0,
        query: _query,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _posts = page.posts;
        _total = page.total;
        _isInitialLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted || requestId != _requestId) return;
      _handleFirstPageError(error.message);
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      _handleFirstPageError('Terjadi kesalahan tak terduga.');
    }
  }

  void _handleFirstPageError(String message) {
    if (_posts.isEmpty) {
      setState(() {
        _error = message;
        _isInitialLoading = false;
      });
    } else {
      setState(() => _isInitialLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isInitialLoading ||
        _isLoadingMore ||
        _posts.length >= _total ||
        _error != null) {
      return;
    }

    final requestId = _requestId;
    setState(() => _isLoadingMore = true);

    try {
      final page = await _api.fetchPosts(
        limit: _currentPageSize,
        skip: _posts.length,
        query: _query,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _posts = [..._posts, ...page.posts];
        _total = page.total;
        _isLoadingMore = false;
      });
    } on ApiException catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() => _isLoadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  void _openDetail(Post post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(post: post, api: _api),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post & Comment Explorer'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _loadFirstPage,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onQueryChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Cari postingan…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus pencarian',
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close),
                          ),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isInitialLoading) {
      return const LoadingView();
    }

    if (_error != null && _posts.isEmpty) {
      return _refreshable(
        ErrorView(message: _error!, onRetry: _loadFirstPage),
      );
    }

    if (_posts.isEmpty) {
      return _refreshable(
        EmptyView(
          message: _query.isEmpty
              ? 'Belum ada postingan.'
              : 'Tidak ada postingan untuk "$_query".',
          icon: Icons.article_outlined,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _posts.length + 1,
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return _buildFooter();
          }
          final post = _posts[index];
          return PostCard(post: post, onTap: () => _openDetail(post));
        },
      ),
    );
  }

  Widget _refreshable(Widget child) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (_posts.length >= _total) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text('Semua $_total postingan sudah dimuat', style: style),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text('Menampilkan ${_posts.length} dari $_total postingan',
              style: style),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loadMore,
            icon: const Icon(Icons.expand_more),
            label: const Text('Muat lebih banyak'),
          ),
        ],
      ),
    );
  }
}
