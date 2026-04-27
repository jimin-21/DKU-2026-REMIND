import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final TextEditingController nicknameController =
      TextEditingController(text: '사용자님');
  final TextEditingController emailController =
      TextEditingController(text: 'user@example.com');
  final TextEditingController passwordController =
      TextEditingController(text: 'password123');

  @override
  void dispose() {
    nicknameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void handleSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('계정 정보가 저장되었습니다.'),
      ),
    );
  }

  void handleLogout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('로그아웃 기능은 나중에 연결할 수 있어요.'),
      ),
    );
  }

  void handleWithdraw() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('회원탈퇴'),
          content: const Text('정말 탈퇴하시겠어요? 이 기능은 아직 UI만 구현된 상태입니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('회원탈퇴 기능은 나중에 연결할 수 있어요.'),
                  ),
                );
              },
              child: const Text(
                '탈퇴',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: AppColors.charcoal,
        ),
      ),
    );
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.button),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.button),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.button),
                borderSide: const BorderSide(
                  color: AppColors.paleLavenderDark,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
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
          '계정 설정',
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
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          buildSectionTitle('프로필'),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0FA),
              borderRadius: BorderRadius.circular(AppRadii.card),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.04),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.peachDust,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'MY',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    '프로필 사진 기능은\n나중에 로그인 기능과 함께 연결할 수 있어요.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          buildSectionTitle('기본 정보'),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.04),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                buildTextField(
                  label: '닉네임',
                  controller: nicknameController,
                ),
                buildTextField(
                  label: '이메일',
                  controller: emailController,
                ),
                buildTextField(
                  label: '비밀번호',
                  controller: passwordController,
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.peachDust,
                      foregroundColor: AppColors.charcoal,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      '저장하기',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          buildSectionTitle('계정 관리'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.04),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text(
                    '로그아웃',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: handleLogout,
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text(
                    '회원탈퇴',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.error,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: handleWithdraw,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}