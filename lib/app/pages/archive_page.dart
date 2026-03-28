import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../theme/app_categories.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/category_tabs.dart';
import '../widgets/post_list.dart';
import '../widgets/top_bar.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  int activeTab = 0;
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
            Expanded(
              child: PostList(
                category: AppCategories.categories[categoryTab],
                searchQuery: searchQuery,
                showArchived: true,
                isInArchive: true,
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