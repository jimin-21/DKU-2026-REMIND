import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

class PostDetailPage extends StatefulWidget {
  final String? postId;

  const PostDetailPage({super.key, this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();

  bool isLoading = true;
  bool isFavorite = false;
  bool isEditingSummary = false;
  bool isOriginalExpanded = false;

  Map<String, dynamic>? post;
  late TextEditingController summaryController;
  late TextEditingController memoController;

  @override
  void initState() {
    super.initState();
    summaryController = TextEditingController();
    memoController = TextEditingController();
    loadPost();
  }

  @override
  void dispose() {
    summaryController.dispose();
    memoController.dispose();
    super.dispose();
  }

  Future<void> loadPost() async {
    final id = widget.postId;

    if (id == null || id.isEmpty) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        post = null;
      });
      return;
    }

    final data = await _firestoreService.getPostById(id);

    if (!mounted) return;

    setState(() {
      post = data;
      isLoading = false;
      isFavorite = data?['isFavorite'] ?? false;
      summaryController.text = (data?['summary'] ?? '').toString();
      memoController.text = (data?['memo'] ?? '').toString();
    });
  }

  Future<void> toggleFavorite() async {
    if (post == null) return;

    final id = post!['id'].toString();
    final currentValue = post!['isFavorite'] ?? false;

    await _firestoreService.updateFavoriteStatus(id, !currentValue);
    await loadPost();
  }

  Future<void> markAsMastered() async {
    if (post == null) return;

    final id = post!['id'].toString();
    await _firestoreService.updateCollectedStatus(id, true);
    await loadPost();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('컬렉션으로 이동했습니다.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> saveSummary() async {
    if (post == null) return;

    final id = post!['id'].toString();
    await _firestoreService.updateSummary(id, summaryController.text.trim());

    if (!mounted) return;

    setState(() {
      isEditingSummary = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI 요약을 저장했습니다.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    await loadPost();
  }

  Future<void> saveMemo() async {
    if (post == null) return;

    final id = post!['id'].toString();
    await _firestoreService.updateMemo(id, memoController.text.trim());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('메모를 저장했습니다.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    await loadPost();
  }

  Future<void> openOriginalLink() async {
    if (post == null) return;

    final url = (post!['url'] ?? '').toString().trim();
    if (url.isEmpty) return;

    final Uri uri = Uri.parse(url);

    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('링크를 열 수 없습니다.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  DateTime? parseCreatedAt(dynamic createdAt) {
    try {
      if (createdAt == null) return null;

      if (createdAt is DateTime) {
        return createdAt;
      }

      return createdAt.toDate();
    } catch (_) {
      return null;
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

  String getMasterBadgeText() {
    if (post == null) return '🏆 마스터 완료';

    final createdAt = parseCreatedAt(post!['createdAt']);

    if (createdAt == null) {
      return '🏆 마스터 완료';
    }

    final completedAt = createdAt.add(const Duration(days: 5));
    final completedText =
        '${completedAt.year}.${completedAt.month.toString().padLeft(2, '0')}.${completedAt.day.toString().padLeft(2, '0')}';

    return '🏆 $completedText 마스터 완료';
  }

  Color getCategoryChipColor(String category) {
    switch (category) {
      case '자기계발':
        return const Color.fromRGBO(200, 182, 255, 0.2);
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

  List<String> getSummaryList(String summary) {
    final lines = summary
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (lines.isNotEmpty) return lines;
    return ['요약 정보가 없습니다.'];
  }

  Widget buildMasterAction() {
    final bool isCollected = post?['isCollected'] ?? false;

    if (isCollected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.butterYellow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE0D38A),
          ),
        ),
        child: Text(
          getMasterBadgeText(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: markAsMastered,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.butterYellow,
        foregroundColor: AppColors.charcoal,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(
            color: Color(0xFFE0D38A),
          ),
        ),
      ),
      child: const Text(
        '🏆 마스터 하기',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (post == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('게시물을 찾을 수 없습니다.'),
        ),
      );
    }

    final category = (post!['category'] ?? '기타').toString();
    final title = ((post!['title'] ?? '').toString().trim().isNotEmpty)
        ? (post!['title'] ?? '').toString()
        : (post!['url'] ?? '제목 없음').toString();
    final dateText = formatDate(post!['createdAt']);
    final summaryText = summaryController.text.trim();
    final summaryList = getSummaryList(summaryText);
    final originalText =
        ((post!['originalText'] ?? '').toString().trim().isNotEmpty)
            ? (post!['originalText'] ?? '').toString()
            : ((post!['summary'] ?? '').toString().trim().isNotEmpty
                ? (post!['summary'] ?? '').toString()
                : (post!['url'] ?? '').toString());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.charcoal,
        title: const Text(
          '상세 요약',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: toggleFavorite,
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? AppColors.star : AppColors.charcoal,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: getCategoryChipColor(category),
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                  border: Border.all(
                    color: const Color.fromRGBO(176, 159, 255, 0.35),
                  ),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                dateText,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              buildMasterAction(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 28,
              color: AppColors.charcoal,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  (post!['url'] ?? '').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: openOriginalLink,
                icon: const Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                label: const Text(
                  '원본 링크 이동',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '✨ AI 요약',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          if (isEditingSummary) {
                            await saveSummary();
                          } else {
                            setState(() {
                              isEditingSummary = true;
                            });
                          }
                        },
                        icon: Icon(
                          isEditingSummary ? Icons.check : Icons.edit,
                          size: 18,
                          color: isEditingSummary
                              ? AppColors.peachDustDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (!isEditingSummary)
                    Column(
                      children: summaryList
                          .map(
                            (line) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• '),
                                  Expanded(
                                    child: Text(
                                      line,
                                      style: const TextStyle(height: 1.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    )
                  else
                    TextField(
                      controller: summaryController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        hintText: '엔터로 항목을 구분하세요',
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '📄 원본 글',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    isOriginalExpanded = !isOriginalExpanded;
                  });
                },
                icon: Icon(
                  isOriginalExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                ),
                label: Text(isOriginalExpanded ? '접기' : '전체보기'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              originalText,
              maxLines: isOriginalExpanded ? null : 4,
              overflow: isOriginalExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '📝 내 메모',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              TextButton(
                onPressed: saveMemo,
                child: const Text('저장'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color.fromRGBO(0, 0, 0, 0.02),
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.divider),
            ),
            child: TextField(
              controller: memoController,
              minLines: 5,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: '여기에 나만의 생각이나 적용할 점을 기록해 보세요',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}