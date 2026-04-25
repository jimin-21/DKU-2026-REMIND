import 'package:flutter/material.dart';
import '../theme/app_categories.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

class CategoryTabs extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChange;

  const CategoryTabs({
    super.key,
    required this.value,
    required this.onChange,
  });

  @override
  State<CategoryTabs> createState() => _CategoryTabsState();
}

class _CategoryTabsState extends State<CategoryTabs> {
  final FirestoreService _firestoreService = FirestoreService();

  List<String> tabLabels = [
    ...AppCategories.fixedTabs,
    AppCategories.etc,
  ];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTabs();
  }

  Future<void> loadTabs() async {
    final categories = await _firestoreService.getCategories();

    if (!mounted) return;

    final mainCategoryNames = categories
        .where((e) => (e['isMain'] ?? false) == true)
        .map((e) => (e['name'] ?? '').toString().trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    setState(() {
      tabLabels = [
        ...AppCategories.fixedTabs,
        ...mainCategoryNames,
        AppCategories.etc,
      ];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 52,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: tabLabels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 24),
        itemBuilder: (context, index) {
          final isSelected = widget.value == index;
          final label = tabLabels[index];

          return GestureDetector(
            onTap: () => widget.onChange(index),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (label == AppCategories.favorite)
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 10),
                Container(
                  width: 68,
                  height: 3,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.peachDust
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}