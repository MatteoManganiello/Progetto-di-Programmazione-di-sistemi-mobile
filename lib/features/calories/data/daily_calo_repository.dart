import 'local/daily_calo_local_ds.dart';
import 'models/calorie_entry.dart';
import 'remote/openfoodfacts_ds.dart';
import '../../../../core/network/connectivity_service.dart';

class DailyCaloRepository {
  final DailyCaloLocalDs local;
  final OpenFoodFactsDs off;
  final ConnectivityService connectivity;

  DailyCaloRepository({
    required this.local,
    required this.off,
    required this.connectivity,
  });

  // Locale
  Future<List<CalorieEntry>> getTodayEntries() => local.getTodayEntries();

  Future<void> addEntryToday(CalorieEntry entry) async {
    final list = await local.getTodayEntries();
    list.insert(0, entry);
    await local.saveTodayEntries(list);
  }

  Future<void> updateEntryToday(CalorieEntry entry) async {
    final list = await local.getTodayEntries();
    final i = list.indexWhere((e) => e.id == entry.id);
    if (i != -1) list[i] = entry;
    await local.saveTodayEntries(list);
  }

  Future<void> deleteEntryToday(String id) async {
    final list = await local.getTodayEntries();
    list.removeWhere((e) => e.id == id);
    await local.saveTodayEntries(list);
  }

  Future<void> clearToday() => local.clearToday();

  Future<int?> getDailyGoal() => local.getDailyGoal();

  // Remote
  Future<bool> isOnline() => connectivity.isOnline();

  Future<OffFoodInfo?> fetchFromBarcode(String barcode) =>
      off.fetchDaBarcode(barcode);
}
