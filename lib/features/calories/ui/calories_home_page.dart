import 'dart:async';
import 'package:flutter/material.dart';

import '../data/home_repository.dart';
import '../data/home_local_ds.dart';
import 'weekly_goal_page.dart';
import 'daily_calo_page.dart';
import 'meal_suggestions_page.dart';

class CaloriesHomePage extends StatefulWidget {
  const CaloriesHomePage({super.key});

  @override
  State<CaloriesHomePage> createState() => _CaloriesHomePageState();
}

class _CaloriesHomePageState extends State<CaloriesHomePage> {
  late final HomeRepository repo;

  int? _dailyGoal;
  bool _isLoadingGoal = true;
  bool _isSaving = false;

  int _todayTotalKcal = 0;
  bool _isLoadingToday = true;

  List<Map<String, dynamic>> _attivitaScelteOggi = [];
  bool _isLoadingAttivita = true;

  @override
  void initState() {
    super.initState();
    repo = HomeRepository(HomeLocalDs());
    _refreshAll();
  }

  Future<void> _loadDailyGoal() async {
    setState(() => _isLoadingGoal = true);
    try {
      final goal = await repo.getDailyGoal();
      if (!mounted) return;
      setState(() => _dailyGoal = goal);
    } finally {
      if (mounted) setState(() => _isLoadingGoal = false);
    }
  }

  Future<void> _loadTodayTotal() async {
    setState(() => _isLoadingToday = true);
    try {
      final total = await repo.getTodayTotalCalories();
      if (!mounted) return;
      setState(() => _todayTotalKcal = total);
    } finally {
      if (mounted) setState(() => _isLoadingToday = false);
    }
  }

  Future<void> _loadAttivitaScelteOggi() async {
    setState(() => _isLoadingAttivita = true);
    try {
      final list = await repo.getAttivitaSelezionateOggi();
      if (!mounted) return;
      setState(() => _attivitaScelteOggi = list);
    } finally {
      if (mounted) setState(() => _isLoadingAttivita = false);
    }
  }

