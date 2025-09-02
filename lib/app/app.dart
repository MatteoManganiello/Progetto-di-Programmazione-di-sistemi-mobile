import 'package:flutter/material.dart';
import 'router.dart'; // for AppRouter
import 'start_screen.dart'; // your StartScreen (stays in /app)

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fit & Food',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2DB8FD),
        useMaterial3: true,
      ),
      // Avoid circular imports: start directly on StartScreen
      home: const StartScreen(),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
