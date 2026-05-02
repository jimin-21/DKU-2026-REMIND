import 'package:flutter/material.dart';
import '../pages/account_settings_page.dart';
import '../pages/add_link_page.dart';
import '../pages/archive_page.dart';
import '../pages/auth_gate_page.dart';
import '../pages/category_manage_page.dart';
import '../pages/collection_page.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../pages/my_page.dart';
import '../pages/pinned_page.dart';
import '../pages/post_detail_page.dart';
import '../pages/signup_page.dart';
import '../pages/trash_page.dart';
import '../pages/unread_page.dart';

class AppRoutes {
  static const String authGate = '/auth-gate';
  static const String login = '/login';
  static const String signup = '/signup';

  static const String home = '/';
  static const String archive = '/archive';
  static const String add = '/add';
  static const String my = '/my';
  static const String categoryManage = '/category-manage';
  static const String unread = '/unread';
  static const String post = '/post';
  static const String accountSettings = '/account-settings';
  static const String trash = '/trash';
  static const String collection = '/collection';
  static const String pinned = '/pinned';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case authGate:
        return MaterialPageRoute(builder: (_) => const AuthGatePage());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case signup:
        return MaterialPageRoute(builder: (_) => const SignupPage());

      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());

      case archive:
        return MaterialPageRoute(builder: (_) => const ArchivePage());

      case add:
        return MaterialPageRoute(builder: (_) => const AddLinkPage());

      case my:
        return MaterialPageRoute(builder: (_) => const MyPage());

      case categoryManage:
        return MaterialPageRoute(builder: (_) => const CategoryManagePage());

      case unread:
        return MaterialPageRoute(builder: (_) => const UnreadPage());

      case trash:
        return MaterialPageRoute(builder: (_) => const TrashPage());

      case post:
        final postId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => PostDetailPage(postId: postId),
        );

      case accountSettings:
        return MaterialPageRoute(
          builder: (_) => const AccountSettingsPage(),
        );

      case collection:
        return MaterialPageRoute(
          builder: (_) => const CollectionPage(),
        );

      case pinned:
        return MaterialPageRoute(
          builder: (_) => const PinnedPage(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('페이지를 찾을 수 없습니다.'),
            ),
          ),
        );
    }
  }
}