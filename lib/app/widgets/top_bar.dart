import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';

class TopBar extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChange;

  const TopBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              );
            },
            child: Image.asset(
              'assets/images/resee_wordmark_black.png',
              width: 95,
              height: 42,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.searchBar),
                boxShadow: AppShadows.searchBar,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: AppColors.textDisabled,
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextFormField(
                      initialValue: searchQuery,
                      onChanged: onSearchChange,
                      decoration: const InputDecoration(
                        hintText: '검색하기...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _CircleIconButton(
            backgroundColor: AppColors.peachDust,
            icon: Icons.add,
            iconColor: const Color(0xFF212529),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.add);
            },
          ),
          const SizedBox(width: 8),
          _CircleIconButton(
            backgroundColor: AppColors.surface,
            icon: Icons.person,
            iconColor: Colors.black87,
            boxShadow: AppShadows.searchBar,
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.my);
            },
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final List<BoxShadow>? boxShadow;

  const _CircleIconButton({
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: boxShadow,
      ),
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          color: iconColor,
          size: 23,
        ),
      ),
    );
  }
}