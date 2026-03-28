import 'package:flutter/material.dart';
import '../data/mock_posts.dart';
import '../theme/app_colors.dart';
import '../theme/app_formatters.dart';
import '../theme/app_radii.dart';

class PostDetailPage extends StatefulWidget {
  final String? postId;

  const PostDetailPage({super.key, this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  bool isFavorite = false;
  bool isEditing = false;
  bool isOriginalExpanded = false;
  late TextEditingController summaryController;
  late TextEditingController memoController;

  @override
  void initState() {
    super.initState();
    final post = postDetails[widget.postId ?? ''];
    isFavorite = post?.isFavorite ?? false;
    summaryController =
        TextEditingController(text: post?.summaryList.join('\n') ?? '');
    memoController = TextEditingController(text: post?.memo ?? '');
  }

  @override
  void dispose() {
    summaryController.dispose();
    memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = postDetails[widget.postId ?? ''];

    if (post == null) {
      return const Scaffold(
        body: Center(
          child: Text('게시물을 찾을 수 없습니다.'),
        ),
      );
    }

    final currentSummaryList = summaryController.text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

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
            onPressed: () {
              setState(() {
                isFavorite = !isFavorite;
              });
            },
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
                  color: const Color.fromRGBO(200, 182, 255, 0.2),
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                  border: Border.all(
                    color: const Color.fromRGBO(176, 159, 255, 0.35),
                  ),
                ),
                child: Text(
                  post.category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatDate(post.date),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (post.isMastered && post.masteredDate != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.butterYellow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE0D38A),
                    ),
                  ),
                  child: Text(
                    '🏆 ${formatDate(post.masteredDate!)} 마스터 완료',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            post.title,
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
                  post.source ?? '',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  post.type == 'photo' ? '🖼️ 원본 사진 보기' : '🔗 원본 링크 가기',
                  style: const TextStyle(
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
                        onPressed: () {
                          setState(() {
                            isEditing = !isEditing;
                          });
                        },
                        icon: Icon(
                          isEditing ? Icons.check : Icons.edit,
                          size: 18,
                          color: isEditing
                              ? AppColors.peachDustDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (!isEditing)
                    Column(
                      children: currentSummaryList
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
                      maxLines: currentSummaryList.length < 3
                          ? 3
                          : currentSummaryList.length,
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
              post.originalText,
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
          const Text(
            '📝 내 메모',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.charcoal,
            ),
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