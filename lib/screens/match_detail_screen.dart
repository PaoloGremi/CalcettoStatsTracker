import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/match_model.dart';
import '../data/hive_boxes.dart';
import '../widgets/player_avatar.dart';
import '../theme/app_theme.dart';

class MatchDetailScreen extends StatelessWidget {
  final MatchModel match;
  const MatchDetailScreen({required this.match, super.key});

  Color _voteColor(double v) {
    if (v >= 8) return AppTheme.accentGreen;
    if (v >= 6.5) return AppTheme.accentGold;
    if (v >= 5) return AppTheme.accentOrange;
    return AppTheme.accentRed;
  }

  Color _resultAccent() {
    if (match.scoreA > match.scoreB) return AppTheme.accentGreen;
    if (match.scoreB > match.scoreA) return AppTheme.accentRed;
    return AppTheme.accentGold;
  }

  String _resultLabel() {
    if (match.scoreA > match.scoreB) return 'Vittoria Bianchi';
    if (match.scoreB > match.scoreA) return 'Vittoria Colorati';
    return 'Pareggio';
  }

  String _resolveName(String playerId) {
    if (playerId.isEmpty) return '';
    return HiveBoxes.playersBox.get(playerId)?.name ?? playerId;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _resultAccent();
    final date = DateFormat('EEEE dd MMMM yyyy · HH:mm', 'it_IT')
        .format(match.date);
    final mvpName = _resolveName(match.mvp);
    final hustleName = _resolveName(match.hustlePlayer);
    final bestGoalName = _resolveName(match.bestGoalPlayer);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const FifaLabel('Dettaglio Partita',
            color: AppTheme.textPrimary, fontSize: 13),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Scoreboard ────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                    color: accent.withOpacity(0.12), blurRadius: 20)
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                FifaLabel(date, color: AppTheme.textSecondary),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ScoreBox(match.scoreA, accent,
                        match.scoreA > match.scoreB),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(':',
                        style: TextStyle(
                            color: accent.withOpacity(0.4),
                            fontSize: 36,
                            fontWeight: FontWeight.w200)),
                    ),
                    _ScoreBox(match.scoreB, accent,
                        match.scoreB > match.scoreA),
                  ],
                ),
                const SizedBox(height: 14),
                FifaBadge(_resultLabel(), color: accent),

                // Premi
                if (mvpName.isNotEmpty || hustleName.isNotEmpty || bestGoalName.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(height: 1, color: AppTheme.border),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (mvpName.isNotEmpty)
                        _AwardChip('👑', 'MVP', mvpName, AppTheme.accentGold),
                      if (hustleName.isNotEmpty)
                        _AwardChip('🔥', 'COMBATTIVO', hustleName, AppTheme.accentOrange),
                      if (bestGoalName.isNotEmpty)
                        _AwardChip('⚽', 'BEST GOAL', bestGoalName, AppTheme.accentGreen),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Team A ────────────────────────────────────────────
          const FifaSectionHeader('Squadra Bianca',
              accent: AppTheme.accentBlue),
          ...match.teamA.map((id) => _PlayerDetailTile(
              playerId: id, match: match, voteColor: _voteColor)),

          // ── Team B ────────────────────────────────────────────
          const FifaSectionHeader('Squadra Colorata',
              accent: AppTheme.accentOrange),
          ...match.teamB.map((id) => _PlayerDetailTile(
              playerId: id, match: match, voteColor: _voteColor)),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final int score;
  final Color accent;
  final bool isWinner;
  const _ScoreBox(this.score, this.accent, this.isWinner);

  @override
  Widget build(BuildContext context) => Container(
    width: 70, height: 70,
    decoration: BoxDecoration(
      color: isWinner
          ? accent.withOpacity(0.12)
          : AppTheme.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isWinner
            ? accent.withOpacity(0.55)
            : AppTheme.border,
        width: isWinner ? 2 : 1,
      ),
    ),
    alignment: Alignment.center,
    child: Text('$score',
      style: TextStyle(
        color: isWinner ? accent : AppTheme.textMuted,
        fontSize: 40,
        fontWeight: FontWeight.w900,
        height: 1,
      ),
    ),
  );
}

class _AwardChip extends StatelessWidget {
  final String emoji, label, name;
  final Color color;
  const _AwardChip(this.emoji, this.label, this.name, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(height: 4),
      FifaLabel(label, color: color.withOpacity(0.6), fontSize: 9),
      Text(name,
        style: TextStyle(
            color: color, fontSize: 13, fontWeight: FontWeight.w800)),
    ],
  );
}

class _PlayerDetailTile extends StatelessWidget {
  final String playerId;
  final MatchModel match;
  final Color Function(double) voteColor;
  const _PlayerDetailTile(
      {required this.playerId,
      required this.match,
      required this.voteColor});

  @override
  Widget build(BuildContext context) {
    final player = HiveBoxes.playersBox.get(playerId);
    final name = player?.name ?? 'Sconosciuto';
    final role = player?.role ?? '';
    final voto = match.votes[playerId] ?? 0.0;
    final commento = match.comments[playerId] ?? '';
    final goals = match.goals[playerId] ?? 0; // ✅
    final accent = voteColor(voto);
    final isMvp = match.mvp == playerId;
    final isHustle = match.hustlePlayer == playerId;
    final isBestGoal = match.bestGoalPlayer == playerId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMvp
              ? AppTheme.accentGold.withOpacity(0.4)
              : isHustle
                  ? AppTheme.accentOrange.withOpacity(0.4)
                  : isBestGoal
                      ? AppTheme.accentGreen.withOpacity(0.4)
                      : AppTheme.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            if (player != null)
              PlayerAvatar(player: player, radius: 22)
            else
              const CircleAvatar(
                  radius: 22, child: Icon(Icons.person)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name.toUpperCase(),
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2)),
                      const SizedBox(width: 6),
                      FifaBadge(role, color: AppTheme.accentBlue),
                      if (isMvp) ...[
                        const SizedBox(width: 4),
                        const Text('👑', style: TextStyle(fontSize: 14)),
                      ],
                      if (isHustle) ...[
                        const SizedBox(width: 4),
                        const Text('🔥', style: TextStyle(fontSize: 14)),
                      ],
                      if (isBestGoal) ...[
                        const SizedBox(width: 4),
                        const Text('⚽', style: TextStyle(fontSize: 14)),
                      ],
                    ],
                  ),
                  // ✅ Gol segnati in questa partita
                  if (goals > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('⚽', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          goals == 1 ? '1 gol' : '$goals gol',
                          style: const TextStyle(
                            color: AppTheme.accentGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (commento.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('"$commento"',
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (voto > 0)
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: accent.withOpacity(0.4), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(voto.toStringAsFixed(1),
                  style: TextStyle(
                      color: accent,
                      fontSize: 17,
                      fontWeight: FontWeight.w900)),
              ),
          ],
        ),
      ),
    );
  }
}