  Future<void> _openDailyGoalPage() async {
    setState(() => _isSaving = true);
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const WeeklyGoalPage()),
    );

    if (result is int) {
      await repo.setDailyGoal(result);
      if (!mounted) return;
      setState(() => _dailyGoal = result);
    } else {
      await _loadDailyGoal();
    }
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _openAttivitaPage() async {
    await Navigator.pushNamed(context, '/attivita', arguments: _todayTotalKcal);
    if (!mounted) return;
    await _loadAttivitaScelteOggi();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadDailyGoal(),
      _loadTodayTotal(),
      _loadAttivitaScelteOggi(),
    ]);
  }

  int _parseDurataToSeconds(String durata) {
    final regex = RegExp(r'^\s*(?:(\d+)\s*h)?\s*(?:(\d+)\s*m)?\s*$');
    final m = regex.firstMatch(durata);
    if (m == null) return 0;
    final h = int.tryParse(m.group(1) ?? '0') ?? 0;
    final min = int.tryParse(m.group(2) ?? '0') ?? 0;
    return h * 3600 + min * 60;
  }

  String _fmtHHMMSS(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _openTimerFor(Map<String, dynamic> activity) async {
    final sport = activity['nome']?.toString() ?? 'Attività';
    final durataStr = activity['durata']?.toString() ?? '';
    final recSeconds = _parseDurataToSeconds(durataStr);

    Timer? t;
    int remaining = recSeconds > 0 ? recSeconds : 0;
    bool running = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            void start() {
              if (running) return;
              running = true;
              t?.cancel();
              t = Timer.periodic(const Duration(seconds: 1), (_) {
                if (!running) return;
                if (remaining <= 0) {
                  running = false;
                  t?.cancel();
                  setModalState(() {});
                  return;
                }
                remaining -= 1;
                setModalState(() {});
              });
              setModalState(() {});
            }

            void pause() {
              running = false;
              t?.cancel();
              setModalState(() {});
            }

            void reset() {
              running = false;
              t?.cancel();
              remaining = recSeconds;
              setModalState(() {});
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text(
                        'Timer - $sport',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (durataStr.isNotEmpty)
                        const Text(
                          'Durata consigliata:',
                          style: TextStyle(fontSize: 14),
                        ),
                      if (durataStr.isNotEmpty)
                        Text(durataStr, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 18),
                      Text(
                        _fmtHHMMSS(remaining),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: running ? pause : start,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: running
                                  ? Colors.red
                                  : Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(130, 44),
                            ),
                            icon: Icon(
                              running ? Icons.pause : Icons.play_arrow,
                            ),
                            label: Text(running ? 'Pausa' : 'Avvia'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: reset,
                            icon: const Icon(Icons.restart_alt),
                            label: const Text('Reset'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() => t?.cancel());
  }

  Widget _buildCalorieTrailing(Color cardColor) {
    if (_isLoadingToday || _isLoadingGoal) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final goal = _dailyGoal ?? 0;
    final ratio = goal > 0 ? (_todayTotalKcal / goal).clamp(0.0, 1.0) : 0.0;

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 210),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: ratio,
                    strokeWidth: 6,
                    backgroundColor: cardColor.withOpacity(0.22),
                    valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                  ),
                  Text(
                    '${(ratio * 100).round()}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 3),
            Card(
              color: cardColor,
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Text(
                  '$_todayTotalKcal kcal',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasGoal = _dailyGoal != null;

    const goalTitle = 'Obiettivo giornaliero';

    final Widget? goalTrailing = (!hasGoal || _isLoadingGoal)
        ? null
        : Card(
            color: theme.colorScheme.onPrimary,
            elevation: 1.3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(90),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
              child: Text(
                '${_dailyGoal!} kcal',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
            ),
          );

    final BorderRadius outerBigTopRight = const BorderRadius.only(
      topRight: Radius.circular(100),
      topLeft: Radius.circular(16),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(16),
    );
    final BorderRadius innerBigTopRight = const BorderRadius.only(
      topRight: Radius.circular(90),
      topLeft: Radius.circular(12),
      bottomLeft: Radius.circular(12),
      bottomRight: Radius.circular(12),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'Imposta obiettivo',
            onPressed: _isSaving ? null : _openDailyGoalPage,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(),
                  )
                : const Icon(Icons.flag_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ListView(
            children: [
              _ColoredCard(
                cardName: goalTitle,
                imagePath: 'assets/images/add.png',
                color: const Color.fromARGB(255, 98, 204, 71),
                width: double.infinity,
                height: 60,
                onTap: _openDailyGoalPage,
                trailing: goalTrailing,
              ),
              if (_dailyGoal == null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _openDailyGoalPage,
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Tocca la card per impostare l\'obiettivo',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ColoredCard(
                      cardName: 'Calorie\ngiornaliere',
                      imagePath: 'assets/images/Torcia.png',
                      color: const Color.fromARGB(255, 211, 66, 66),
                      height: 240,
                      insetWhite: true,
                      iconTopLeft: true,
                      trailing: _buildCalorieTrailing(
                        const Color.fromARGB(255, 211, 66, 66),
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DailyCaloPage(),
                          ),
                        );
                        if (mounted) _loadTodayTotal();
                      },
                      outerBorderRadius: outerBigTopRight,
                      innerBorderRadius: innerBigTopRight,
                      imageWidth: 70,
                      imageHeight: 70,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ColoredCard(
                      cardName: 'Sport\ngiornaliero',
                      imagePath: 'assets/images/Attivita.png',
                      color: const Color.fromARGB(255, 210, 73, 180),
                      height: 240,
                      insetWhite: true,
                      iconTopLeft: true,
                      outerBorderRadius: outerBigTopRight,
                      innerBorderRadius: innerBigTopRight,
                      imageWidth: 70,
                      imageHeight: 70,
                      trailing: _attivitaTrailing(),
                      onTap: _openAttivitaPage,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  void _openSuggestions() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MealSuggestionsPage(),
                      ),
                    );
                  }

                  return Card(
                    color: const Color.fromARGB(255, 45, 184, 253),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(40),
                      splashFactory: NoSplash.splashFactory,
                      highlightColor: Colors.transparent,
                      onTap: _openSuggestions,
                      child: const SizedBox(
                        height: 81,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 19.0,
                            vertical: 2,
                          ),
                          child: _SuggestionsCardContent(),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text('Blogs', style: TextStyle(fontSize: 22)),
              const SizedBox(height: 12),
              SizedBox(
                height: 400,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _HorizontalCard(
                      title: 'Ricetta proteica',
                      subtitle:
                          'In un mondo sempre più frenetico e dominato da abitudini sedentarie, prendersi cura del proprio corpo e della propria mente è diventato fondamentale. L’attività fisica regolare, abbinata a un’alimentazione equilibrata, è un investimento sulla qualità della vita. Sport e buona alimentazione lavorano in sinergia per migliorare il benessere fisico, mentale ed emotivo.',
                      imagePath: 'assets/images/Alimentazione.png',
                    ),
                    SizedBox(width: 12),
                    _HorizontalCard(
                      title: 'Consiglio nutrizionale',
                      subtitle:
                          'Il termine cibo spazzatura (dall’inglese junk food) si riferisce a tutti quegli alimenti ad alta densità calorica ma poveri di valore nutrizionale. Si tratta per lo più di prodotti industriali altamente processati, ricchi di zuccheri raffinati, grassi saturi, sale e additivi chimici, ma estremamente poveri di vitamine, minerali, fibre e proteine di qualità. Nonostante ciò, il cibo spazzatura è oggi una delle opzioni alimentari più diffuse, soprattutto tra bambini, adolescenti e giovani adulti, grazie alla sua facile reperibilità, al basso costo e al sapore gratificante.',
                      imagePath: 'assets/images/CiboSpazzatura.png',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attivitaTrailing() {
    if (_isLoadingAttivita) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (_attivitaScelteOggi.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(6),
        child: Text(
          'Seleziona attività',
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 12),
        ),
      );
    }

    final ultima = _attivitaScelteOggi.first;
    final assetPath = ultima['assetPath']?.toString();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(0),
            child: assetPath != null && assetPath.isNotEmpty
                ? Image.asset(
                    assetPath,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_not_supported, size: 32),
                  )
                : const Icon(Icons.fitness_center, size: 32),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 210, 73, 180),
              foregroundColor: Colors.white,
              minimumSize: const Size(55, 30),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            onPressed: () => _openTimerFor(ultima),
            icon: const Icon(Icons.timer, size: 20),
            label: const Text('timer', style: TextStyle(fontSize: 15.5)),
          ),
        ],
      ),
    );
  }
}

class _ColoredCard extends StatelessWidget {
  final String cardName;
  final String imagePath;
  final Color? color;
  final double? width;
  final double height;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool insetWhite;
  final Color insetColor;
  final double insetRadius;
  final EdgeInsets insetMargin;
  final bool iconTopLeft;
  final BorderRadius? outerBorderRadius;
  final BorderRadius? innerBorderRadius;
  final double? imageWidth;
  final double? imageHeight;

  const _ColoredCard({
    required this.cardName,
    required this.imagePath,
    this.color,
    this.width,
    this.height = 100,
    this.onTap,
    this.trailing,
    this.insetWhite = false,
    this.insetColor = Colors.white,
    this.insetRadius = 14,
    this.insetMargin = const EdgeInsets.all(10),
    this.iconTopLeft = false,
    this.outerBorderRadius,
    this.innerBorderRadius,
    this.imageWidth,
    this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    final content = _SampleCard(
      cardName: cardName,
      imagePath: imagePath,
      height: height,
      onTap: onTap,
      trailing: trailing,
      iconTopLeft: iconTopLeft,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );

    return SizedBox(
      width: width,
      child: Card(
        color: color,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: outerBorderRadius ?? BorderRadius.circular(90),
        ),
        child: insetWhite
            ? Padding(
                padding: insetMargin,
                child: Container(
                  decoration: BoxDecoration(
                    color: insetColor,
                    borderRadius:
                        innerBorderRadius ?? BorderRadius.circular(insetRadius),
                  ),
                  child: content,
                ),
              )
            : content,
      ),
    );
  }
}

class _SampleCard extends StatelessWidget {
  final String cardName;
  final String imagePath;
  final double height;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool iconTopLeft;
  final double? imageWidth;
  final double? imageHeight;

  const _SampleCard({
    required this.cardName,
    required this.imagePath,
    required this.height,
    this.onTap,
    this.trailing,
    this.iconTopLeft = false,
    this.imageWidth,
    this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (iconTopLeft) {
      return InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned(
                top: 9,
                left: 6,
                child: Image.asset(
                  imagePath,
                  width: imageWidth ?? 48,
                  height: imageHeight ?? 48,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      cardName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              if (trailing != null)
                Positioned(right: 12, bottom: 12, child: trailing!),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              Image.asset(
                imagePath,
                width: imageWidth ?? 30,
                height: imageHeight ?? 30,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cardName,
                  style: const TextStyle(fontSize: 20),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class _HorizontalCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;

  const _HorizontalCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        elevation: 4,
        color: const Color.fromARGB(255, 153, 198, 193),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(imagePath, width: 255, height: 220, fit: BoxFit.cover),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          subtitle,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionsCardContent extends StatelessWidget {
  const _SuggestionsCardContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Non sai cosa mangiare oggi?',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        Center(
          child: FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MealSuggestionsPage()),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
                side: const BorderSide(color: Colors.black54, width: 2),
              ),
            ),
            icon: const Icon(Icons.restaurant_menu),
            label: const Text(
              'Apri suggerimenti',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
