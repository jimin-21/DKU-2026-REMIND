import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

class CategoryManagePage extends StatefulWidget {
  const CategoryManagePage({super.key});

  @override
  State<CategoryManagePage> createState() => _CategoryManagePageState();
}

class _CategoryManagePageState extends State<CategoryManagePage> {
  final FirestoreService _firestoreService = FirestoreService();

  bool showEtcDetail = true;
  bool isLoading = true;

  List<Map<String, dynamic>> mainCategories = [];
  List<Map<String, dynamic>> etcCategories = [];

  final List<int> categoryColors = const [
    0xFFC2D6CF,
    0xFFD8B4FE,
    0xFFFBBF24,
    0xFFF87171,
    0xFF9ED0F6,
    0xFFF2B8B5,
    0xFFA7E3D3,
  ];

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Color _pickNextColor() {
    return Color(categoryColors[mainCategories.length % categoryColors.length]);
  }

  Future<void> loadCategories() async {
    final data = await _firestoreService.getCategories();

    if (!mounted) return;

    final mains = data.where((e) => (e['isMain'] ?? false) == true).toList()
      ..sort((a, b) => ((a['sortOrder'] ?? 0) as int)
          .compareTo((b['sortOrder'] ?? 0) as int));

    final etcs = data.where((e) => (e['isMain'] ?? false) == false).toList()
      ..sort((a, b) => ((a['sortOrder'] ?? 0) as int)
          .compareTo((b['sortOrder'] ?? 0) as int));

    setState(() {
      mainCategories = mains;
      etcCategories = etcs;
      isLoading = false;
    });
  }

  Future<void> _showEditDialog({
    required String currentName,
    required Function(String newName) onSave,
  }) async {
    final controller = TextEditingController(text: currentName);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('카테고리 이름 수정'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '카테고리 이름 입력',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      await onSave(result);
    }
  }

  Future<void> _showAddDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('카테고리 추가'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '새 카테고리 이름 입력',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      await _firestoreService.addCategory(
        name: result,
        isMain: false,
        color: categoryColors[(mainCategories.length + etcCategories.length) %
            categoryColors.length],
      );

      await loadCategories();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$result 카테고리를 추가했습니다.')),
      );
    }
  }

  Future<void> _showDeleteDialog({
    required String name,
    required Future<void> Function() onDelete,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('카테고리 삭제'),
          content: Text('$name 카테고리를 삭제할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                '삭제',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await onDelete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name 카테고리를 삭제했습니다.')),
      );
    }
  }

  Future<void> _editMainCategory(int index) async {
    final item = mainCategories[index];
    final currentName = (item['name'] ?? '').toString();

    await _showEditDialog(
      currentName: currentName,
      onSave: (newName) async {
        await _firestoreService.updateCategoryName(
          id: item['id'].toString(),
          name: newName,
        );
        await loadCategories();
      },
    );
  }

  Future<void> _editEtcCategory(int index) async {
    final item = etcCategories[index];
    final currentName = (item['name'] ?? '').toString();

    await _showEditDialog(
      currentName: currentName,
      onSave: (newName) async {
        await _firestoreService.updateCategoryName(
          id: item['id'].toString(),
          name: newName,
        );
        await loadCategories();
      },
    );
  }

  Future<void> _deleteMainCategory(int index) async {
    final item = mainCategories[index];
    final String name = (item['name'] ?? '').toString();

    await _showDeleteDialog(
      name: name,
      onDelete: () async {
        await _firestoreService.demoteCategoryToEtc(
          id: item['id'].toString(),
          sortOrder: 100 + etcCategories.length,
        );
        await loadCategories();
      },
    );
  }

  Future<void> _promoteToMain(int index) async {
    if (mainCategories.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메인 카테고리는 최대 6개까지 가능합니다.')),
      );
      return;
    }

    final item = etcCategories[index];

    await _firestoreService.promoteCategoryToMain(
      id: item['id'].toString(),
      sortOrder: mainCategories.length,
    );

    await loadCategories();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item['name']} 카테고리를 메인으로 올렸습니다.')),
    );
  }

  Future<void> _moveMainUp(int index) async {
    if (index == 0) return;

    final updated = [...mainCategories];
    final item = updated.removeAt(index);
    updated.insert(index - 1, item);

    setState(() {
      mainCategories = updated;
    });

    await _firestoreService.reorderCategories(mainCategories);
    await loadCategories();
  }

  Future<void> _moveMainDown(int index) async {
    if (index == mainCategories.length - 1) return;

    final updated = [...mainCategories];
    final item = updated.removeAt(index);
    updated.insert(index + 1, item);

    setState(() {
      mainCategories = updated;
    });

    await _firestoreService.reorderCategories(mainCategories);
    await loadCategories();
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

  Widget _buildCategoryName({
    required String name,
    required String originalName,
    required bool renamed,
  }) {
    if (!renamed) {
      return Text(
        name,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.charcoal,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          originalName,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textDisabled,
          ),
        ),
      ],
    );
  }

  Widget _buildMainCategoryRow({
    required int index,
    required Map<String, dynamic> item,
    required bool isLast,
  }) {
    final String name = (item['name'] ?? '').toString();
    final String originalName = (item['originalName'] ?? '').toString();
    final int count = (item['count'] ?? 0) as int;
    final int colorValue = (item['color'] ?? 0xFFC2D6CF) as int;
    final bool renamed = name.trim() != originalName.trim();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Row(
            children: [
              Column(
                children: [
                  InkWell(
                    onTap: index == 0 ? null : () => _moveMainUp(index),
                    child: Icon(
                      Icons.keyboard_arrow_up,
                      size: 22,
                      color: index == 0
                          ? AppColors.divider
                          : AppColors.textSecondary,
                    ),
                  ),
                  InkWell(
                    onTap: index == mainCategories.length - 1
                        ? null
                        : () => _moveMainDown(index),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 22,
                      color: index == mainCategories.length - 1
                          ? AppColors.divider
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(colorValue),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _buildCategoryName(
                  name: name,
                  originalName: originalName,
                  renamed: renamed,
                ),
              ),
              _buildCountChip(count),
              const SizedBox(width: 18),
              InkWell(
                onTap: () => _editMainCategory(index),
                child: const Icon(
                  Icons.edit,
                  size: 24,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 18),
              InkWell(
                onTap: () => _deleteMainCategory(index),
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
    required int index,
    required Map<String, dynamic> item,
    required bool isLast,
  }) {
    final String name = (item['name'] ?? '').toString();
    final String originalName = (item['originalName'] ?? '').toString();
    final int count = (item['count'] ?? 0) as int;
    final bool renamed = name.trim() != originalName.trim();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Row(
            children: [
              Expanded(
                child: _buildCategoryName(
                  name: name,
                  originalName: originalName,
                  renamed: renamed,
                ),
              ),
              _buildCountChip(count),
              const SizedBox(width: 18),
              InkWell(
                onTap: () => _promoteToMain(index),
                child: const Icon(
                  Icons.arrow_upward,
                  size: 24,
                  color: Color(0xFFF2B8B5),
                ),
              ),
              const SizedBox(width: 18),
              InkWell(
                onTap: () => _editEtcCategory(index),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                        index: index,
                        item: item,
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
                        if (etcCategories.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              '기타 카테고리가 없습니다.',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        else
                          ...List.generate(etcCategories.length, (index) {
                            final item = etcCategories[index];
                            return _buildEtcCategoryRow(
                              index: index,
                              item: item,
                              isLast: index == etcCategories.length - 1,
                            );
                          }),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _showAddDialog,
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