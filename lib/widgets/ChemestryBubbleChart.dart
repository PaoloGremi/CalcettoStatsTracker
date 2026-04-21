// ─────────────────────────────────────────────────────────────
// Chemistry Bubble Chart
// ─────────────────────────────────────────────────────────────

import 'package:calcetto_tracker/data/hive_boxes.dart';
import 'package:calcetto_tracker/models/match_model.dart';
import 'package:calcetto_tracker/models/player.dart';
import 'package:calcetto_tracker/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ChemistryBubbleChart extends StatefulWidget {
  final List<MatchModel> matches;
  final Player player;

  const ChemistryBubbleChart({
    required this.matches,
    required this.player,
  });

  @override
  State<ChemistryBubbleChart> createState() => ChemistryBubbleChartState();
}

class ChemistryBubbleChartState extends State<ChemistryBubbleChart> {
  String? _tappedId;

  // Calcola i dati chemistry per ogni compagno di squadra
  List<_ChemistryData> _computeChemistry() {
    final playerId = widget.player.id;
    final allPlayers = HiveBoxes.playersBox.values.toList();

    // mappa playerId -> dati aggregati
    final data = <String, _ChemistryData>{};

    for (final m in widget.matches) {
      // Determina se il giocatore è in teamA o teamB
      final inTeamA = m.teamA.contains(playerId);
      final inTeamB = m.teamB.contains(playerId);
      if (!inTeamA && !inTeamB) continue;

      final teammates = inTeamA ? m.teamA : m.teamB;
      final playerScore = inTeamA ? m.scoreA : m.scoreB;
      final oppScore = inTeamA ? m.scoreB : m.scoreA;

      final isWin = playerScore > oppScore;
      final isDraw = playerScore == oppScore;

      // Gol del giocatore selezionato in questa partita
      final myGoals = m.goals[playerId] ?? 0;
      // Gol subiti (avversari)
      final conceded = inTeamA ? m.scoreB : m.scoreA;

      for (final tid in teammates) {
        if (tid == playerId) continue;
        data.putIfAbsent(tid, () => _ChemistryData(playerId: tid));
        final c = data[tid]!;
        c.games++;
        if (isWin) c.wins++;
        if (isDraw) c.draws++;
        c.goalsFor += myGoals;
        c.goalsConceded += conceded;
      }
    }

    // Arricchisci con il nome del giocatore
    final result = <_ChemistryData>[];
    for (final entry in data.values) {
      if (entry.games == 0) continue;
      final p = HiveBoxes.playersBox.get(entry.playerId);
      if (p == null) continue;
      entry.name = p.name;
      entry.role = p.role;
      result.add(entry);
    }

    // Ordina per games decrescente (bolle più a destra = più esperienza insieme)
    result.sort((a, b) => b.games.compareTo(a.games));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final chemData = _computeChemistry();

    if (chemData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Center(
          child: Text(
            'Nessun dato disponibile.\nServono partite con compagni in comune.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final maxGames =
        chemData.map((d) => d.games).reduce((a, b) => a > b ? a : b);
    final maxGoals =
        chemData.map((d) => d.goalsFor).reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // ── Legenda assi ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _AxisLabel('← meno partite insieme   più partite →',
                    color: AppTheme.textMuted),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: Row(
              children: [
                _AxisLabel('↑ % vittorie', color: AppTheme.textMuted),
                const Spacer(),
                // Legenda dimensione bolla
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('gol fatti',
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                    const SizedBox(width: 10),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.accentRed.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('gol subiti',
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),

          // ── Canvas bolle ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: SizedBox(
              height: 280,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return _BubbleCanvas(
                    data: chemData,
                    maxGames: maxGames,
                    maxGoals: maxGoals > 0 ? maxGoals : 1,
                    width: constraints.maxWidth,
                    height: 280,
                    tappedId: _tappedId,
                    onTap: (id) => setState(() {
                      _tappedId = _tappedId == id ? null : id;
                    }),
                  );
                },
              ),
            ),
          ),

          // ── Tooltip giocatore selezionato ──────────────────
          if (_tappedId != null) ...[
            const Divider(height: 1, color: AppTheme.border),
            _buildTooltip(chemData.firstWhere((d) => d.playerId == _tappedId,
                orElse: () => chemData.first)),
          ],

          // ── Nota tap ───────────────────────────────────────
          if (_tappedId == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Tocca una bolla per vedere i dettagli',
                style: TextStyle(
                    color: AppTheme.textMuted.withOpacity(0.6), fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTooltip(_ChemistryData d) {
    final winPct = d.games > 0 ? (d.wins / d.games * 100).round() : 0;
    final drawPct = d.games > 0 ? (d.draws / d.games * 100).round() : 0;
    final lossPct = 100 - winPct - drawPct;
    final roleColor = switch (d.role) {
      'P' => AppTheme.accentGold,
      'D' => AppTheme.accentBlue,
      'C' => AppTheme.accentGreen,
      'A' => AppTheme.accentRed,
      _ => AppTheme.textMuted,
    };

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Nome + ruolo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FifaBadge(d.role, color: roleColor),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        d.name.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${d.games} partite insieme',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          // Stats V/P/S
          _TooltipStat(
              label: 'VINTE',
              value: '${d.wins}',
              sub: '$winPct%',
              color: AppTheme.accentGreen),
          const SizedBox(width: 10),
          _TooltipStat(
              label: 'PARI',
              value: '${d.draws}',
              sub: '$drawPct%',
              color: AppTheme.accentGold),
          const SizedBox(width: 10),
          _TooltipStat(
              label: 'PERSE',
              value: '${d.games - d.wins - d.draws}',
              sub: '$lossPct%',
              color: AppTheme.accentRed),
          const SizedBox(width: 10),
          _TooltipStat(
              label: 'GOL F.',
              value: '${d.goalsFor}',
              sub: '',
              color: AppTheme.accentGreen),
          const SizedBox(width: 10),
          _TooltipStat(
              label: 'GOL S.',
              value: '${d.goalsConceded}',
              sub: '',
              color: AppTheme.accentRed),
        ],
      ),
    );
  }
}

// ── Canvas personalizzato per le bolle ────────────────────────

class _BubbleCanvas extends StatefulWidget {
  final List<_ChemistryData> data;
  final int maxGames;
  final int maxGoals;
  final double width;
  final double height;
  final String? tappedId;
  final ValueChanged<String> onTap;

