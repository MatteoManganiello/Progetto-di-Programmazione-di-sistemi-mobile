import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/home_repository.dart';
import '../data/home_local_ds.dart';

class WeeklyGoalPage extends StatefulWidget {
  const WeeklyGoalPage({super.key});
  static const route = '/weekly-goal';

  @override
  State<WeeklyGoalPage> createState() => _WeeklyGoalPageState();
}

class _WeeklyGoalPageState extends State<WeeklyGoalPage> {
  // UI constants
  static const _brand = Color.fromARGB(255, 99, 228, 103);
  static const _min = 800, _max = 5000, _step = 50;

  final _controller = TextEditingController();
  late final HomeRepository _repo;

  int? _original;
  int _goal = 2000;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repo = HomeRepository(HomeLocalDs());
    _load();
  }

  Future<void> _load() async {
    final saved = await _repo.getDailyGoal();
    setState(() {
      _original = saved;
      _goal = saved ?? 2000;
      _controller.text = _goal.toString();
      _loading = false;
    });
  }

  void _setGoal(int v) {
    final clamped = v.clamp(_min, _max);
    if (clamped == _goal) return;
    _goal = clamped;
    _controller.text = _goal.toString();
    setState(() {});
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    await _repo.setDailyGoal(_goal);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Obiettivo impostato a $_goal kcal')),
    );
    Navigator.pop(context, _goal); // ritorna il nuovo valore alla chiamante
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final canSave = _goal >= _min && _goal <= _max && _goal != _original;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        title: const SizedBox.shrink(),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          child: Card(
            elevation: 1.5,
            surfaceTintColor: Colors.transparent,
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.black, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_original != null)
                    Text(
                      'Obiettivo attuale: $_original kcal',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton.filled(
                        onPressed: () => _setGoal(_goal - _step),
                        style: IconButton.styleFrom(backgroundColor: _brand),
                        icon: const Icon(Icons.remove, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            hintText: 'Es. 2000',
                            suffixText: 'kcal',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (v) {
                            final n = int.tryParse(v);
                            if (n != null) _setGoal(n);
                          },
                          onSubmitted: (_) => canSave ? _save() : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () => _setGoal(_goal + _step),
                        style: IconButton.styleFrom(backgroundColor: _brand),
                        icon: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: _goal.toDouble(),
                    min: _min.toDouble(),
                    max: _max.toDouble(),
                    divisions: (_max - _min) ~/ _step,
                    label: '$_goal kcal',
                    activeColor: _brand,
                    onChanged: (v) => _setGoal(v.round()),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [Text('800'), Text('5000')],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    color: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.black, width: 1.5),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoHeader(),
                          SizedBox(height: 8),
                          Text('Motivi comuni per assumere più calorie:'),
                          SizedBox(height: 6),
                          _Bullet('Fase di aumento massa muscolare (bulk).'),
                          _Bullet(
                            'Allenamento intenso o giornata molto attiva.',
                          ),
                          _Bullet('Recupero da infortunio o malattia.'),
                          _Bullet('Metabolismo basale elevato.'),
                          _Bullet('Obiettivo di aumento peso controllato.'),
                          SizedBox(height: 6),
                          Text(
                            'Suggerimento: distribuisci le calorie in pasti bilanciati (proteine, carboidrati, grassi e fibre).',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.red,
                  side: const BorderSide(color: Colors.white, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Annulla'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: canSave ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Salva'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _InfoHeader extends StatelessWidget {
  const _InfoHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.info_outline, color: _WeeklyGoalPageState._brand),
        SizedBox(width: 8),
        Text(
          'Perché questo obiettivo?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
