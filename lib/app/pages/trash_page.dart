import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> trashPosts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTrashPosts();
  }

  Future<void> loadTrashPosts() async {
    final data = await _firestoreService.getTrashPosts();

    if (!mounted) return;

    setState(() {
      trashPosts = data;
      isLoading = false;
    });
  }

  Future<void> restorePost(String id) async {
    await _firestoreService.restoreFromTrash(id);
    await loadTrashPosts();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('복구되었습니다.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> deletePostPermanently(String id) async {
    await _firestoreService.deletePostPermanently(id);
    await loadTrashPosts();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('완전히 삭제되었습니다.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> showRestoreDialog(String id) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('복구'),
          content: const Text('이 링크를 복구할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('복구'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await restorePost(id);
    }
  }

  Future<void> showPermanentDeleteDialog(String id) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('완전 삭제'),
          content: const Text('이 링크를 완전히 삭제할까요?\n삭제 후에는 되돌릴 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await deletePostPermanently(id);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('휴지통'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.charcoal,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : trashPosts.isEmpty
              ? const Center(
                  child: Text(
                    '휴지통이 비어 있습니다.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: trashPosts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final post = trashPosts[index];
                    final String id = post['id'] ?? '';
                    final String category =
                        (post['category'] ?? '기타').toString();
                    final String dateText = formatDate(post['createdAt']);
                    final String title = getDisplayTitle(post);
                    final List<String> summaryLines = getSummaryLines(post);
                    final List<String> tags = getTags(post);

                    return Container(
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
                              const SizedBox(width: 8),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_horiz,
                                  color: AppColors.textDisabled,
                                ),
                                onSelected: (value) async {
                                  if (value == 'restore') {
                                    await showRestoreDialog(id);
                                  } else if (value == 'delete') {
                                    await showPermanentDeleteDialog(id);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'restore',
                                    child: Text('복구'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('완전삭제'),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        tag,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      await showRestoreDialog(id);
                                    },
                                    child: const Text('복구'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await showPermanentDeleteDialog(id);
                                    },
                                    child: const Text('완전삭제'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}