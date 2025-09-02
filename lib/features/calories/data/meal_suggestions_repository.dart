import 'remote/meals_api_ds.dart';

class MealSuggestionsRepository {
  final MealsApiDs remote;
  MealSuggestionsRepository(this.remote);

  Future<List<Meal>> getRandomMeals(int n) => remote.fetchRandomMeals(n);
}
