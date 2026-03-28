import 'package:flutter/material.dart';
import 'app/routes/app_routes.dart';

void main() {
  runApp(const ReSeeApp());
}

class ReSeeApp extends StatelessWidget {
  const ReSeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}