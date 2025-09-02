/// Helpers per chiavi data consistenti nell'app (timezone locale).

/// Ritorna 'YYYY-MM-DD' per *oggi* (es. '2025-09-01').
String todayKey() => dateKeyFrom(DateTime.now());

/// Ritorna 'YYYYMMDD' per *oggi* (es. '20250901').
String todayKeyCompact() => dateKeyCompactFrom(DateTime.now());

/// Ritorna 'YYYY-MM-DD' per una data specifica.
String dateKeyFrom(DateTime date) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}

/// Ritorna 'YYYYMMDD' per una data specifica.
String dateKeyCompactFrom(DateTime date) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${date.year}${two(date.month)}${two(date.day)}';
}
