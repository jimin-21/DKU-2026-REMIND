import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/routes/app_routes.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ReSeeApp());
}

class ReSeeApp extends StatelessWidget {
  const ReSeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.authGate,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}