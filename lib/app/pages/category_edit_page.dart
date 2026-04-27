import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class EditableCategory {
  String id;
  String name;
  int count;

  EditableCategory({
    required this.id,
    required this.name,
    required this.count,
  });
}

class CategoryEditPage extends StatefulWidget {
  const CategoryEditPage({super.key});

  @override
  State<CategoryEditPage> createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends State<CategoryEditPage> {
  List<EditableCategory> categories = [
    EditableCategory(id: '1', name: '자기계발', count: 12),
    EditableCategory(id: '2', name: '운동', count: 8),
    EditableCategory(id: '3', name: '장소', count: 5),
    EditableCategory(id: '4', name: '쇼핑', count: 3),
    EditableCategory(id: '5', name: '기타', count: 15),
  ];

  String? editingId;
  final TextEditingController editingController = TextEditingController();

  @override
  void dispose() {
    editingController.dispose();
    super.dispose();
  }

  void handleNameClick(EditableCategory category) {
    setState(() {
      editingId = category.id;
      editingController.text = category.name;
    });
  }

  void handleNameChange(String id) {
    setState(() {
      categories = categories.map((cat) {
        if (cat.id == id) {
          return EditableCategory(
            id: cat.id,
            name: editingController.text,
            count: cat.count,
          );
        }
        return cat;
      }).toList();

      editingId = null;
      editingController.clear();
    });
  }

  void handleDelete(String id) {
    setState(() {
      categories.removeWhere((cat) => cat.id == id);
    });
  }

  void handleAddCategory() {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      categories.add(
        EditableCategory(id: newId, name: '새 카테고리', count: 0),
      );
      editingId = newId;
      editingController.text = '새 카테고리';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.charcoal,
        title: const Text(
          '카테고리 편집',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: categories.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final category = categories[index];
                return Container(
                  color: AppColors.surface,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => handleDelete(category.id),
                        icon: const Icon(Icons.remove, color: AppColors.error),
                      ),
                      Expanded(
                        child: editingId == category.id
                            ? TextField(
                                controller: editingController,
                                autofocus: true,
                                onSubmitted: (_) =>
                                    handleNameChange(category.id),
                                onEditingComplete: () =>
                                    handleNameChange(category.id),
                              )
                            : GestureDetector(
                                onTap: () => handleNameClick(category),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.charcoal,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${category.count}개',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                      const Icon(
                        Icons.drag_indicator,
                        color: AppColors.textDisabled,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: handleAddCategory,
              icon: const Icon(Icons.add),
              label: const Text('새 카테고리 추가'),
            ),
          ),
        ],
      ),
    );
  }
}