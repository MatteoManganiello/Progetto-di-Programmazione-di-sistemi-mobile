import 'dart:convert';
import 'package:http/http.dart' as http;

/// Modello con le info principali ricavate dal prodotto.
class InfoAlimento {
  final String nome;
  final int? kcal;       // kcal per porzione o per 100 g
  final String? nota;    // es. "Per porzione (30 g)" o "Per 100 g"
  final String? immagineUrl;

  const InfoAlimento({
    required this.nome,
    this.kcal,
    this.nota,
    this.immagineUrl,
  });
}

/// Servizio per interrogare le API di OpenFoodFacts dato un barcode.
class ServizioOpenFoodFacts {
  /// Recupera informazioni base (nome, kcal, nota) dal barcode.
  ///
  /// Ritorna `null` se il prodotto non esiste o in caso di errore di rete.
  Future<InfoAlimento?> fetchDaBarcode(
    String barcode, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = Uri.https(
      'world.openfoodfacts.org',
      '/api/v2/product/$barcode.json',
      {
        // Limitiamo i campi per risposta più veloce
        'fields': 'product_name,product_name_it,brands,nutriments,serving_size,image_front_url',
      },
    );

    final res = await http
        .get(
          uri,
          headers: {
            // Aiuta OFF a prioritizzare contenuti in italiano
            'Accept-Language': 'it',
            'User-Agent': 'FlutterCaloApp/1.0 (+https://example.invalid)',
          },
        )
        .timeout(timeout);

    if (res.statusCode != 200) return null;

    final root = jsonDecode(res.body) as Map<String, dynamic>;
    if ((root['status'] as num?)?.toInt() != 1) return null;

    final product = (root['product'] as Map).cast<String, dynamic>();

    // Nome prodotto (preferisci italiano)
    final nome = (product['product_name_it'] ??
            product['product_name'] ??
            (product['brands'] != null ? '${product['brands']} - Prodotto' : 'Prodotto'))
        .toString();

    // Nutrimenti
    final nutr = (product['nutriments'] as Map?)?.cast<String, dynamic>();

    // kcal per porzione / 100g (alcuni prodotti hanno solo kJ)
    double? kcalServing =
        _asNum(nutr?['energy-kcal_serving'])?.toDouble();
    double? kcal100g = _asNum(nutr?['energy-kcal_100g'])?.toDouble();

    if (kcalServing == null || kcalServing <= 0) {
      final kJserv = _asNum(nutr?['energy_serving'])?.toDouble();
      if (kJserv != null && kJserv > 0) kcalServing = kJserv / 4.184; // kJ → kcal
    }
    if (kcal100g == null || kcal100g <= 0) {
      final kJ100 = _asNum(nutr?['energy_100g'])?.toDouble();
      if (kJ100 != null && kJ100 > 0) kcal100g = kJ100 / 4.184; // kJ → kcal
    }

    int? kcal;
    String? nota;

    if (kcalServing != null && kcalServing > 0) {
      kcal = kcalServing.round();
      final serving = product['serving_size']?.toString();
      nota = (serving != null && serving.isNotEmpty)
          ? 'Per porzione ($serving)'
          : 'Per porzione';
    } else if (kcal100g != null && kcal100g > 0) {
      kcal = kcal100g.round();
      nota = 'Per 100 g';
    }

    final immagineUrl = product['image_front_url']?.toString();

    return InfoAlimento(
      nome: nome,
      kcal: kcal,
      nota: nota,
      immagineUrl: immagineUrl,
    );
  }

  // --- Helpers ---

  /// Tenta di convertire dinamicamente un valore (num/string) in num.
  static num? _asNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;
      // Rimuovi eventuali unità (es. "450 kJ" → "450")
      final onlyNum = RegExp(r'^[\d\.\,]+').stringMatch(s) ?? s;
      final normalized = onlyNum.replaceAll(',', '.');
      return num.tryParse(normalized);
    }
    return null;
  }
}
