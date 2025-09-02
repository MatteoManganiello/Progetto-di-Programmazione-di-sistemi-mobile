import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ActivitiesLocalDs {
  static const _chiavePeso = 'peso_utente_kg';
  static const _attivitaPrefix = 'attivita_selezionate_'; // + yyyymmdd

  Future<double?> getPeso() async {
    final prefs = await SharedPreferences.getInstance();
    final d =
        prefs.getDouble(_chiavePeso) ?? prefs.getInt(_chiavePeso)?.toDouble();
    return d;
  }

  Future<void> setPeso(double kg) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_chiavePeso, kg);
  }

  String _oggiKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$_attivitaPrefix$y$m$d';
    // <-- stessa forma usata dalla Home ("attivita_selezionate_yyyymmdd")
  }

  Future<Map<String, dynamic>> addAttivitaSelezionataOggi({
    required String nome,
    required String assetPath,
    required int minuti,
    required String durata,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _oggiKey();
    final lista = prefs.getStringList(key) ?? [];

    final voce = {
      'nome': nome,
      'assetPath': assetPath,
      'minuti': minuti,
      'durata': durata,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // mantieni una sola voce per nome (come nel tuo codice originale)
    final target = nome.toLowerCase();
    final filtrata = <String>[];
    for (final s in lista) {
      try {
        final m = jsonDecode(s);
        if ((m['nome']?.toString().toLowerCase() ?? '') != target) {
          filtrata.add(s);
        }
      } catch (_) {}
    }
    filtrata.add(jsonEncode(voce));
    await prefs.setStringList(key, filtrata);

    return voce;
  }

  Future<void> resetAttivitaOggi() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_oggiKey());
  }
}
