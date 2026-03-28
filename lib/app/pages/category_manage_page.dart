import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

class CategoryManagePage extends StatefulWidget {
  const CategoryManagePage({super.key});

  @override
  State<CategoryManagePage> createState() => _CategoryManagePageState();
}

class _CategoryManagePageState extends State<CategoryManagePage> {
  bool showEtcDetail = true;

  final List<Map<String, dynamic>> mainCategories = [
    {
      'name': '자기계발',
      'count': 12,
      'color': const Color(0xFFC2D6CF),
    },
    {
      'name': '운동',
      'count': 8,
      'color': const Color(0xFFD8B4FE),
    },
    {
      'name': '장소',
      'count': 5,
      'color': const Color(0xFFFBBF24),
    },
    {
      'name': '쇼핑',
      'count': 3,
      'color': const Color(0xFFF87171),
    },
  ];

  final List<Map<String, dynamic>> etcCategories = [
    {'name': '영화', 'count': 2},
    {'name': '음악', 'count': 1},
    {'name': '요리', 'count': 3},
  ];

  void handleEdit(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name 수정 기능은 다음 단계에서 연결하면 됩니다.')),
    );
  }

  void handleDelete(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name 삭제 기능은 다음 단계에서 연결하면 됩니다.')),
    );
  }

  void handlePromote(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name 을(를) 메인 카테고리로 올리는 기능은 다음 단계에서 연결하면 됩니다.')),
    );
  }

  void handleAddCategory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('카테고리 추가 기능은 다음 단계에서 연결하면 됩니다.')),
    );
  }

  Widget _buildCountChip(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMainCategoryRow({
    required String name,
    required int count,
    required Color dotColor,
    required bool isLast,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Row(
            children: [
              const Icon(
                Icons.drag_handle,
                color: AppColors.textSecondary,
                size: 30,
              ),
              const SizedBox(width: 12),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              _buildCountChip(count),
              const SizedBox(width: 18),
              InkWell(
                onTap: () => handleEdit(name),
                child: const Icon(
                  Icons.edit,
                  size: 24,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 18),
              InkWell(
                onTap: () => handleDelete(name),
                child: const Icon(
                  Icons.delete,
                  size: 24,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFD9D9D9),
          ),
      ],
    );
  }

  Widget _buildEtcCategoryRow({
    required String name,
    required int count,
    required bool isLast,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              _buildCountChip(count),
              const SizedBox(width: 18),
              InkWell(
                onTap: () => handlePromote(name),
                child: const Icon(
                  Icons.arrow_upward,
                  size: 24,
                  color: Color(0xFFF2B8B5),
                ),
              ),
              const SizedBox(width: 18),
              InkWell(
                onTap: () => handleEdit(name),
                child: const Icon(
                  Icons.edit,
                  size: 24,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFD9D9D9),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.charcoal,
        title: const Text(
          '카테고리 관리',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 6, bottom: 14),
            child: Text(
              '메인 카테고리',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: List.generate(mainCategories.length, (index) {
                final item = mainCategories[index];
                return _buildMainCategoryRow(
                  name: item['name'] as String,
                  count: item['count'] as int,
                  dotColor: item['color'] as Color,
                  isLast: index == mainCategories.length - 1,
                );
              }),
            ),
          ),

          const SizedBox(height: 36),

          const Padding(
            padding: EdgeInsets.only(left: 6, bottom: 14),
            child: Text(
              '기타 카테고리',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  onTap: () {
                    setState(() {
                      showEtcDetail = !showEtcDetail;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '기타',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.charcoal,
                            ),
                          ),
                        ),
                        Icon(
                          showEtcDetail
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 32,
                          color: AppColors.charcoal,
                        ),
                      ],
                    ),
                  ),
                ),

                if (showEtcDetail) ...[
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFD9D9D9),
                  ),
                  ...List.generate(etcCategories.length, (index) {
                    final item = etcCategories[index];
                    return _buildEtcCategoryRow(
                      name: item['name'] as String,
                      count: item['count'] as int,
                      isLast: index == etcCategories.length - 1,
                    );
                  }),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          OutlinedButton.icon(
            onPressed: handleAddCategory,
            icon: const Icon(
              Icons.add,
              size: 28,
              color: Color(0xFFF2B8B5),
            ),
            label: const Text(
              '카테고리 추가하기',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF2B8B5),
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.transparent,
              side: const BorderSide(
                color: Color(0xFFF2B8B5),
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ],
      ),
    );
  }
}