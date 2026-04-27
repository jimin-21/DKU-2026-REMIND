import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../pages/archive_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../services/analysis_service.dart';

class AddLinkPage extends StatefulWidget {
  const AddLinkPage({super.key});

  @override
  State<AddLinkPage> createState() => _AddLinkPageState();
}

class _AddLinkPageState extends State<AddLinkPage> {
  final TextEditingController urlController = TextEditingController();
  final AnalysisService _analysisService = AnalysisService();

  bool isLoading = false;
  bool isLinkMode = true;

  List<Uint8List> selectedImageBytesList = [];
  List<String> selectedImageFileNames = [];

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }

  Future<void> handleSubmit() async {
    final isDisabled =
        (isLinkMode && urlController.text.trim().isEmpty) ||
        (!isLinkMode && selectedImageBytesList.isEmpty);

    if (isDisabled || isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      if (isLinkMode) {
        final success = await _analysisService.analyzeUrl(
          urlController.text.trim(),
        );

        if (!success) {
          throw Exception('AI 분석 실패');
        }
      } else {
        final success = await _analysisService.analyzeImageFiles(
          selectedImageBytesList,
          selectedImageFileNames,
        );

        if (!success) {
          throw Exception('이미지 분석 실패');
        }
      }

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('저장되었습니다.'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const ArchivePage(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 중 오류가 발생했습니다. $e'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();

    if (images.isEmpty) return;

    final bytesList = <Uint8List>[];
    final fileNames = <String>[];

    for (final image in images) {
      final bytes = await image.readAsBytes();
      bytesList.add(bytes);
      fileNames.add(image.name);
    }

    setState(() {
      selectedImageBytesList = bytesList;
      selectedImageFileNames = fileNames;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled =
        (isLinkMode && urlController.text.trim().isEmpty) ||
        (!isLinkMode && selectedImageBytesList.isEmpty);

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
                  '링크와 스크린샷을 분석하여\n핵심만 자동으로 저장해 드려요!',
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
                  '제목, 요약, 태그, 카테고리를\nAI가 자동으로 정리합니다',
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
                  onPressed: isLoading
                      ? null
                      : () {
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
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
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
              enabled: !isLoading,
              onChanged: (_) {
                setState(() {});
              },
              minLines: 3,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'https://www.example.com/post/...',
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.all(20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
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
                    '여러 장의 이미지를 함께 분석해 제목, 요약, 태그, 카테고리를 자동으로 저장합니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: isLoading ? null : pickImages,
                    child: const Text('파일 선택'),
                  ),
                  if (selectedImageFileNames.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      '✓ ${selectedImageFileNames.length}장 선택됨',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...selectedImageFileNames.map(
                      (name) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
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
              isLoading ? 'AI가 분석 중...' : 'AI 요약 시작하기',
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