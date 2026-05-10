import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final AuthService _authService = AuthService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordCheckController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscurePasswordCheck = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    passwordCheckController.dispose();
    super.dispose();
  }

  Future<void> handleSignup() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final passwordCheck = passwordCheckController.text.trim();

    if (email.isEmpty || password.isEmpty || passwordCheck.isEmpty) {
      showMessage('모든 항목을 입력해주세요.');
      return;
    }

    if (password.length < 6) {
      showMessage('비밀번호는 6자리 이상이어야 합니다.');
      return;
    }

    if (password != passwordCheck) {
      showMessage('비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _authService.signUp(email, password);

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.authGate,
        (route) => false,
      );
    } catch (e) {
      showMessage('회원가입에 실패했습니다. 이미 사용 중인 이메일일 수 있습니다.');
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: AppColors.textDisabled,
              fontSize: 14,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
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
                color: AppColors.peachDust,
                width: 1.6,
              ),
            ),
          ),
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
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.charcoal,
        title: const Text(
          '회원가입',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          children: [
            const Text(
              'ReSee 시작하기',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '계정을 만들고 나만의 저장 기록을 관리하세요.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.card),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  buildTextField(
                    label: '이메일',
                    controller: emailController,
                    hintText: 'example@email.com',
                  ),
                  const SizedBox(height: 22),
                  buildTextField(
                    label: '비밀번호',
                    controller: passwordController,
                    hintText: '6자리 이상 입력',
                    obscureText: obscurePassword,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  buildTextField(
                    label: '비밀번호 확인',
                    controller: passwordCheckController,
                    hintText: '비밀번호 다시 입력',
                    obscureText: obscurePasswordCheck,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePasswordCheck = !obscurePasswordCheck;
                        });
                      },
                      icon: Icon(
                        obscurePasswordCheck
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : handleSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.peachDust,
                        foregroundColor: AppColors.charcoal,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: Text(
                        isLoading ? '가입 중...' : '회원가입',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      '이미 계정이 있나요? 로그인',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}