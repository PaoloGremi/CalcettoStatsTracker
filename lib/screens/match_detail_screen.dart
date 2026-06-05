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
        actions: [
          IconButton(
            tooltip: 'Prima Pagina',
            icon: const Icon(Icons.newspaper_rounded,
                color: AppTheme.accentGold),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MatchNewspaperScreen(match: match),
              ),
            ),
          ),
        ],
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
                        const Text('🥅', style: TextStyle(fontSize: 12)),
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

// ═══════════════════════════════════════════════════════════════
//  📰  MATCH NEWSPAPER SCREEN  ──  stile Gazzetta dello Sport
// ═══════════════════════════════════════════════════════════════

class MatchNewspaperScreen extends StatelessWidget {
  final MatchModel match;
  const MatchNewspaperScreen({required this.match, super.key});

  String _resolveName(String id) {
    if (id.isEmpty) return '';
    return HiveBoxes.playersBox.get(id)?.name ?? id;
  }

  String _resultLabel() {
    if (match.scoreA > match.scoreB) return 'Vittoria Bianchi';
    if (match.scoreB > match.scoreA) return 'Vittoria Colorati';
    return 'Pareggio';
  }

  // Genera un titolone editoriale in base al risultato
  String _headline() {
    final diff = (match.scoreA - match.scoreB).abs();
    if (match.scoreA == match.scoreB) {
      return 'NESSUNO VINCE, NESSUNO PERDE';
    }
    final winner = match.scoreA > match.scoreB ? 'BIANCHI' : 'COLORATI';
    if (diff >= 4) return '$winner DA URLO!';
    if (diff >= 2) return '$winner DOMINANO';
    return '$winner IN RIMONTA';
  }

  String _subheadline() {
    final mvp = _resolveName(match.mvp);
    if (mvp.isNotEmpty) return 'Il trascinatore? $mvp in grande spolvero.';
    return 'Una partita da ricordare.';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMMM yyyy', 'it_IT').format(match.date);
    final timeStr = DateFormat('HH:mm', 'it_IT').format(match.date);
    final mvpName = _resolveName(match.mvp);
    final hustleName = _resolveName(match.hustlePlayer);
    final bestGoalName = _resolveName(match.bestGoalPlayer);

    // Raccogli tutti i giocatori con voto, ordinati decrescente
    final allPlayers = [...match.teamA, ...match.teamB];
    final rated = allPlayers
        .where((id) => (match.votes[id] ?? 0.0) > 0)
        .toList()
      ..sort((a, b) => (match.votes[b] ?? 0)
          .compareTo(match.votes[a] ?? 0));

    // Top scorer (più gol)
    final scorers = allPlayers
        .where((id) => (match.goals[id] ?? 0) > 0)
        .toList()
      ..sort((a, b) =>
          (match.goals[b] ?? 0).compareTo(match.goals[a] ?? 0));

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE0), // carta ingiallita
      appBar: AppBar(
        backgroundColor: const Color(0xFFD40000),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'LA GAZZETTA DEL GOL',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Testata rossa ─────────────────────────────────
            _NewspaperHeader(dateStr: dateStr, timeStr: timeStr),

            // ── Risultato / titolone ──────────────────────────
            _HeadlineBlock(
              scoreA: match.scoreA,
              scoreB: match.scoreB,
              headline: _headline(),
              subheadline: _subheadline(),
              resultLabel: _resultLabel(),
            ),

            // ── Linea decorativa ──────────────────────────────
            _Ornament(),

            // ── Premi ─────────────────────────────────────────
            if (mvpName.isNotEmpty || hustleName.isNotEmpty || bestGoalName.isNotEmpty)
              _AwardsBlock(
                  mvpName: mvpName,
                  hustleName: hustleName,
                  bestGoalName: bestGoalName),

            _Ornament(),

            // ── Colonna marcatori ─────────────────────────────
            if (scorers.isNotEmpty)
              _ScorersBlock(scorers: scorers, match: match),

            // ── Tabellino in due colonne ──────────────────────
            _TwoColumnRatings(
              teamAIds: match.teamA,
              teamBIds: match.teamB,
              match: match,
            ),

            // ── Commenti / Citazioni ──────────────────────────
            _CommentsBlock(allPlayers: allPlayers, match: match),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets del giornale ─────────────────────────────────────

class _NewspaperHeader extends StatelessWidget {
  final String dateStr, timeStr;
  const _NewspaperHeader({required this.dateStr, required this.timeStr});

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFD40000),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(dateStr.toUpperCase(),
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
        const Text('⚽  IL GIORNALE DELLA PARTITA  ⚽',
            style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2)),
        Text('ORE $timeStr',
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
      ],
    ),
  );
}

