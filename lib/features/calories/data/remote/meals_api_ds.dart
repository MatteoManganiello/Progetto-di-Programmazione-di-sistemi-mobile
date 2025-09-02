import 'dart:async';
import '../../../../core/network/base_api.dart';

class Ingredient {
  final String ingredient;
  final String? measure;
  Ingredient({required this.ingredient, this.measure});
}

class Meal {
  final String id;
  final String name;
  final String? category;
  final String? area;
  final String? thumb;
  final String? instructions;
  final String? youtube;
  final List<Ingredient> ingredients;

  Meal({
    required this.id,
    required this.name,
    this.category,
    this.area,
    this.thumb,
    this.instructions,
    this.youtube,
    required this.ingredients,
  });

  factory Meal.fromApi(Map<String, dynamic> m) {
    final ings = <Ingredient>[];
    for (int i = 1; i <= 20; i++) {
      final ing = (m['strIngredient$i'] ?? '').toString().trim();
      final msr = (m['strMeasure$i'] ?? '').toString().trim();
      if (ing.isNotEmpty)
        ings.add(
          Ingredient(ingredient: ing, measure: msr.isEmpty ? null : msr),
        );
    }
    return Meal(
      id: (m['idMeal'] ?? '').toString(),
      name: (m['strMeal'] ?? '').toString(),
      category: (m['strCategory'] ?? '').toString().trim().isEmpty
          ? null
          : (m['strCategory'] as String),
      area: (m['strArea'] ?? '').toString().trim().isEmpty
          ? null
          : (m['strArea'] as String),
      thumb: (m['strMealThumb'] ?? '').toString().trim().isEmpty
          ? null
          : (m['strMealThumb'] as String),
      instructions: (m['strInstructions'] ?? '').toString().trim().isEmpty
          ? null
          : (m['strInstructions'] as String),
      youtube: (m['strYoutube'] ?? '').toString().trim().isEmpty
          ? null
          : (m['strYoutube'] as String),
      ingredients: ings,
    );
  }
}

class MealsApiDs {
  final BaseApi api;
  MealsApiDs(this.api);

  Future<List<Meal>> fetchRandomMeals(int n) async {
    final out = <Meal>[];
    for (var i = 0; i < n; i++) {
      final json = await api.getJson('/random.php');
      final meals = (json['meals'] as List?) ?? const [];
      if (meals.isNotEmpty) {
        final m = Map<String, dynamic>.from(meals.first as Map);
        out.add(Meal.fromApi(m));
      }
    }
    return out;
  }
}
