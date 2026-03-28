import 'package:flutter/material.dart';
import '../theme/app_categories.dart';
import '../theme/app_colors.dart';

class CategoryTabs extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChange;

  const CategoryTabs({
    super.key,
    required this.value,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: SizedBox(
        height: 58,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: AppCategories.categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 4),
          itemBuilder: (context, index) {
            final category = AppCategories.categories[index];
            final selected = value == index;

            return GestureDetector(
              onTap: () => onChange(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? AppColors.peachDust : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (category == '즐겨찾기') ...[
                      Icon(
                        Icons.star,
                        size: 16,
                        color: selected
                            ? AppColors.charcoal
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? AppColors.charcoal
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}