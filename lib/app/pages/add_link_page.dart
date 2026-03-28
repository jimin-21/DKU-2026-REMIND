import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

class AddLinkPage extends StatefulWidget {
  const AddLinkPage({super.key});

  @override
  State<AddLinkPage> createState() => _AddLinkPageState();
}

class _AddLinkPageState extends State<AddLinkPage> {
  final TextEditingController urlController = TextEditingController();

  bool isLoading = false;
  bool isLinkMode = true;
  String? uploadedImageName;

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }

  Future<void> handleSubmit() async {
    final isDisabled =
        (isLinkMode && urlController.text.trim().isEmpty) ||
        (!isLinkMode && uploadedImageName == null);

    if (isDisabled) return;

    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    Navigator.pushNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled =
        (isLinkMode && urlController.text.trim().isEmpty) ||
        (!isLinkMode && uploadedImageName == null);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.charcoal,
        title: const Text(
          '콘텐츠 추가',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(
                color: AppColors.peachDustLight,
                width: 2,
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 52,
                  color: AppColors.peachDust,
                ),
                SizedBox(height: 18),
                Text(
                  '링크와 스크린샷을 분석하여\n핵심만 요약해 드려요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: AppColors.charcoal,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '인스타그램, 블로그, 뉴스 등 링크와 이미지의\n핵심을 3줄로 정리합니다',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      isLinkMode = true;
                    });
                  },
                  icon: const Icon(Icons.link),
                  label: const Text('링크 입력'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor:
                        isLinkMode ? const Color(0xFFF3EEFF) : Colors.white,
                    foregroundColor: const Color(0xFF6E56CF),
                    side: const BorderSide(color: Color(0xFF6E56CF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      isLinkMode = false;
                    });
                  },
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('사진 업로드'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor:
                        !isLinkMode ? const Color(0xFFF3EEFF) : Colors.white,
                    foregroundColor: const Color(0xFF6E56CF),
                    side: const BorderSide(color: Color(0xFF6E56CF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          if (isLinkMode) ...[
            const Text(
              '링크 주소',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              onChanged: (_) {
                setState(() {});
              },
              minLines: 3,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'https://www.example.com/post/...',
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.all(20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Color(0xFF6E56CF),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Color(0xFF6E56CF),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Color(0xFF6E56CF),
                    width: 2,
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF6E56CF),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.image_outlined,
                    size: 44,
                    color: Color(0xFF6E56CF),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '이미지를 업로드하세요',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '스크린샷이나 사진을 올리면\n핵심 내용을 분석해 드립니다',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        uploadedImageName = 'sample_image.png';
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6E56CF),
                      side: const BorderSide(color: Color(0xFF6E56CF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('파일 선택'),
                  ),
                  if (uploadedImageName != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      '✓ $uploadedImageName 업로드됨',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: isDisabled || isLoading ? null : handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDisabled ? Colors.grey.shade300 : AppColors.peachDust,
              foregroundColor:
                  isDisabled ? Colors.grey.shade600 : AppColors.charcoal,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              isLoading ? '요약 생성 중...' : 'AI 요약 시작하기',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}