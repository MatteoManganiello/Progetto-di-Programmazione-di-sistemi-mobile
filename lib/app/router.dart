import 'package:flutter/material.dart';

import '../features/calories/ui/calories_home_page.dart';
import '../features/calories/ui/daily_calo_page.dart';
import '../features/calories/ui/meal_suggestions_page.dart';
import '../features/calories/ui/weekly_goal_page.dart';
import '../features/calories/ui/activities_page.dart';

abstract class AppRoutes {
  static const home = '/home';
  static const dailyCalo = '/daily-calo';
  static const mealSuggestions = '/meal-suggestions';
  static const weeklyGoal = '/weekly-goal';
  static const attivita = '/attivita';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return _material(const CaloriesHomePage());

      case AppRoutes.dailyCalo:
        return _material(const DailyCaloPage());

      case AppRoutes.mealSuggestions:
        return _material(const MealSuggestionsPage());

      case AppRoutes.weeklyGoal:
        return _material(const WeeklyGoalPage());

      case AppRoutes.attivita:
        final arg = settings.arguments;
        final kcal = (arg is int) ? arg : 0;
        return _material(ActivitiesPage(kcalDaSmaltire: kcal));

      default:
        return _material(const CaloriesHomePage());
    }
  }

  static MaterialPageRoute _material(Widget child) =>
      MaterialPageRoute(builder: (_) => child);
}
