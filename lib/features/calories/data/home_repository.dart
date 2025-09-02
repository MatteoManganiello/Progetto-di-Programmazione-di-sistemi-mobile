import 'home_local_ds.dart';

class HomeRepository {
  final HomeLocalDs local;
  HomeRepository(this.local);

  Future<int?> getDailyGoal() => local.getDailyGoal();
  Future<void> setDailyGoal(int goal) => local.setDailyGoal(goal);

  Future<int> getTodayTotalCalories() => local.getTodayTotalCalories();

  Future<List<Map<String, dynamic>>> getAttivitaSelezionateOggi() =>
      local.getAttivitaSelezionateOggi();
}
