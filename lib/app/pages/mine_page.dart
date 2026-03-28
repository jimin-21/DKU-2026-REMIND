import 'package:flutter/material.dart';
import '../data/mock_posts.dart';
import '../routes/app_routes.dart';
import '../theme/app_categories.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/category_tabs.dart';
import '../widgets/post_list.dart';
import '../widgets/top_bar.dart';

class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  int activeTab = 2;
  int categoryTab = 0;
  String searchQuery = '';

  void handleTabChange(int tab) {
    setState(() {
      activeTab = tab;
    });

    if (tab == 0) {
      Navigator.pushNamed(context, AppRoutes.archive);
    } else if (tab == 1) {
      Navigator.pushNamed(context, AppRoutes.home);
    } else if (tab == 2) {
      Navigator.pushNamed(context, AppRoutes.mine);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              searchQuery: searchQuery,
              onSearchChange: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            CategoryTabs(
              value: categoryTab,
              onChange: (newValue) {
                setState(() {
                  categoryTab = newValue;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.peachDustLight,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(255, 181, 167, 0.4),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  '이번 주 나만의 컬렉션이 ${minePosts.length}개 쌓였어요',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.charcoal,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    height: 1.8,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PostList(
                category: AppCategories.categories[categoryTab],
                searchQuery: searchQuery,
                showArchived: false,
                isInArchive: false,
                isInMine: true,
                showHeader: true,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(
        activeTab: activeTab,
        onTabChange: handleTabChange,
      ),
    );
  }
}