class _HeadlineBlock extends StatelessWidget {
  final int scoreA, scoreB;
  final String headline, subheadline, resultLabel;
  const _HeadlineBlock({
    required this.scoreA,
    required this.scoreB,
    required this.headline,
    required this.subheadline,
    required this.resultLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isWinA = scoreA > scoreB;
    final isDraw = scoreA == scoreB;
    return Container(
      color: const Color(0xFFF5EFE0),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        children: [
          // Striscia categoria
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFD40000),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(resultLabel.toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2)),
          ),
          const SizedBox(height: 12),
          // Titolone
          Text(headline,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A),
                  height: 1.1,
                  letterSpacing: -0.5)),
          const SizedBox(height: 10),
          // Risultato enorme
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BigScore(scoreA,
                  highlight: isWinA,
                  label: 'BIANCHI'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text('-',
                    style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w200,
                        color: Color(0xFF555555))),
              ),
              _BigScore(scoreB,
                  highlight: !isWinA && !isDraw,
                  label: 'COLORATI'),
            ],
          ),
          const SizedBox(height: 10),
          Text(subheadline,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                  color: Color(0xFF555555))),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _BigScore extends StatelessWidget {
  final int score;
  final bool highlight;
  final String label;
  const _BigScore(this.score, {required this.highlight, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text('$score',
          style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: highlight
                  ? const Color(0xFFD40000)
                  : const Color(0xFF888888),
              height: 1)),
      Text(label,
          style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Color(0xFF888888),
              letterSpacing: 1.5)),
    ],
  );
}

class _Ornament extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Expanded(child: Container(height: 1, color: const Color(0xFF1A1A1A))),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text('✦', style: TextStyle(color: Color(0xFFD40000), fontSize: 14)),
      ),
      Expanded(child: Container(height: 1, color: const Color(0xFF1A1A1A))),
    ]),
  );
}

class _AwardsBlock extends StatelessWidget {
  final String mvpName, hustleName, bestGoalName;
  const _AwardsBlock(
      {required this.mvpName,
      required this.hustleName,
      required this.bestGoalName});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Column(
      children: [
        const Text('I PREMI DELLA SERATA',
            style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Color(0xFF1A1A1A))),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (mvpName.isNotEmpty)
              _AwardTile('👑', 'MVP', mvpName, const Color(0xFFB8860B)),
            if (hustleName.isNotEmpty)
              _AwardTile('🔥', 'COMBATTIVO', hustleName,
                  const Color(0xFFD46000)),
            if (bestGoalName.isNotEmpty)
              _AwardTile('⚽', 'BEST GOAL', bestGoalName,
                  const Color(0xFF2E7D32)),
          ],
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}

class _AwardTile extends StatelessWidget {
  final String emoji, label, name;
  final Color color;
  const _AwardTile(this.emoji, this.label, this.name, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 26)),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: color)),
      Text(name.toUpperCase(),
          style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1A1A1A))),
    ],
  );
}

class _ScorersBlock extends StatelessWidget {
  final List<String> scorers;
  final MatchModel match;
  const _ScorersBlock({required this.scorers, required this.match});

