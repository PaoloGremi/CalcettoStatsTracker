import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match_model.dart';
import '../data/hive_boxes.dart';
import '../widgets/player_avatar.dart';
import '../theme/app_theme.dart';
import '../services/data_service.dart';

class VoteScreen extends StatefulWidget {
  final MatchModel match;
  const VoteScreen({required this.match, super.key});

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  late final Map<String, TextEditingController> _commentControllers;
  late final Map<String, TextEditingController> _goalControllers;

  @override
  void initState() {
    super.initState();
    final allPlayers = [...widget.match.teamA, ...widget.match.teamB];
    _commentControllers = {};
    _goalControllers = {};
    for (final id in allPlayers) {
      if (!widget.match.votes.containsKey(id)) widget.match.votes[id] = 5.0;
      if (!widget.match.goals.containsKey(id)) widget.match.goals[id] = 0;
      _commentControllers[id] = TextEditingController(text: widget.match.comments[id] ?? '');
      final savedGoals = widget.match.goals[id] ?? 0;
      _goalControllers[id] = TextEditingController(
        text: savedGoals > 0 ? '$savedGoals' : '',
      );
    }
  }

  @override
  void dispose() {
    for (final c in _commentControllers.values) c.dispose();
    for (final c in _goalControllers.values) c.dispose();
    super.dispose();
  }

  Color _voteColor(double v) {
    if (v >= 8) return AppTheme.accentGreen;
    if (v >= 6.5) return AppTheme.accentGold;
    if (v >= 5) return AppTheme.accentOrange;
    return AppTheme.accentRed;
  }

  Widget _buildGoalCounter(String id) {
    final goals = widget.match.goals[id] ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🥅', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            if (goals > 0) {
              setState(() {
                widget.match.goals[id] = goals - 1;
                final newVal = goals - 1;
                _goalControllers[id]!.text = newVal > 0 ? '$newVal' : '';
              });
            }
          },
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: goals > 0 ? AppTheme.accentRed.withOpacity(0.15) : AppTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: goals > 0 ? AppTheme.accentRed.withOpacity(0.4) : AppTheme.border,
              ),
            ),
            child: Icon(Icons.remove_rounded, size: 16,
                color: goals > 0 ? AppTheme.accentRed : AppTheme.textMuted),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: TextField(
            controller: _goalControllers[id],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: goals > 0 ? AppTheme.accentGreen : AppTheme.textMuted,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
            decoration: const InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 18),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (text) {
              final val = int.tryParse(text) ?? 0;
              setState(() => widget.match.goals[id] = val.clamp(0, 99));
            },
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              final newVal = goals + 1;
              widget.match.goals[id] = newVal;
              _goalControllers[id]!.text = '$newVal';
            });
          },
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.accentGreen.withOpacity(0.4)),
            ),
            child: const Icon(Icons.add_rounded, size: 16, color: AppTheme.accentGreen),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSection(String teamLabel, List<String> playerIds, Color sectionAccent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FifaSectionHeader(teamLabel, accent: sectionAccent),
        ...playerIds.map((id) {
          final player = HiveBoxes.playersBox.get(id);
          final name = player?.name ?? 'Sconosciuto';
          final voto = widget.match.votes[id]?.toDouble() ?? 5.0;
          final accent = _voteColor(voto);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (player != null) PlayerAvatar(player: player, radius: 20),
                      if (player == null) const CircleAvatar(radius: 20, child: Icon(Icons.person)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(name.toUpperCase(),
                          style: const TextStyle(color: AppTheme.textPrimary,
                              fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      ),
                      _buildGoalCounter(id),
                      const SizedBox(width: 10),
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: accent.withOpacity(0.45), width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(voto.toStringAsFixed(1),
                              style: TextStyle(color: accent, fontSize: 18,
                                  fontWeight: FontWeight.w900, height: 1)),
                            Text('VOTO', style: TextStyle(color: accent.withOpacity(0.6),
                                fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: accent,
                      thumbColor: accent,
                      overlayColor: accent.withOpacity(0.15),
                      inactiveTrackColor: AppTheme.border,
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: voto,
                      min: 1, max: 10, divisions: 18,
                      label: voto.toStringAsFixed(1),
                      onChanged: (val) => setState(() => widget.match.votes[id] = val),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FifaLabel('1', color: AppTheme.accentRed, fontSize: 9),
                        FifaLabel('5', color: AppTheme.textMuted, fontSize: 9),
                        FifaLabel('10', color: AppTheme.accentGreen, fontSize: 9),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _commentControllers[id],
                    onChanged: (text) => widget.match.comments[id] = text,
                    maxLines: 2,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Commento opzionale...',
                      hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const FifaLabel('Vota i Giocatori', color: AppTheme.textPrimary, fontSize: 13),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _buildTeamSection('Squadra Bianca', widget.match.teamA, AppTheme.accentBlue),
          _buildTeamSection('Squadra Colorata', widget.match.teamB, AppTheme.accentOrange),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: const Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: ElevatedButton(
          onPressed: () async {
            // ✅ updateMatch aggiorna anche totalGoals sui giocatori
            final dataService = Provider.of<DataService>(context, listen: false);
            await dataService.updateMatch(widget.match);
            if (mounted) Navigator.pop(context);
          },
          child: const Text('SALVA VOTI, GOL E COMMENTI'),
        ),
      ),
    );
  }
}
