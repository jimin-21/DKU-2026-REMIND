import 'dart:math';
import 'package:flutter/material.dart';
import '../data/mock_posts.dart';
import '../models/post.dart';
import '../models/post_status.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import 'post_card.dart';

class HomeView extends StatefulWidget {
  final String searchQuery;

  const HomeView({
    super.key,
    this.searchQuery = '',
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<Post> randomPosts = [];
  final Map<int, PostStatus> postStatuses = {};
  final Map<int, bool> pinnedPosts = {};
  final Set<int> hiddenToday = {};

  @override
  void initState() {
    super.initState();
    refreshRandomPosts();
  }

  void refreshRandomPosts() {
    final availablePosts =
        homePosts.where((post) => !hiddenToday.contains(post.id)).toList();

    final shuffled = [...availablePosts];
    shuffled.shuffle(Random());

    setState(() {
      randomPosts = shuffled.take(2).toList();
    });
  }

  void sortRandomPosts(String type) {
    final availablePosts =
        homePosts.where((post) => !hiddenToday.contains(post.id)).toList();

    List<Post> sorted = [...availablePosts];

    if (type == 'recent') {
      sorted.sort((a, b) => b.date.compareTo(a.date));
    } else if (type == 'oldest') {
      sorted.sort((a, b) => a.date.compareTo(b.date));
    } else {
      sorted.shuffle(Random());
    }

    setState(() {
      randomPosts = sorted.take(2).toList();
    });
  }

  void handleStatusChange(int postId, PostStatus newStatus) {
    setState(() {
      postStatuses[postId] = newStatus;
    });
  }

  void handlePinChange(int postId, bool isPinned) {
    setState(() {
      pinnedPosts[postId] = isPinned;
    });
  }

  void handleHideToday(int postId) {
    setState(() {
      hiddenToday.add(postId);
    });
    refreshRandomPosts();
  }

  @override
  Widget build(BuildContext context) {
    List<Post> posts = homePosts.map((post) {
      return post.copyWith(
        status: postStatuses[post.id] ?? post.status,
        isPinned: pinnedPosts[post.id] ?? post.isPinned,
      );
    }).toList();

    if (widget.searchQuery.isNotEmpty) {
      final q = widget.searchQuery.toLowerCase();
      posts = posts.where((p) {
        return p.title.toLowerCase().contains(q) ||
            (p.source?.toLowerCase().contains(q) ?? false) ||
            p.tags.any((tag) => tag.toLowerCase().contains(q)) ||
            p.keyPoints.any((pt) => pt.toLowerCase().contains(q));
      }).toList();
    }

    posts = posts
        .where((p) => p.status == PostStatus.active || p.status == PostStatus.done)
        .toList();

    final pinnedPostsList = posts.where((p) => p.isPinned).toList();

    final unreadPosts = homePosts.where((p) {
      final s = postStatuses[p.id] ?? p.status;
      return s != PostStatus.done &&
          s != PostStatus.archived &&
          s != PostStatus.mine &&
          s != PostStatus.deleted;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        if (unreadPosts.isNotEmpty)
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.unread);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.butterYellow,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '놓친 요약 ${unreadPosts.length}개 보러가기',
                          style: const TextStyle(
                            color: AppColors.charcoal,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '아직 확인하지 않은 카드가 있어요',
                          style: TextStyle(
                            color: Color(0xFF495057),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    color: AppColors.charcoal,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        if (pinnedPostsList.isNotEmpty) ...[
          Row(
            children: const [
              Icon(
                Icons.push_pin_outlined,
                color: AppColors.peachDust,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '내가 고정한 카드',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...pinnedPostsList.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PostCard(
                post: post,
                onStatusChange: handleStatusChange,
                onPinChange: handlePinChange,
                isInFixedZone: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.auto_awesome,
                  color: AppColors.star,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  '오늘의 되돌아보기',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'recent') {
                  sortRandomPosts('recent');
                } else if (value == 'oldest') {
                  sortRandomPosts('oldest');
                } else {
                  refreshRandomPosts();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'recent', child: Text('최근 등록 순')),
                PopupMenuItem(value: 'oldest', child: Text('오래된 순')),
                PopupMenuItem(value: 'random', child: Text('랜덤')),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...randomPosts
            .where((p) => !hiddenToday.contains(p.id))
            .map(
              (post) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PostCard(
                  post: post,
                  onStatusChange: handleStatusChange,
                  onPinChange: handlePinChange,
                  isInRandomZone: true,
                  onHideToday: handleHideToday,
                  onRefreshRandom: refreshRandomPosts,
                ),
              ),
            ),
      ],
    );
  }
}