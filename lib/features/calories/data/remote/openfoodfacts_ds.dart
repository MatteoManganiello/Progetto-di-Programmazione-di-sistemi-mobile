import '../../../../core/network/base_api.dart';

class OffFoodInfo {
  final String name;
  final int? kcal;
  final String? note;
  OffFoodInfo({required this.name, this.kcal, this.note});
}

class OpenFoodFactsDs {
  final BaseApi api;
  OpenFoodFactsDs(this.api);

  /// Ritorna nome, kcal (se presenti) e una nota sintetica
  Future<OffFoodInfo?> fetchDaBarcode(String barcode) async {
    final json = await api.getJson('/api/v0/product/$barcode.json');
    final status = json['status'] as int?; // 1 = trovato
    if (status != 1) return null;

    final product = json['product'] as Map<String, dynamic>?;

    final name = (product?['product_name'] as String?)?.trim();
    if (name == null || name.isEmpty) return null;

    int? kcal;
    // OFF può dare energia in kJ; se c'è 'nutriments' proviamo a leggere 'energy-kcal_100g'
    final nutr = product?['nutriments'] as Map<String, dynamic>?;
    if (nutr != null) {
      final kcalAny = nutr['energy-kcal_100g'] ?? nutr['energy-kcal_serving'];
      if (kcalAny is num) kcal = kcalAny.round();
    }

    final brand = (product?['brands'] as String?)?.split(',').first.trim();
    final note = brand != null && brand.isNotEmpty
        ? 'Fonte OFF • Brand: $brand'
        : 'Fonte OFF';

    return OffFoodInfo(name: name, kcal: kcal, note: note);
  }
}
