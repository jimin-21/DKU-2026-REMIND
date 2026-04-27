import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

class UnreadPage extends StatefulWidget {
  const UnreadPage({super.key});

  @override
  State<UnreadPage> createState() => _UnreadPageState();
}

class _UnreadPageState extends State<UnreadPage> {
  final FirestoreService _firestoreService = FirestoreService();

  List<Map<String, dynamic>> unreadPosts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUnreadPosts();
  }

  Future<void> loadUnreadPosts() async {
    final data = await _firestoreService.getPosts();

    if (!mounted) return;

    setState(() {
      unreadPosts = data.where((post) {
        final bool isRead = post['isRead'] ?? false;
        final bool isDeleted = post['isDeleted'] ?? false;
        final bool isCollected = post['isCollected'] ?? false;

        return !isRead && !isDeleted && !isCollected;
      }).toList();
      isLoading = false;
    });
  }

  Future<void> toggleReadStatus(String id, bool currentValue) async {
    await _firestoreService.updateReadStatus(id, !currentValue);
    await loadUnreadPosts();
  }

  Future<void> toggleFavoriteStatus(String id, bool currentValue) async {
    await _firestoreService.updateFavoriteStatus(id, !currentValue);
    await loadUnreadPosts();
  }

  Future<void> togglePinnedStatus(String id, bool currentValue) async {
    await _firestoreService.updatePinnedStatus(id, !currentValue);
    await loadUnreadPosts();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(currentValue ? '고정을 해제했습니다.' : '홈에 고정했습니다.'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> moveToCollection(String id) async {
    await _firestoreService.updateCollectedStatus(id, true);
    await loadUnreadPosts();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('컬렉션으로 이동했습니다.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> moveToTrash(String id) async {
    await _firestoreService.moveToTrash(id);
    await loadUnreadPosts();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('휴지통으로 이동했습니다.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> showDeleteDialog(String id) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('휴지통 이동'),
          content: const Text('이 링크를 휴지통으로 이동할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('이동'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await moveToTrash(id);
    }
  }

  DateTime getCreatedAt(Map<String, dynamic> post) {
    final createdAt = post['createdAt'];

    if (createdAt == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    if (createdAt is DateTime) {
      return createdAt;
    }

    try {
      return createdAt.toDate();
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  String formatDate(dynamic createdAt) {
    try {
      if (createdAt == null) return '날짜 없음';

      if (createdAt is DateTime) {
        return '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}';
      }

      if (createdAt.toString().contains('Timestamp')) {
        final date = createdAt.toDate();
        return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
      }

      return createdAt.toString();
    } catch (_) {
      return '날짜 없음';
    }
  }

  String getDisplayTitle(Map<String, dynamic> post) {
    final title = (post['title'] ?? '').toString().trim();
    final url = (post['url'] ?? '').toString().trim();

    if (title.isNotEmpty) return title;
    if (url.isNotEmpty) return url;
    return '제목 없음';
  }

  List<String> getSummaryLines(Map<String, dynamic> post) {
    final summary = (post['summary'] ?? '').toString().trim();
    final url = (post['url'] ?? '').toString().trim();

    if (summary.isNotEmpty) {
      return summary
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .map((e) => e.replaceFirst(RegExp(r'^[•\-\*\.·]+\s*'), ''))
          .where((e) => e.isNotEmpty)
          .take(3)
          .toList();
    }

    if (url.isNotEmpty) {
      return [url];
    }

    return ['요약 정보가 없습니다.'];
  }

  List<String> getTags(Map<String, dynamic> post) {
    final rawTags = post['tags'];

    if (rawTags is List) {
      final parsed = rawTags
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .map((e) => e.startsWith('#') ? e : '#$e')
          .take(3)
          .toList();

      if (parsed.isNotEmpty) return parsed;
    }

    final category = (post['category'] ?? '기타').toString();
    switch (category) {
      case '자기계발':
        return ['#기록', '#습관'];
      case '운동':
        return ['#헬스', '#기록'];
      case '장소':
        return ['#장소', '#저장'];
      case '쇼핑':
        return ['#쇼핑', '#구매'];
      default:
        return ['#링크', '#저장'];
    }
  }

  Color getCategoryChipColor(String category) {
    switch (category) {
      case '자기계발':
        return const Color(0xFFF2E6E1);
      case '운동':
        return const Color(0xFFDDEBE5);
      case '장소':
        return const Color(0xFFE8E4F4);
      case '쇼핑':
        return const Color(0xFFF7E5D9);
      default:
        return const Color(0xFFF1F1F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    unreadPosts.sort((a, b) => getCreatedAt(b).compareTo(getCreatedAt(a)));

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
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
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
                  ...unreadPosts.map((post) {
                    final String id = post['id'] ?? '';
                    final bool isRead = post['isRead'] ?? false;
                    final bool isFavorite = post['isFavorite'] ?? false;
                    final bool isPinned = post['isPinned'] ?? false;
                    final String category =
                        (post['category'] ?? '기타').toString();
                    final String dateText = formatDate(post['createdAt']);
                    final String title = getDisplayTitle(post);
                    final List<String> summaryLines = getSummaryLines(post);
                    final List<String> tags = getTags(post);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.post,
                            arguments: id,
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: getCategoryChipColor(category),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      category,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.charcoal,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    dateText,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textDisabled,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (isPinned) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.push_pin,
                                      size: 18,
                                      color: AppColors.peachDust,
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () async {
                                      await toggleReadStatus(id, isRead);
                                    },
                                    child: Icon(
                                      isRead
                                          ? Icons.check_circle
                                          : Icons.check_circle_outline,
                                      size: 22,
                                      color: isRead
                                          ? const Color(0xFF95DDB4)
                                          : AppColors.textDisabled,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () async {
                                      await toggleFavoriteStatus(
                                        id,
                                        isFavorite,
                                      );
                                    },
                                    child: Icon(
                                      isFavorite
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 22,
                                      color: isFavorite
                                          ? Colors.amber
                                          : AppColors.textDisabled,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_horiz,
                                      color: AppColors.textDisabled,
                                    ),
                                    onSelected: (value) async {
                                      if (value == 'pin') {
                                        await togglePinnedStatus(
                                          id,
                                          isPinned,
                                        );
                                      } else if (value == 'collection') {
                                        await moveToCollection(id);
                                      } else if (value == 'delete') {
                                        await showDeleteDialog(id);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'pin',
                                        child: Text(
                                          isPinned ? '고정 해제' : '홈에 고정',
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'collection',
                                        child: Text('컬렉션으로 이동'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('휴지통으로 이동'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  height: 1.4,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...summaryLines.map(
                                (line) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '• ',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      Expanded(
                                        child: Text(
                                          line,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            height: 1.6,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.charcoal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Divider(color: AppColors.divider),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: tags.map((tag) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF3F3F3),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            tag,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color:
                                                  AppColors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Row(
                                    children: [
                                      Text(
                                        '원본 보기',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color:
                                              AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward,
                                        size: 16,
                                        color:
                                            AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}