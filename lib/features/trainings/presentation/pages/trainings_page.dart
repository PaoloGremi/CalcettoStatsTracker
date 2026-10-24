import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/entities/training.dart';
import '../controllers/trainings_controller.dart';
import '../widgets/pace_chart_card.dart';
import '../widgets/training_heatmap.dart';
import '../widgets/training_list_tile.dart';
import '../widgets/training_records_card.dart';
import 'training_form_page.dart';

/// Progressi e storico degli allenamenti.
class TrainingsPage extends StatefulWidget {
  /// [controller] serve ai test; se null se ne crea uno da `getIt`.
  const TrainingsPage({super.key, this.controller});

  final TrainingsController? controller;

  @override
  State<TrainingsPage> createState() => _TrainingsPageState();
}

class _TrainingsPageState extends State<TrainingsPage> {
  late final TrainingsController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? getIt<TrainingsController>();
    // Dopo il primo frame: il controller può essere quello della home, che
    // ha listener già montati; notificare durante questa build li sporcherebbe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.load();
    });
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  /// Il modulo salva tramite lo stesso controller, che ricarica da solo.
  Future<void> _openForm([Training? initial]) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<TrainingsController>.value(
            value: _controller,
            child: TrainingFormPage(initial: initial),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TrainingsController>.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: AppBar(
          title: const Text('Allenamenti'),
          actions: [
            IconButton(
              tooltip: 'Nuovo allenamento',
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _openForm(),
            ),
          ],
        ),
        body: Consumer<TrainingsController>(
          builder: (context, c, _) {
            if (c.isLoading && c.trainings.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (c.error != null && c.trainings.isEmpty) {
              return Center(
                child: Text(c.error!,
                    style: TextStyle(color: AppTheme.accentRed)),
              );
            }
            if (c.trainings.isEmpty) return _EmptyState(onAdd: _openForm);
            final stats = c.stats;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                TrainingRecordsCard(stats: stats),
                const SizedBox(height: 12),
                PaceChartCard(points: stats.pacePoints),
                // Sezione camminata: solo se ce n'è almeno una.
                if (stats.longestWalkKm != null) ...[
                  _sectionTitle('Camminata'),
                  WalkingRecordsCard(stats: stats),
                  const SizedBox(height: 12),
                  PaceChartCard(
                    points: stats.walkPacePoints,
                    title: 'Passo camminata (min/km)',
                    emptyMessage:
                        'Servono almeno 2 camminate per vedere l\'andamento',
                    color: AppTheme.accentGold,
                  ),
                ],
                const SizedBox(height: 12),
                TrainingHeatmap(
                  dayTypes: stats.dayTypes,
                  activeYears: stats.activeYears,
                  today: c.today,
                ),
                _sectionTitle('Storico'),
                for (final t in c.trainings)
                  TrainingListTile(
                    training: t,
                    today: c.today,
                    onTap: () => _openForm(t),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

Widget _sectionTitle(String text) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(text.toUpperCase(),
          style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2)),
    );

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_run_rounded,
                  size: 48, color: AppTheme.textMuted),
              const SizedBox(height: 12),
              Text('Nessun allenamento registrato',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Aggiungi allenamento'),
              ),
            ],
          ),
        ),
      );
}
