import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models/calorie_entry.dart';
import '../data/daily_calo_repository.dart';
import '../data/local/daily_calo_local_ds.dart';
import '../data/remote/openfoodfacts_ds.dart';
import '../../../../core/network/base_api.dart';
import '../../../../core/network/connectivity_service.dart';

import '../ui/schermata_scanner_codice_barre.dart';

const Color _brandRed = Color.fromARGB(255, 211, 66, 66);
const Color _pageBgRed = Color.fromARGB(255, 244, 194, 194);
const Color _cardBorderRed = Colors.black;

class DailyCaloPage extends StatefulWidget {
  const DailyCaloPage({super.key});

  @override
  State<DailyCaloPage> createState() => _DailyCaloPageState();
}

class _DailyCaloPageState extends State<DailyCaloPage> {
  late final DailyCaloRepository repo;

  List<CalorieEntry> _entries = [];
  bool _loading = true;
  int? _dailyGoal;

  @override
  void initState() {
    super.initState();
    // Inietto dipendenze minime (puoi passare da qui a un DI centralizzato quando vuoi)
    final local = DailyCaloLocalDs();
    final off = OpenFoodFactsDs(
      BaseApi(baseUrl: 'https://world.openfoodfacts.org'),
    );
    repo = DailyCaloRepository(
      local: local,
      off: off,
      connectivity: ConnectivityService(),
    );
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final entries = await repo.getTodayEntries();
      final goal = await repo.getDailyGoal();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _dailyGoal = goal;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalKcal => _entries.fold(0, (sum, e) => sum + e.totalKcal);

  void _onAddPressed() => _openEntrySheet();

  void _onEditPressed(CalorieEntry entry) => _openEntrySheet(existing: entry);

  Future<void> _onScanPressed() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const SchermataScannerCodiceBarre()),
    );

    if (!mounted || barcode == null || barcode.isEmpty) return;

    final isBarcode = RegExp(r'^\d{8,14}$').hasMatch(barcode);
    if (!isBarcode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Codice non valido: non sembra un EAN/UPC'),
        ),
      );
      return;
    }

    final online = await repo.isOnline();
    String? initialName;
    int? initialKcal;
    String? initialNotes;

    if (online) {
      try {
        final info = await repo.fetchFromBarcode(barcode);
        if (info != null) {
          initialName = info.name;
          initialKcal = info.kcal;
          initialNotes = info.note;
        }
      } catch (_) {}
    }

    await _openEntrySheet(
      initialName: initialName ?? 'Prodotto ($barcode)',
      initialKcal: initialKcal,
      initialQty: 1,
      initialNotes: initialNotes ?? 'Aggiunto da barcode: $barcode',
    );
  }

  Future<void> _openEntrySheet({
    CalorieEntry? existing,
    String? initialName,
    int? initialKcal,
    int? initialQty,
    String? initialNotes,
  }) async {
    final nameCtrl = TextEditingController(
      text: existing?.name ?? initialName ?? '',
    );
    final kcalCtrl = TextEditingController(
      text: (existing?.caloriesPerUnit ?? initialKcal)?.toString() ?? '',
    );
    final qtyCtrl = TextEditingController(
      text: (existing?.quantity ?? initialQty ?? 1).toString(),
    );
    final notesCtrl = TextEditingController(
      text: existing?.notes ?? initialNotes ?? '',
    );
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: viewInsets.bottom + 16,
            top: 10,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  existing == null ? 'Aggiungi pasto' : 'Modifica pasto',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Alimento / Pasto',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _cardBorderRed, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _cardBorderRed, width: 1.5),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Campo obbligatorio'
                      : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: kcalCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Calorie per unità (kcal)',
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _cardBorderRed,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _cardBorderRed,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Obbligatorio';
                          final n = int.tryParse(v);
                          if (n == null || n <= 0) return 'Valore non valido';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Quantità',
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _cardBorderRed,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _cardBorderRed,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n <= 0) return '≥ 1';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Note (opzionale)',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _cardBorderRed, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _cardBorderRed, width: 1.5),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      final newEntry = CalorieEntry(
                        id:
                            existing?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameCtrl.text.trim(),
                        caloriesPerUnit: int.parse(kcalCtrl.text.trim()),
                        quantity: int.tryParse(qtyCtrl.text.trim()) ?? 1,
                        notes: notesCtrl.text.trim().isEmpty
                            ? null
                            : notesCtrl.text.trim(),
                        timestamp: existing?.timestamp ?? DateTime.now(),
                      );

                      if (existing == null) {
                        await repo.addEntryToday(newEntry);
                      } else {
                        await repo.updateEntryToday(newEntry);
                      }

                      if (!mounted) return;
                      setState(() {
                        if (existing == null) {
                          _entries.insert(0, newEntry);
                        } else {
                          final i = _entries.indexWhere(
                            (e) => e.id == existing.id,
                          );
                          if (i != -1) _entries[i] = newEntry;
                        }
                      });
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.check),
                    label: Text(existing == null ? 'Aggiungi' : 'Salva'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmClearToday() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Azzera voci di oggi?'),
        content: const Text('Questa azione rimuoverà tutte le voci di oggi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Conferma'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await repo.clearToday();
      if (!mounted) return;
      setState(() => _entries.clear());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Voci di oggi rimosse')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dailyGoal != null && _dailyGoal! > 0)
        ? (_totalKcal / _dailyGoal!)
        : null;

    return Scaffold(
      backgroundColor: _pageBgRed,
      appBar: AppBar(
        title: const Text('Calorie giornaliere'),
        backgroundColor: _pageBgRed,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            tooltip: 'Azzera oggi',
            onPressed: _entries.isEmpty ? null : _confirmClearToday,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 56.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton.extended(
              heroTag: 'fab_scan',
              onPressed: _onScanPressed,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scansiona'),
              backgroundColor: _brandRed,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            FloatingActionButton.extended(
              heroTag: 'fab_add',
              onPressed: _onAddPressed,
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi'),
              backgroundColor: _brandRed,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(_brandRed),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAll,
              color: _brandRed,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                children: [
                  _SummaryCard(
                    total: _totalKcal,
                    goal: _dailyGoal,
                    progress: progress,
                  ),
                  const SizedBox(height: 12),
                  if (_entries.isEmpty)
                    _EmptyState(onAdd: _onAddPressed)
                  else
                    ..._entries.map(
                      (e) => _EntryTile(
                        entry: e,
                        onEdit: () => _onEditPressed(e),
                        onDelete: () async {
                          await repo.deleteEntryToday(e.id);
                          if (!mounted) return;
                          setState(
                            () => _entries.removeWhere((x) => x.id == e.id),
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

// --- UI helper widgets (identici al tuo comportamento) ---
class _SummaryCard extends StatelessWidget {
  final int total;
  final int? goal;
  final double? progress;

  const _SummaryCard({
    required this.total,
    required this.goal,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _cardBorderRed, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Oggi',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '$total kcal',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (goal != null) const SizedBox(width: 8),
                if (goal != null)
                  Text(
                    'Obiettivo: $goal kcal',
                    style: const TextStyle(fontSize: 14),
                  ),
              ],
            ),
            if (goal != null && progress != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress!.clamp(0.0, 1.0),
                  minHeight: 10,
                  valueColor: const AlwaysStoppedAnimation<Color>(_brandRed),
                  backgroundColor: _pageBgRed,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${(progress! * 100).clamp(0, 100).toStringAsFixed(0)}% dell’obiettivo',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _cardBorderRed, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.fastfood, size: 48, color: _brandRed),
            const SizedBox(height: 8),
            const Text(
              'Nessuna voce per oggi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Aggiungi il tuo primo pasto con il pulsante qui sotto.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi pasto'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _brandRed,
                side: const BorderSide(color: _brandRed, width: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final CalorieEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EntryTile({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(entry.id),
      background: Container(
        color: _brandRed,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: _brandRed,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _cardBorderRed, width: 1),
        ),
        child: ListTile(
          title: Text(
            entry.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calorie/unità: ${entry.caloriesPerUnit} • Quantità: ${entry.quantity}',
              ),
              if (entry.notes != null && entry.notes!.isNotEmpty)
                Text(entry.notes!),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${entry.totalKcal} kcal',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: onEdit,
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.edit, size: 18, color: _brandRed),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
