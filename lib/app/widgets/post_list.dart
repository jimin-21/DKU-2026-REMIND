import 'package:flutter/material.dart';
import '../data/mock_posts.dart';
import '../models/post.dart';
import '../models/post_status.dart';
import '../theme/app_categories.dart';
import '../theme/app_colors.dart';
import 'post_card.dart';

class PostList extends StatefulWidget {
  final String category;
  final String searchQuery;
  final bool showArchived;
  final bool isInArchive;
  final bool isInMine;
  final bool showHeader;

  const PostList({
    super.key,
    required this.category,
    this.searchQuery = '',
    this.showArchived = false,
    this.isInArchive = false,
    this.isInMine = false,
    this.showHeader = true,
  });

  @override
  State<PostList> createState() => _PostListState();
}

class _PostListState extends State<PostList> {
  String sortOrder = 'recent';

  final Map<int, PostStatus> postStatuses = {};
  final Map<int, bool> pinnedPosts = {};
  final Map<int, bool> readPosts = {};

  void handleStatusChange(int postId, PostStatus status) {
    setState(() {
      postStatuses[postId] = status;
    });
  }

  void handlePinChange(int postId, bool isPinned) {
    setState(() {
      pinnedPosts[postId] = isPinned;
    });
  }

  void handleReadChange(int postId, bool isRead) {
    setState(() {
      readPosts[postId] = isRead;
    });
  }

  List<Post> getFilteredPosts() {
    List<Post> posts;

    if (widget.isInMine) {
      posts = [...minePosts];
    } else {
      posts = [...allPosts];
    }

    if (widget.category == '즐겨찾기') {
      posts = posts.where((p) => p.isFavorite).toList();
    } else if (widget.category == '기타') {
      posts = posts
          .where((p) => !AppCategories.mainCategories.contains(p.category))
          .toList();
    } else if (widget.category != '전체') {
      posts = posts.where((p) => p.category == widget.category).toList();
    }

    if (widget.searchQuery.isNotEmpty) {
      final q = widget.searchQuery.toLowerCase();
      posts = posts.where((p) {
        return p.title.toLowerCase().contains(q) ||
            p.keyPoints.any((pt) => pt.toLowerCase().contains(q));
      }).toList();
    }

    posts = posts.where((p) {
      final currentStatus = postStatuses[p.id] ?? p.status;

      if (widget.isInMine) {
        return currentStatus == PostStatus.mine;
      }

      if (widget.showArchived) {
        return currentStatus == PostStatus.archived;
      }

      return currentStatus != PostStatus.archived &&
          currentStatus != PostStatus.deleted;
    }).toList();

    posts = posts.map((p) {
      return p.copyWith(
        status: postStatuses[p.id] ?? p.status,
        isPinned: pinnedPosts[p.id] ?? p.isPinned,
        isRead: readPosts[p.id] ?? p.isRead,
      );
    }).toList();

    posts.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;

      final aIsRead = a.status == PostStatus.done || a.isRead;
      final bIsRead = b.status == PostStatus.done || b.isRead;

      if (!aIsRead && bIsRead) return -1;
      if (aIsRead && !bIsRead) return 1;

      if (sortOrder == 'recent') {
        return b.date.compareTo(a.date);
      } else {
        return a.date.compareTo(b.date);
      }
    });

    return posts;
  }

  @override
  Widget build(BuildContext context) {
    final posts = getFilteredPosts();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        if (widget.showHeader)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '총 ${posts.length}개의 ${widget.isInMine ? '컬렉션' : '보관된 기록'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    sortOrder = sortOrder == 'recent' ? 'oldest' : 'recent';
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.subtleBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        sortOrder == 'recent' ? '최근 저장순' : '오래된순',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.sort,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        if (widget.showHeader) const SizedBox(height: 16),
        ...posts.map(
          (post) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: PostCard(
              post: post,
              onStatusChange: handleStatusChange,
              onPinChange: handlePinChange,
              onReadChange: handleReadChange,
              isInArchive: widget.isInArchive,
              isInMine: widget.isInMine,
            ),
          ),
        ),
      ],
    );
  }
}