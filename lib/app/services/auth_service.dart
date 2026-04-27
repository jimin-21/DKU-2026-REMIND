import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 회원가입
  Future<User?> signUp(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  // 로그인
  Future<User?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  // 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 현재 사용자
  User? get currentUser => _auth.currentUser;
}