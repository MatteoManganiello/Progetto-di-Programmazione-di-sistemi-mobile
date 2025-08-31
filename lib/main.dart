import 'package:flutter/material.dart';
import 'start_screen.dart';
import 'home_page.dart';
import 'homepages/DailyGoal.dart';
import 'homepages/DailyCalo.dart';
import 'homepages/pagina_attivita_fisica.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CaloTracker',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF75C0B7)),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const WelcomePage(),
        'home': (_) => const HomeScreen(),
        DailyGoalPage.route: (_) => const DailyGoalPage(),
        '/daily-calo': (_) => const DailyCaloPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/attivita') {
          final args = settings.arguments as int? ?? 0;
          return MaterialPageRoute(
            builder: (_) => PaginaAttivitaFisica(kcalDaSmaltire: args),
          );
        }
        return null;
      },
      onUnknownRoute: (_) =>
          MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}
