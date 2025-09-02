import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calorie_entry.dart';

class DailyCaloLocalDs {
  static const String _entriesKeyPrefix = 'calo_entries_';
  static const String _dailyGoalPrefKey = 'daily_calorie_goal';

  String _todayKey() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}';
  }

  Future<List<CalorieEntry>> getTodayEntries() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('$_entriesKeyPrefix${_todayKey()}');
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map((e) => CalorieEntry.fromMap(e)).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // recenti in alto
  }

  Future<void> saveTodayEntries(List<CalorieEntry> entries) async {
    final sp = await SharedPreferences.getInstance();
    final data = jsonEncode(entries.map((e) => e.toMap()).toList());
    await sp.setString('$_entriesKeyPrefix${_todayKey()}', data);
  }

  Future<void> clearToday() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('$_entriesKeyPrefix${_todayKey()}');
  }

  Future<int?> getDailyGoal() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_dailyGoalPrefKey);
  }
}
