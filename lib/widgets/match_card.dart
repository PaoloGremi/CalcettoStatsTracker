import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/util/date_formatters.dart';
import '../core/util/player_lookup.dart';
import '../models/match_model.dart';
import '../models/field_model.dart';
import '../screens/match_detail_screen.dart';
import '../screens/edit_match_screen.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;
  const MatchCard({required this.match, super.key});

  // ── Helpers ──────────────────────────────────────────────────

  /// Ritorna il FieldModel corrispondente a match.fieldLocation (che è l'ID).
  FieldModel? _field(BuildContext context) =>
      Provider.of<DataService>(context, listen: false)
          .getFieldById(match.fieldLocation);

  String _locationLabel(BuildContext context) {
    final f = _field(context);
    if (f != null) return f.name;
    return match.fieldLocation == 'Other' ? 'Campo Sportivo' : match.fieldLocation;
  }

  /// Ritorna null se si deve usare l'asset di fallback, altrimenti il path del file.
  String? _fieldImageFilePath(BuildContext context) {
    final f = _field(context);
    if (f != null && f.imagePath != null && File(f.imagePath!).existsSync()) {
      return f.imagePath;
    }
    return null;
  }

  String get _legacyAsset => 'assets/images/sfondoPalloneGenerico.png';

  String _playerName(String id) => resolvePlayerName(id, fallback: '?');

  // ── Colore risultato ─────────────────────────────────────────

  Color _accentColor() {
    if (match.scoreA > match.scoreB) return AppTheme.accentGreen;
    if (match.scoreB > match.scoreA) return AppTheme.accentRed;
    return AppTheme.accentGold;
  }

  String _resultLabel() {
    if (match.scoreA > match.scoreB) return 'VITTORIA BIANCHI';
    if (match.scoreB > match.scoreA) return 'VITTORIA COLORATI';
    return 'PAREGGIO';
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEE dd MMM yyyy', 'it_IT').format(match.date);
    final time = formatTime(match.date);
    final teamANames = match.teamA.map(_playerName).toList();
    final teamBNames = match.teamB.map(_playerName).toList();
    final accent = _accentColor();
    final mvpName = resolvePlayerName(match.mvp);
    final hustleName = resolvePlayerName(match.hustlePlayer);
    final bestGoalName = resolvePlayerName(match.bestGoalPlayer);

    final fieldImagePath = _fieldImageFilePath(context);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MatchDetailScreen(match: match)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.22),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // ── ZONA 1: Header campo ───────────────────────────
              _FieldHeader(
                fieldImagePath: fieldImagePath,
                fallbackAsset: _legacyAsset,
                locationLabel: _locationLabel(context),
                date: date,
                time: time,
              ),

              // ── ZONA 2: Punteggio ──────────────────────────────
              _ScoreSection(
                scoreA: match.scoreA,
                scoreB: match.scoreB,
                accent: accent,
                resultLabel: _resultLabel(),
                teamANames: teamANames,
                teamBNames: teamBNames,
              ),

              // ── ZONA 3: Footer premi + elimina ────────────────
              _FooterSection(
                mvp: mvpName,
                hustle: hustleName,
                bestGoal: bestGoalName,
                accent: accent,
                match: match,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ZONA 1 — Header campo
// ─────────────────────────────────────────────────────────────

class _FieldHeader extends StatelessWidget {
  /// Path file locale (da FieldModel). Null se non disponibile.
  final String? fieldImagePath;

  /// Asset di fallback (vecchi campi hardcoded o generico).
  final String fallbackAsset;
  final String locationLabel;
  final String date;
  final String time;

  const _FieldHeader({
    required this.fieldImagePath,
    required this.fallbackAsset,
    required this.locationLabel,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Sfondo: foto campo da file o asset legacy
          fieldImagePath != null
              ? Image.file(File(fieldImagePath!), fit: BoxFit.cover)
              : Image.asset(fallbackAsset, fit: BoxFit.cover),

          // Overlay scurito
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.82),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Nome campo
                Row(
                  children: [
                    const Icon(Icons.sports_soccer,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      locationLabel.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Data + ora
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      date.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '⏰  $time',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ZONA 2 — Punteggio
// ─────────────────────────────────────────────────────────────

class _ScoreSection extends StatelessWidget {
  final int scoreA;
  final int scoreB;
  final Color accent;
  final String resultLabel;
  final List<String> teamANames;
  final List<String> teamBNames;

  const _ScoreSection({
    required this.scoreA,
    required this.scoreB,
    required this.accent,
    required this.resultLabel,
    required this.teamANames,
    required this.teamBNames,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Team A (sinistra) — nomi uno sotto l'altro
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BIANCHI',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...teamANames.map((name) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            name.toUpperCase(),
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  ],
                ),
              ),

              // Punteggio al centro
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    _ScoreBox(
                        score: scoreA,
                        accent: accent,
                        isWinner: scoreA > scoreB),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        ':',
                        style: TextStyle(
                          color: accent.withValues(alpha: 0.4),
                          fontSize: 32,
                          fontWeight: FontWeight.w200,
                          height: 1,
                        ),
                      ),
                    ),
                    _ScoreBox(
                        score: scoreB,
                        accent: accent,
                        isWinner: scoreB > scoreA),
                  ],
                ),
              ),

              // Team B (destra) — nomi uno sotto l'altro allineati a destra
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'COLORATI',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...teamBNames.map((name) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            name.toUpperCase(),
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Badge risultato
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
              border:
                  Border.all(color: accent.withValues(alpha: 0.35), width: 1),
            ),
            child: Text(
              resultLabel,
              style: TextStyle(
                color: accent,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final int score;
  final Color accent;
  final bool isWinner;

  const _ScoreBox({
    required this.score,
    required this.accent,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: isWinner ? accent.withValues(alpha: 0.13) : AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinner ? accent.withValues(alpha: 0.55) : AppTheme.border,
          width: isWinner ? 2 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$score',
        style: TextStyle(
          color: isWinner ? accent : AppTheme.textMuted,
          fontSize: 36,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ZONA 3 — Footer premi + elimina
// ─────────────────────────────────────────────────────────────

class _FooterSection extends StatelessWidget {
  final String mvp;
  final String hustle;
  final String bestGoal;
  final Color accent;
  final MatchModel match;

  const _FooterSection({
    required this.mvp,
    required this.hustle,
    required this.bestGoal,
    required this.accent,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final hasMvp = mvp.isNotEmpty;
    final hasHustle = hustle.isNotEmpty;
    final hasBestGoal = bestGoal.isNotEmpty;
    final hasAny = hasMvp || hasHustle || hasBestGoal;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        border: Border(
          top: BorderSide(color: accent.withValues(alpha: 0.18), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          if (hasMvp)
            Expanded(
                child: _AwardBadge(
                    emoji: '👑',
                    label: 'MVP',
                    name: mvp,
                    color: AppTheme.accentGold)),

          if (hasMvp && (hasHustle || hasBestGoal))
            Container(
                width: 1,
                height: 34,
                color: AppTheme.border,
                margin: const EdgeInsets.symmetric(horizontal: 8)),

          if (hasHustle)
            Expanded(
                child: _AwardBadge(
                    emoji: '🔥',
                    label: 'COMBATTIVO',
                    name: hustle,
                    color: AppTheme.accentOrange)),

          if (hasHustle && hasBestGoal)
            Container(
                width: 1,
                height: 34,
                color: AppTheme.border,
                margin: const EdgeInsets.symmetric(horizontal: 8)),

          if (hasBestGoal)
            Expanded(
                child: _AwardBadge(
                    emoji: '⚽',
                    label: 'BEST GOAL',
                    name: bestGoal,
                    color: AppTheme.accentGreen)),

          if (!hasAny)
            Expanded(
              child: Text('Nessun premio assegnato',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ),

          const SizedBox(width: 8),

          // Bottone modifica
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditMatchScreen(match: match)),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
              ),
              child:
                  const Icon(Icons.edit_rounded, color: Colors.amber, size: 20),
            ),
          ),

          const SizedBox(width: 8),

          // Bottone elimina
          GestureDetector(
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Elimina partita?'),
                  content: const Text('Vuoi eliminare questa partita?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('No')),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sì')),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                final data = Provider.of<DataService>(context, listen: false);
                await data.deleteMatch(match.id);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Badge premio (MVP / Combattivo)
// ─────────────────────────────────────────────────────────────

class _AwardBadge extends StatelessWidget {
  final String emoji;
  final String label;
  final String name;
  final Color color;

  const _AwardBadge({
    required this.emoji,
    required this.label,
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.65),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
              Text(
                name,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