  const _BubbleCanvas({
    required this.data,
    required this.maxGames,
    required this.maxGoals,
    required this.width,
    required this.height,
    required this.tappedId,
    required this.onTap,
  });

  static const double _padL = 32;
  static const double _padR = 16;
  static const double _padT = 12;
  static const double _padB = 24;

  @override
  State<_BubbleCanvas> createState() => _BubbleCanvasState();
}

class _BubbleCanvasState extends State<_BubbleCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Map<String, Offset> _centers;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _computeCenters();
  }

  @override
  void didUpdateWidget(covariant _BubbleCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.data != widget.data) {
      _computeCenters(); // 🔥 importante: non ricalcolare ogni frame
    }

    if (oldWidget.tappedId != widget.tappedId) {
      _controller.forward(from: 0);
    }
  }

  void _computeCenters() {
    final centers = <String, Offset>{};
    final placed = <Offset>[];

    final plotW = widget.width - _BubbleCanvas._padL - _BubbleCanvas._padR;
    final plotH = widget.height - _BubbleCanvas._padT - _BubbleCanvas._padB;

    for (final d in widget.data) {
      final x = _BubbleCanvas._padL + (d.games / widget.maxGames) * plotW;

      final winRate = d.games > 0 ? d.wins / d.games : 0.0;
      final y = _BubbleCanvas._padT + (1.0 - winRate) * plotH;

      Offset pos = Offset(x, y);

      // Anti-overlap stabile
      for (final other in placed) {
        if ((pos - other).distance < 32) {
          pos = pos.translate(8, -8);
        }
      }

      placed.add(pos);
      centers[d.playerId] = pos;
    }

    _centers = centers;
  }

  double _bubbleRadius(_ChemistryData d) {
    final goalFraction = d.goalsFor / widget.maxGoals;
    return 6 + goalFraction * 14;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return GestureDetector(
          onTapDown: (details) {
            final pos = details.localPosition;

            for (final d in widget.data) {
              final center = _centers[d.playerId]!;
              final r = _bubbleRadius(d);

              if ((pos - center).distance <= r + 6) {
                widget.onTap(d.playerId);
                return;
              }
            }

            widget.onTap('');
          },
          child: CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _BubblePainter(
              data: widget.data,
              centers: _centers,
              tappedId: widget.tappedId,
              animationValue: _controller.value,
              bubbleRadius: _bubbleRadius,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

@override
class _BubblePainter extends CustomPainter {
  final List<_ChemistryData> data;
  final String? tappedId;
  final double Function(_ChemistryData) bubbleRadius;
  final double animationValue;
  final Map<String, Offset> centers;

  _BubblePainter({
    required this.data,
    required this.centers,
    required this.tappedId,
    required this.animationValue,
    required this.bubbleRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padL = _BubbleCanvas._padL;
    const padR = _BubbleCanvas._padR;
    const padT = _BubbleCanvas._padT;
    const padB = _BubbleCanvas._padB;

    final plotW = size.width - padL - padR;
    final plotH = size.height - padT - padB;

    final gridPaint = Paint()
      ..color = AppTheme.border.withOpacity(0.5)
      ..strokeWidth = 0.8;

    // Griglia orizzontale
    for (int pct in [0, 25, 50, 75, 100]) {
      final y = padT + (1 - pct / 100) * plotH;
      canvas.drawLine(Offset(padL, y), Offset(size.width - padR, y), gridPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: '$pct%',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(0, y - 5));
    }

    // Linea 50%
    final midPaint = Paint()
      ..color = AppTheme.accentGold.withOpacity(0.3)
      ..strokeWidth = 1.5;

    final midY = padT + 0.5 * plotH;
    canvas.drawLine(
        Offset(padL, midY), Offset(size.width - padR, midY), midPaint);

    // ── Bolle ──
    for (final d in data) {
      final center = centers[d.playerId]!;
      final baseR = bubbleRadius(d);
      final isTapped = d.playerId == tappedId;
// Raggio animato
      final r = isTapped
          ? baseR + 6 * Curves.easeOutBack.transform(animationValue)
          : baseR;

// Opacità dinamica
      final opacity = isTapped ? 0.25 + 0.30 * animationValue : 0.25;

      // Colore
      final winRate = d.games > 0 ? d.wins / d.games : 0.0;
      final Color baseColor = winRate >= 0.6
          ? AppTheme.accentGreen
          : winRate >= 0.4
              ? AppTheme.accentGold
              : AppTheme.accentRed;

      // Fill (animato)
      canvas.drawCircle(
        center,
        r,
        Paint()..color = baseColor.withOpacity(opacity),
      );

      // Border animato
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = isTapped ? baseColor : baseColor.withOpacity(0.6)
          ..strokeWidth = isTapped ? 1.5 + 1.5 * animationValue : 1.5
          ..style = PaintingStyle.stroke,
      );
// Glow animato
      if (isTapped) {
        canvas.drawCircle(
          center,
          r + 10 * animationValue,
          Paint()
            ..color = baseColor.withOpacity(0.25 * animationValue)
            ..style = PaintingStyle.fill,
        );
      }
      // Testo interno
      if (r >= 10 || isTapped) {
        final text =
            isTapped ? d.name.split(' ').first : d.name[0].toUpperCase();

        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: isTapped ? Colors.white : baseColor,
              fontSize: isTapped ? 9 : 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: r * 2);

        tp.paint(
          canvas,
          center - Offset(tp.width / 2, tp.height / 2),
        );
      }

      // Label sotto (NUOVO)
      final shortName = d.name.length > 4
          ? d.name.substring(0, 4).toUpperCase()
          : d.name.toUpperCase();

      final labelTp = TextPainter(
        text: TextSpan(
          text: shortName,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      labelTp.paint(
        canvas,
        center + Offset(-labelTp.width / 2, r + 2),
      );

      // Glow selezione
      if (isTapped) {
        canvas.drawCircle(
          center,
          r + 6,
          Paint()
            ..color = baseColor.withOpacity(0.25)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.tappedId != tappedId ||
      old.data != data ||
      old.animationValue != animationValue;
}
// ── Data class ────────────────────────────────────────────────

class _ChemistryData {
  final String playerId;
  String name = '';
  String role = '';
  int games = 0;
  int wins = 0;
  int draws = 0;
  int goalsFor = 0;
  int goalsConceded = 0;

  _ChemistryData({required this.playerId});
}

// ── Widget ausiliari tooltip ───────────────────────────────────

class _TooltipStat extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _TooltipStat({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 15, fontWeight: FontWeight.w900)),
          if (sub.isNotEmpty)
            Text(sub,
                style: TextStyle(
                    color: color.withOpacity(0.6),
                    fontSize: 9,
                    fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w600)),
        ],
      );
}

class _AxisLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _AxisLabel(this.text, {required this.color});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(color: color, fontSize: 9),
      );
}
