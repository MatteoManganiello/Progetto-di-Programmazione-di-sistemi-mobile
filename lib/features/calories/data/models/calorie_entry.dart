class CalorieEntry {
  final String id;
  final String name;
  final int caloriesPerUnit;
  final int quantity;
  final String? notes;
  final DateTime timestamp;

  CalorieEntry({
    required this.id,
    required this.name,
    required this.caloriesPerUnit,
    this.quantity = 1,
    this.notes,
    required this.timestamp,
  });

  int get totalKcal => caloriesPerUnit * quantity;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'caloriesPerUnit': caloriesPerUnit,
    'quantity': quantity,
    'notes': notes,
    'timestamp': timestamp.toIso8601String(),
  };

  factory CalorieEntry.fromMap(Map<String, dynamic> map) => CalorieEntry(
    id: map['id'] as String,
    name: map['name'] as String,
    caloriesPerUnit: map['caloriesPerUnit'] as int,
    quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    notes: map['notes'] as String?,
    timestamp:
        DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
  );
}
