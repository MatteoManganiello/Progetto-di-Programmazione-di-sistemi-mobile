String todayKey() => dateKeyFrom(DateTime.now());

String todayKeyCompact() => dateKeyCompactFrom(DateTime.now());

String dateKeyFrom(DateTime date) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}

String dateKeyCompactFrom(DateTime date) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${date.year}${two(date.month)}${two(date.day)}';
}
