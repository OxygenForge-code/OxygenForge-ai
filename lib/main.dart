import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OxygenForgeApp());
}

class OxygenForgeApp extends StatelessWidget {
  const OxygenForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OxygenForge AI',
      debugShowCheckedModeBanner: false,
      theme: OxygenForgeTheme.build(),
      home: const HomeScreen(),
    );
  }
}