  String _name(String id) =>
      HiveBoxes.playersBox.get(id)?.name ?? id;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Column(
      children: [
        const Text('MARCATORI',
            style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Color(0xFF1A1A1A))),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: scorers.map((id) {
            final g = match.goals[id] ?? 0;
            return RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 13,
                    color: Color(0xFF1A1A1A)),
                children: [
                  TextSpan(
                      text: _name(id).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  TextSpan(
                      text: ' ${'⚽' * g}',
                      style: const TextStyle(fontSize: 11)),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}

class _TwoColumnRatings extends StatelessWidget {
  final List<String> teamAIds, teamBIds;
  final MatchModel match;
  const _TwoColumnRatings(
      {required this.teamAIds,
      required this.teamBIds,
      required this.match});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          // Intestazione colonne
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text('BIANCHI',
                        style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            fontSize: 11,
                            color: Color(0xFF1A1A1A))),
                  ),
                ),
                Container(width: 1, height: 20, color: const Color(0xFF1A1A1A)),
                Expanded(
                  child: Center(
                    child: Text('COLORATI',
                        style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            fontSize: 11,
                            color: Color(0xFF1A1A1A))),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFF1A1A1A)),
          const SizedBox(height: 6),
          // Righe giocatori affiancate
          ...List.generate(
            [teamAIds.length, teamBIds.length].reduce((a, b) => a > b ? a : b),
            (i) {
              final idA = i < teamAIds.length ? teamAIds[i] : null;
              final idB = i < teamBIds.length ? teamBIds[i] : null;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                        child: idA != null
                            ? _RatingRow(idA, match, alignRight: false)
                            : const SizedBox()),
                    Container(
                        width: 1,
                        height: 26,
                        color: const Color(0xFFCCBB99)),
                    Expanded(
                        child: idB != null
                            ? _RatingRow(idB, match, alignRight: true)
                            : const SizedBox()),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final String playerId;
  final MatchModel match;
  final bool alignRight;
  const _RatingRow(this.playerId, this.match, {required this.alignRight});

  Color _voteColor(double v) {
    if (v >= 8) return const Color(0xFF2E7D32);
    if (v >= 6.5) return const Color(0xFFB8860B);
    if (v >= 5) return const Color(0xFFD46000);
    return const Color(0xFFD40000);
  }

  @override
  Widget build(BuildContext context) {
    final player = HiveBoxes.playersBox.get(playerId);
    final name = player?.name ?? 'Sconosciuto';
    final voto = match.votes[playerId] ?? 0.0;
    final goals = match.goals[playerId] ?? 0;
    final color = _voteColor(voto);
    final isMvp = match.mvp == playerId;

    final nameWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isMvp && !alignRight)
          const Text('👑 ', style: TextStyle(fontSize: 10)),
        Flexible(
          child: Text(name.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: Color(0xFF1A1A1A))),
        ),
        if (goals > 0)
          Text(' ${'⚽' * goals.clamp(0, 3)}',
              style: const TextStyle(fontSize: 9)),
        if (isMvp && alignRight)
          const Text(' 👑', style: TextStyle(fontSize: 10)),
      ],
    );

    final scoreWidget = voto > 0
        ? Container(
            width: 28,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(voto.toStringAsFixed(1),
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900)),
          )
        : const SizedBox(width: 28);

    return Padding(
      padding: EdgeInsets.only(
          left: alignRight ? 8 : 4, right: alignRight ? 4 : 8),
      child: Row(
        mainAxisAlignment: alignRight
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.spaceBetween,
        children: alignRight
            ? [scoreWidget, const SizedBox(width: 6), Expanded(child: nameWidget)]
            : [Expanded(child: nameWidget), const SizedBox(width: 6), scoreWidget],
      ),
    );
  }
}

class _CommentsBlock extends StatelessWidget {
  final List<String> allPlayers;
  final MatchModel match;
  const _CommentsBlock(
      {required this.allPlayers, required this.match});

  @override
  Widget build(BuildContext context) {
    final withComments = allPlayers
        .where((id) => (match.comments[id] ?? '').isNotEmpty)
        .toList();

    if (withComments.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Ornament(),
          const SizedBox(height: 6),
          const Center(
            child: Text('LE VOCI DELLO SPOGLIATOIO',
                style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Color(0xFF1A1A1A))),
          ),
          const SizedBox(height: 12),
          ...withComments.map((id) {
            final player = HiveBoxes.playersBox.get(id);
            final name = player?.name ?? id;
            final comment = match.comments[id]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('«$comment»',
                      style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                          color: Color(0xFF333333),
                          height: 1.4)),
                  const SizedBox(height: 4),
                  Text('— ${name.toUpperCase()}',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Color(0xFFD40000))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
