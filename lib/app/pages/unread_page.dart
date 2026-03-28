import 'package:flutter/material.dart';
import '../data/mock_posts.dart';
import '../models/post.dart';
import '../models/post_status.dart';
import '../theme/app_colors.dart';
import '../widgets/post_card.dart';

class UnreadPage extends StatefulWidget {
  const UnreadPage({super.key});

  @override
  State<UnreadPage> createState() => _UnreadPageState();
}

class _UnreadPageState extends State<UnreadPage> {
  final Map<int, PostStatus> postStatuses = {};
  final Map<int, bool> pinnedPosts = {};

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

  List<Post> getUnreadPosts() {
    return homePosts
        .where((post) {
          final s = postStatuses[post.id] ?? post.status;
          return s != PostStatus.done &&
              s != PostStatus.archived &&
              s != PostStatus.mine &&
              s != PostStatus.deleted;
        })
        .map((post) => post.copyWith(
              status: postStatuses[post.id] ?? post.status,
              isPinned: pinnedPosts[post.id] ?? post.isPinned,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final unreadPosts = getUnreadPosts();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.charcoal,
        title: Text(
          '놓친 요약 ${unreadPosts.length}개',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
        children: [
          const Text(
            '아직 확인하지 않은 카드들이에요. 꼼꼼히 읽고 넘겨보세요!',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          if (unreadPosts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(
                child: Text(
                  '모든 카드를 확인했습니다! 🎉',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            ...unreadPosts.map(
              (post) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PostCard(
                  post: post,
                  onStatusChange: handleStatusChange,
                  onPinChange: handlePinChange,
                ),
              ),
            ),
        ],
      ),
    );
  }
}