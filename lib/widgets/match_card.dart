import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/match_model.dart';
import '../data/hive_boxes.dart';
import '../screens/match_detail_screen.dart';
import '../services/data_service.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;
  const MatchCard({required this.match, super.key});

  // ── Helpers location ─────────────────────────────────────────

  static const _backgrounds = {
    'SanFrancesco': 'assets/images/campoSanFrancescoColorato.jpg',
    'Montanaso':    'assets/images/montanaso.jpg',
    'Faustina':     'assets/images/faustina.png',
    'Pergola':      'assets/images/laPergola.jpg',
    'Other':        'assets/images/sfondoPalloneGenerico.png',
  };

  static const _locationLabels = {
    'SanFrancesco': 'San Francesco',
    'Montanaso':    'Montanaso',
    'Faustina':     'Faustina Arena',
    'Pergola':      'La Pergola',
    'Other':        'Campo Sportivo',
  };

  String get _bg =>
      _backgrounds[match.fieldLocation] ?? 'assets/images/sfondoPalloneGenerico.png';

  String get _locationLabel =>
      _locationLabels[match.fieldLocation] ?? match.fieldLocation;

  String _playerName(String id) =>
      HiveBoxes.playersBox.get(id)?.name ?? '?';

  // ── Colore risultato ─────────────────────────────────────────

  Color _accentColor() {
    if (match.scoreA > match.scoreB) return const Color(0xFF00E676);
    if (match.scoreB > match.scoreA) return const Color(0xFFFF1744);
    return const Color(0xFFFFD600);
  }

  String _resultLabel() {
    if (match.scoreA > match.scoreB) return 'VITTORIA BIANCHI';
    if (match.scoreB > match.scoreA) return 'VITTORIA COLORATI';
    return 'PAREGGIO';
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEE dd MMM yyyy', 'it_IT').format(match.date);
    final time = DateFormat('HH:mm').format(match.date);
    final teamANames = match.teamA.map(_playerName).join(' · ');
    final teamBNames = match.teamB.map(_playerName).join(' · ');
    final accent = _accentColor();

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
              color: accent.withOpacity(0.22),
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
                backgroundAsset: _bg,
                locationLabel: _locationLabel,
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
                mvp: match.mvp,
                hustle: match.hustlePlayer,
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
  final String backgroundAsset;
  final String locationLabel;
  final String date;
  final String time;

  const _FieldHeader({
    required this.backgroundAsset,
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
          Image.asset(backgroundAsset, fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.82),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Campo
                Row(
                  children: [
                    const Icon(Icons.sports_soccer, color: Colors.white, size: 16),
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
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
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
  final String teamANames;
  final String teamBNames;

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
      color: const Color(0xFF0D0D0D),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Team A (sinistra)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BIANCHI',
                      style: TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      teamANames,
                      style: const TextStyle(color: Color(0xFF555555), fontSize: 10),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Punteggio ENORME al centro
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    _ScoreBox(score: scoreA, accent: accent, isWinner: scoreA > scoreB),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        ':',
                        style: TextStyle(
                          color: accent.withOpacity(0.4),
                          fontSize: 32,
                          fontWeight: FontWeight.w200,
                          height: 1,
                        ),
                      ),
                    ),
                    _ScoreBox(score: scoreB, accent: accent, isWinner: scoreB > scoreA),
                  ],
                ),
              ),

              // Team B (destra)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'COLORATI',
                      style: TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      teamBNames,
                      style: const TextStyle(color: Color(0xFF555555), fontSize: 10),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
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
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: accent.withOpacity(0.35), width: 1),
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
        color: isWinner ? accent.withOpacity(0.13) : const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinner ? accent.withOpacity(0.55) : const Color(0xFF2A2A2A),
          width: isWinner ? 2 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$score',
        style: TextStyle(
          color: isWinner ? accent : const Color(0xFF555555),
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
  final Color accent;
  final MatchModel match;

  const _FooterSection({
    required this.mvp,
    required this.hustle,
    required this.accent,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final hasMvp = mvp.isNotEmpty;
    final hasHustle = hustle.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border(
          top: BorderSide(color: accent.withOpacity(0.18), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          if (hasMvp)
            Expanded(child: _AwardBadge(emoji: '👑', label: 'MVP', name: mvp, color: const Color(0xFFFFD700))),

          if (hasMvp && hasHustle)
            Container(width: 1, height: 34, color: Colors.white10,
                margin: const EdgeInsets.symmetric(horizontal: 10)),

          if (hasHustle)
            Expanded(child: _AwardBadge(emoji: '🔥', label: 'COMBATTIVO', name: hustle, color: const Color(0xFFFF6D00))),

          if (!hasMvp && !hasHustle)
            const Expanded(
              child: Text('Nessun premio assegnato',
                  style: TextStyle(color: Colors.white24, fontSize: 11)),
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
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.25)),
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
                  color: color.withOpacity(0.65),
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
