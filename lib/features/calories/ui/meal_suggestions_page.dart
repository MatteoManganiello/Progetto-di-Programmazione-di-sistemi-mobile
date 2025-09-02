import 'package:flutter/material.dart';
import '../data/meal_suggestions_repository.dart';
import '../data/remote/meals_api_ds.dart';
import '../../../../core/network/base_api.dart';

class MealSuggestionsPage extends StatefulWidget {
  const MealSuggestionsPage({super.key});

  @override
  State<MealSuggestionsPage> createState() => _MealSuggestionsPageState();
}

class _MealSuggestionsPageState extends State<MealSuggestionsPage> {
  late final MealSuggestionsRepository repo;
  late Future<List<Meal>> _future;

  @override
  void initState() {
    super.initState();
    // Iniezione semplice; puoi passare a DI centralizzato quando vuoi.
    repo = MealSuggestionsRepository(
      MealsApiDs(BaseApi(baseUrl: 'https://www.themealdb.com/api/json/v1/1')),
    );
    _future = repo.getRandomMeals(8); // quante proposte vuoi
  }

  void _openDetails(Meal meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con titolo + bottone Chiudi
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meal.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Chiudi',
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (meal.thumb != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        meal.thumb!,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),

                  const SizedBox(height: 12),
                  Text('Categoria: ${meal.category ?? '-'}'),
                  Text('Area: ${meal.area ?? '-'}'),
                  const SizedBox(height: 12),

                  const Text(
                    'Ingredienti',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  ...meal.ingredients.map((e) {
                    final msr = (e.measure ?? '').trim();
                    return Text(
                      '• ${e.ingredient}${msr.isNotEmpty ? ' – $msr' : ''}',
                    );
                  }),

                  const SizedBox(height: 12),
                  const Text(
                    'Istruzioni',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(meal.instructions ?? ''),

                  const SizedBox(height: 16),
                  if ((meal.youtube ?? '').isNotEmpty)
                    FilledButton.icon(
                      onPressed: () {
                        // TODO: apri con url_launcher (facoltativo)
                      },
                      icon: const Icon(Icons.ondemand_video),
                      label: const Text('Video su YouTube'),
                    ),

                  const SizedBox(height: 16),
                  // Pulsante evidente per uscire
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Torna alla lista'),
                    ),
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
      appBar: AppBar(
        leading: const BackButton(), // back sempre visibile
        title: const Text('Cosa mangiare oggi?'),
      ),
      body: FutureBuilder<List<Meal>>(
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
              // Card → InkWell interno (no rettangolo overlay, splash disattivato)
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias, // clip contenuto + ripple
                child: InkWell(
                  onTap: () => _openDetails(m),
                  borderRadius: BorderRadius.circular(14),
                  splashFactory: NoSplash.splashFactory, // niente splash
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (m.thumb != null)
                        Image.network(
                          m.thumb!,
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
                              m.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${m.category ?? '-'} • ${m.area ?? '-'}',
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
