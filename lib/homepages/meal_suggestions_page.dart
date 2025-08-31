// lib/meal_suggestions_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MealSuggestionsPage extends StatefulWidget {
  const MealSuggestionsPage({super.key});

  @override
  State<MealSuggestionsPage> createState() => _MealSuggestionsPageState();
}

class _MealSuggestionsPageState extends State<MealSuggestionsPage> {
  static const _api = 'https://www.themealdb.com/api/json/v1/1';
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchRandomMeals(8); // quante proposte vuoi
  }

  Future<List<Map<String, dynamic>>> _fetchRandomMeals(int n) async {
    final List<Map<String, dynamic>> out = [];
    for (var i = 0; i < n; i++) {
      final uri = Uri.parse('$_api/random.php');
      final r = await http.get(uri).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final meals = (data['meals'] as List?) ?? [];
        if (meals.isNotEmpty) {
          out.add(Map<String, dynamic>.from(meals.first));
        }
      }
    }
    return out;
  }

  List<Map<String, String>> _ingredients(Map<String, dynamic> m) {
    final out = <Map<String, String>>[];
    for (int i = 1; i <= 20; i++) {
      final ing = (m['strIngredient$i'] ?? '').toString().trim();
      final msr = (m['strMeasure$i'] ?? '').toString().trim();
      if (ing.isNotEmpty) {
        out.add({'ingredient': ing, 'measure': msr});
      }
    }
    return out;
  }

  void _openDetails(Map<String, dynamic> meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final ings = _ingredients(meal);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal['strMeal'] ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (meal['strMealThumb'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        meal['strMealThumb'],
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text('Categoria: ${meal['strCategory'] ?? '-'}'),
                  Text('Area: ${meal['strArea'] ?? '-'}'),
                  const SizedBox(height: 12),
                  const Text(
                    'Ingredienti',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  ...ings.map(
                    (e) => Text(
                      '• ${e['ingredient']}${e['measure']!.isNotEmpty ? ' – ${e['measure']}' : ''}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Istruzioni',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (meal['strInstructions'] ?? '').toString(),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 12),
                  if ((meal['strYoutube'] ?? '').toString().isNotEmpty)
                    FilledButton.icon(
                      onPressed: () {
                        // Aprilo nel browser esterno:
                        // usa url_launcher se vuoi gestirlo in-app
                      },
                      icon: const Icon(Icons.ondemand_video),
                      label: const Text('Video su YouTube'),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cosa mangiare oggi?')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Errore: ${snap.error}'));
          }
          final meals = snap.data ?? [];
          if (meals.isEmpty) {
            return const Center(child: Text('Nessun suggerimento trovato.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.78,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: meals.length,
            itemBuilder: (context, i) {
              final m = meals[i];
              return InkWell(
                onTap: () => _openDetails(m),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (m['strMealThumb'] != null)
                        Image.network(
                          m['strMealThumb'],
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m['strMeal'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${m['strCategory'] ?? '-'} • ${m['strArea'] ?? '-'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
