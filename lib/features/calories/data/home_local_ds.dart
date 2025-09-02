import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HomeLocalDs {
  static const _prefKeyDailyGoal = 'daily_calorie_goal';
  static const _entriesKeyPrefix = 'calo_entries_'; // + YYYY-MM-DD
  static const _attivitaKeyPrefix = 'attivita_selezionate_'; // + YYYYMMDD

  String _todayKey() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}';
  }

  String _todayKeyCompact() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}';
  }

  Future<int?> getDailyGoal() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_prefKeyDailyGoal);
  }

  Future<void> setDailyGoal(int goal) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_prefKeyDailyGoal, goal);
  }

  /// Somma delle kcal delle voci di oggi: caloriesPerUnit * quantity
  Future<int> getTodayTotalCalories() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('$_entriesKeyPrefix${_todayKey()}');
    int total = 0;
    if (raw != null) {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      for (final m in list) {
        final cal = (m['caloriesPerUnit'] as num?)?.toInt() ?? 0;
        final qty = (m['quantity'] as num?)?.toInt() ?? 1;
        total += cal * qty;
      }
    }
    return total;
  }

  /// Lista attività selezionate oggi, ordinata per timestamp desc
  Future<List<Map<String, dynamic>>> getAttivitaSelezionateOggi() async {
    final sp = await SharedPreferences.getInstance();
    final key = '$_attivitaKeyPrefix${_todayKeyCompact()}';
    final list = sp.getStringList(key) ?? const [];
    final parsed = <Map<String, dynamic>>[];
    for (final s in list) {
      try {
        parsed.add(Map<String, dynamic>.from(jsonDecode(s)));
      } catch (_) {}
    }
    parsed.sort((a, b) {
      final at =
          DateTime.tryParse(
            a['timestamp']?.toString() ?? '',
          )?.millisecondsSinceEpoch ??
          0;
      final bt =
          DateTime.tryParse(
            b['timestamp']?.toString() ?? '',
          )?.millisecondsSinceEpoch ??
          0;
      return bt.compareTo(at);
    });
    return parsed;
  }
}
