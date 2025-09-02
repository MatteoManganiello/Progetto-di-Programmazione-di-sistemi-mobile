import 'package:flutter/material.dart';
import '../data/activities_repository.dart';
import '../data/local/activities_local_ds.dart';

class ActivitiesPage extends StatefulWidget {
  final int kcalDaSmaltire;
  final void Function(Map<String, dynamic> scelta)? onAttivitaSelezionata;

  const ActivitiesPage({
    super.key,
    required this.kcalDaSmaltire,
    this.onAttivitaSelezionata,
  });

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  static const _brand = Color.fromARGB(255, 210, 73, 180);

  late final ActivitiesRepository repo;

  final TextEditingController _pesoCtrl = TextEditingController();
  double _peso = 70;
  bool _loading = true;

  // Catalogo attività (statico come nel tuo file originale)
  final List<_Attivita> _attivita = const [
    _Attivita(
      nome: 'Corsa leggera',
      met: 8.0,
      assetPath: 'assets/images/corsa.png',
    ),
    _Attivita(
      nome: 'Ciclismo moderato',
      met: 6.8,
      assetPath: 'assets/images/ciclismo.png',
    ),
    _Attivita(
      nome: 'Nuoto moderato',
      met: 6.0,
      assetPath: 'assets/images/nuoto.png',
    ),
    _Attivita(
      nome: 'Salto con la corda',
      met: 10.0,
      assetPath: 'assets/images/corda.png',
    ),
    _Attivita(nome: 'Tennis', met: 7.3, assetPath: 'assets/images/tennis.png'),
    _Attivita(nome: 'Calcio', met: 7.0, assetPath: 'assets/images/calcio.png'),
  ];

  @override
  void initState() {
    super.initState();
    repo = ActivitiesRepository(ActivitiesLocalDs());
    _loadPeso();
  }

  Future<void> _loadPeso() async {
    setState(() => _loading = true);
    final p = await repo.getPesoUtenteKg();
    _peso = (p != null && p > 0) ? p : 70.0;
    _pesoCtrl.text = _peso.toStringAsFixed(1);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _salvaPeso() async {
    final parsed = double.tryParse(_pesoCtrl.text.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return;
    await repo.setPesoUtenteKg(parsed);
    if (mounted) setState(() => _peso = parsed);
  }

  double _minutiPer(double met, double pesoKg, int kcal) {
    // formula classica: kcal/min = MET * 3.5 * peso(kg) / 200
    final kcalAlMin = (met * 3.5 * pesoKg) / 200.0;
    if (kcalAlMin <= 0) return 0;
    return kcal / kcalAlMin;
  }

  String _formatDurata(int minutiTotali) {
    final ore = minutiTotali ~/ 60;
    final minResto = minutiTotali % 60;
    if (minResto == 0 && ore > 0) return '${ore}h';
    if (ore == 0) return '${minResto}m';
    return '${ore}h ${minResto}m';
  }

  Future<void> _aggiungiAttivita({
    required _Attivita att,
    required int minuti,
    required String durata,
  }) async {
    final voce = await repo.addAttivitaSelezionataOggi(
      nome: att.nome,
      assetPath: att.assetPath,
      minuti: minuti,
      durata: durata,
    );
    widget.onAttivitaSelezionata?.call(voce);
  }

  Future<void> _resetAttivita() async {
    await repo.resetAttivitaOggi();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Attività azzerate'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final kcal = widget.kcalDaSmaltire;

    const pageBg = Color.fromARGB(255, 254, 229, 249);
    const cardBg = Colors.white;
    const cardBorder = Color.fromARGB(255, 1, 1, 1);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: const Text('Attività fisica'),
        elevation: 1,
        actions: [
          IconButton(
            tooltip: 'Reset attività',
            icon: const Icon(Icons.refresh),
            onPressed: _resetAttivita,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_brand),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    color: cardBg,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: cardBorder, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Calorie da smaltire',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$kcal kcal',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: _pesoCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Peso (kg)',
                                isDense: true,
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: cardBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _brand,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onSubmitted: (_) => _salvaPeso(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _salvaPeso,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                128,
                                215,
                                131,
                              ),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Salva'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _IntroCard(
                    testo:
                        'Per bruciare le calorie di oggi, scegli uno degli sport elencati qui sotto e praticalo per il tempo indicato.',
                    brand: _brand,
                    bg: cardBg,
                    border: cardBorder,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: kcal <= 0
                        ? const Center(
                            child: Text(
                              'Nessuna caloria da smaltire per oggi.',
                            ),
                          )
                        : ListView.separated(
                            itemCount: _attivita.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final att = _attivita[index];
                              final minuti = _minutiPer(
                                att.met,
                                _peso,
                                kcal,
                              ).ceil();
                              final durata = _formatDurata(minuti);

                              return Card(
                                color: cardBg,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: cardBorder,
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      att.assetPath,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.image_not_supported,
                                        color: _brand,
                                      ),
                                    ),
                                  ),
                                  title: Text(att.nome),
                                  trailing: Text(
                                    durata,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: _brand,
                                    ),
                                  ),
                                  onTap: () async {
                                    await _aggiungiAttivita(
                                      att: att,
                                      minuti: minuti,
                                      durata: durata,
                                    );
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Aggiunta: ${att.nome} ($durata)',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Attivita {
  final String nome;
  final double met;
  final String assetPath;

  const _Attivita({
    required this.nome,
    required this.met,
    required this.assetPath,
  });
}

class _IntroCard extends StatelessWidget {
  final String testo;
  final Color brand;
  final Color bg;
  final Color border;

  const _IntroCard({
    required this.testo,
    required this.brand,
    required this.bg,
    required this.border,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: bg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: brand),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                testo,
                style: const TextStyle(fontSize: 13.5, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
