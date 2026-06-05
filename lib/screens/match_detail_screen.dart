import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
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
            onPressed: () => _showGenerationMenu(context),
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
  void _showGenerationMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: FifaLabel(
                  'Scegli il formato della Prima Pagina',
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.article_rounded, color: AppTheme.accentGold, size: 28),
                title: const Text(
                  'Cronaca Testuale AI',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Genera il testo in stile Gazzetta dello Sport',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                onTap: () {
                  Navigator.pop(context); // Chiude il bottom sheet
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MatchNewspaperScreen(match: match),
                    ),
                  );
                },
              ),
              const Divider(color: AppTheme.border, height: 20),
              ListTile(
                leading: const Icon(Icons.image_rounded, color: AppTheme.accentGreen, size: 28),
                title: const Text(
                  'Copertina Illustrata AI',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Genera una vignetta/immagine epica della partita',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                onTap: () {
                  Navigator.pop(context); // Chiude il bottom sheet
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MatchImageGenerationScreen(match: match),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
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

/// Contenuto testuale generato dall'AI (o dal fallback statico).
class _NewspaperContent {
  final String headline;
  final String subheadline;
  final String articleBody; // paragrafo principale stile cronaca
  final bool isAiGenerated;
  const _NewspaperContent({
    required this.headline,
    required this.subheadline,
    required this.articleBody,
    required this.isAiGenerated,
  });
}

class MatchNewspaperScreen extends StatefulWidget {
  final MatchModel match;
  const MatchNewspaperScreen({required this.match, super.key});

  @override
  State<MatchNewspaperScreen> createState() => _MatchNewspaperScreenState();
}

class _MatchNewspaperScreenState extends State<MatchNewspaperScreen> {
  static const _storage = FlutterSecureStorage();
  static const _storageKey = 'openai_api_key';

  _NewspaperContent? _content;
  bool _loading = true;
  String? _errorMsg;

  // ── helpers ──────────────────────────────────────────────────

  String _resolveName(String id) {
    if (id.isEmpty) return '';
    return HiveBoxes.playersBox.get(id)?.name ?? id;
  }

  String _resultLabel() {
    if (widget.match.scoreA > widget.match.scoreB) return 'Vittoria Bianchi';
    if (widget.match.scoreB > widget.match.scoreA) return 'Vittoria Colorati';
    return 'Pareggio';
  }

  // Fallback statico (nessuna chiave API)
  _NewspaperContent _staticContent() {
    final diff = (widget.match.scoreA - widget.match.scoreB).abs();
    final mvp = _resolveName(widget.match.mvp);
    String headline;
    if (widget.match.scoreA == widget.match.scoreB) {
      headline = 'NESSUNO VINCE, NESSUNO PERDE';
    } else {
      final winner = widget.match.scoreA > widget.match.scoreB ? 'BIANCHI' : 'COLORATI';
      if (diff >= 4) {
        headline = '$winner DA URLO!';
      } else if (diff >= 2) {
        headline = '$winner DOMINANO';
      } else {
        headline = '$winner IN RIMONTA';
      }
    }
    final sub = mvp.isNotEmpty
        ? 'Il trascinatore? $mvp in grande spolvero.'
        : 'Una partita da ricordare.';
    return _NewspaperContent(
      headline: headline,
      subheadline: sub,
      articleBody: '',
      isAiGenerated: false,
    );
  }

  // Costruisce il prompt con tutti i dati della partita
  String _buildPrompt() {
    final m = widget.match;
    final allPlayers = [...m.teamA, ...m.teamB];

    String teamSection(List<String> ids, String teamName) {
      return ids.map((id) {
        final name = _resolveName(id);
        final voto = m.votes[id] ?? 0.0;
        final gol = m.goals[id] ?? 0;
        final commento = m.comments[id] ?? '';
        final isMvp = m.mvp == id ? ' [MVP]' : '';
        final isHustle = m.hustlePlayer == id ? ' [COMBATTIVO]' : '';
        final isBG = m.bestGoalPlayer == id ? ' [BEST GOAL]' : '';
        return '  - $name$isMvp$isHustle$isBG: voto ${voto > 0 ? voto.toStringAsFixed(1) : 'N/D'}'
            '${gol > 0 ? ', $gol gol' : ''}'
            '${commento.isNotEmpty ? ', nota: "$commento"' : ''}';
      }).join('\n');
    }

    return '''
Sei il cronista de "La Gazzetta del Calcetto", il giornale satirico e appassionato di una partitella di calcetto tra amici.
Scrivi in stile Gazzetta dello Sport: drammatico, colorito, con metafore calcistiche, aggettivi forti.

DATI PARTITA:
- Data: ${DateFormat('dd MMMM yyyy · HH:mm', 'it_IT').format(m.date)}
- Risultato: Bianchi ${m.scoreA} – ${m.scoreB} Colorati
- Esito: ${_resultLabel()}

SQUADRA BIANCHI:
${teamSection(m.teamA, 'Bianchi')}

SQUADRA COLORATI:
${teamSection(m.teamB, 'Colorati')}

Rispondi SOLO con un JSON valido (nessun testo extra, nessun backtick), così:
{
  "headline": "TITOLONE IN MAIUSCOLO MAX 6 PAROLE",
  "subheadline": "Sottotitolo evocativo di 1-2 frasi",
  "articleBody": "Cronaca della partita di 3-4 frasi stile Gazzetta. Cita giocatori per nome, usa toni epici."
}
''';
  }

  // Chiamata OpenAI
  Future<void> _generateAiContent(String apiKey) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'user', 'content': _buildPrompt()}
          ],
          'max_tokens': 400,
          'temperature': 0.85,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final raw = (data['choices'][0]['message']['content'] as String).trim();
        // Strip backtick fences se presenti
        final clean = raw
            .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
            .replaceAll(RegExp(r'```$', multiLine: true), '')
            .trim();
        final json = jsonDecode(clean);
        if (mounted) {
          setState(() {
            _content = _NewspaperContent(
              headline: (json['headline'] as String? ?? '').toUpperCase(),
              subheadline: json['subheadline'] as String? ?? '',
              articleBody: json['articleBody'] as String? ?? '',
              isAiGenerated: true,
            );
            _loading = false;
          });
        }
      } else {
        // Quota / auth error → fallback statico silenzioso
        _setStaticFallback();
      }
    } catch (e) {
      _setStaticFallback();
    }
  }

  void _setStaticFallback() {
    if (mounted) {
      setState(() {
        _content = _staticContent();
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final apiKey = await _storage.read(key: _storageKey);
    if (apiKey != null && apiKey.isNotEmpty) {
      await _generateAiContent(apiKey);
    } else {
      _setStaticFallback();
    }
  }

  // ── build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMMM yyyy', 'it_IT').format(widget.match.date);
    final timeStr = DateFormat('HH:mm', 'it_IT').format(widget.match.date);
    final mvpName = _resolveName(widget.match.mvp);
    final hustleName = _resolveName(widget.match.hustlePlayer);
    final bestGoalName = _resolveName(widget.match.bestGoalPlayer);

    final allPlayers = [...widget.match.teamA, ...widget.match.teamB];
    final scorers = allPlayers
        .where((id) => (widget.match.goals[id] ?? 0) > 0)
        .toList()
      ..sort((a, b) =>
          (widget.match.goals[b] ?? 0).compareTo(widget.match.goals[a] ?? 0));

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD40000),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'LA GAZZETTA DEL CALCETTO',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          // Badge AI visibile quando il contenuto è generato dall'AI
          if (_content?.isAiGenerated == true)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white38),
                  ),
                  child: const Text(
                    'AI ✦',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? _LoadingNewspaper(dateStr: dateStr, timeStr: timeStr)
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _NewspaperHeader(dateStr: dateStr, timeStr: timeStr),

                  _HeadlineBlock(
                    scoreA: widget.match.scoreA,
                    scoreB: widget.match.scoreB,
                    headline: _content!.headline,
                    subheadline: _content!.subheadline,
                    resultLabel: _resultLabel(),
                  ),

                  // ── Articolo AI ────────────────────────────
                  if (_content!.articleBody.isNotEmpty)
                    _ArticleBody(text: _content!.articleBody),

                  _Ornament(),

                  if (mvpName.isNotEmpty || hustleName.isNotEmpty || bestGoalName.isNotEmpty)
                    _AwardsBlock(
                        mvpName: mvpName,
                        hustleName: hustleName,
                        bestGoalName: bestGoalName),

                  _Ornament(),

                  if (scorers.isNotEmpty)
                    _ScorersBlock(scorers: scorers, match: widget.match),

                  _TwoColumnRatings(
                    teamAIds: widget.match.teamA,
                    teamBIds: widget.match.teamB,
                    match: widget.match,
                  ),

                  _CommentsBlock(allPlayers: allPlayers, match: widget.match),
                ],
              ),
            ),
    );
  }
}

// ── Widget di loading stile giornale ─────────────────────────────

class _LoadingNewspaper extends StatefulWidget {
  final String dateStr, timeStr;
  const _LoadingNewspaper({required this.dateStr, required this.timeStr});

  @override
  State<_LoadingNewspaper> createState() => _LoadingNewspaperState();
}

class _LoadingNewspaperState extends State<_LoadingNewspaper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NewspaperHeader(
              dateStr: widget.dateStr, timeStr: widget.timeStr),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Striscia rossa placeholder
                Container(
                  height: 16,
                  width: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD40000).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 16),
                // Titolone placeholder animato
                FadeTransition(
                  opacity: _fade,
                  child: Column(
                    children: [
                      _SkeletonLine(width: double.infinity, height: 34),
                      const SizedBox(height: 8),
                      _SkeletonLine(width: 220, height: 34),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Score placeholder
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SkeletonLine(width: 70, height: 70),
                    const SizedBox(width: 28),
                    _SkeletonLine(width: 70, height: 70),
                  ],
                ),
                const SizedBox(height: 16),
                _SkeletonLine(width: 200, height: 14),
                const SizedBox(height: 32),
                _Ornament(),
                const SizedBox(height: 20),
                // Corpo articolo placeholder
                FadeTransition(
                  opacity: _fade,
                  child: Column(
                    children: [
                      _SkeletonLine(width: double.infinity, height: 13),
                      const SizedBox(height: 6),
                      _SkeletonLine(width: double.infinity, height: 13),
                      const SizedBox(height: 6),
                      _SkeletonLine(width: 260, height: 13),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Indicatore testuale
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Color(0xFFD40000),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FadeTransition(
                      opacity: _fade,
                      child: const Text(
                        'IL CRONISTA STA SCRIVENDO...',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: Color(0xFFD40000),
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

class _SkeletonLine extends StatelessWidget {
  final double width, height;
  const _SkeletonLine({required this.width, required this.height});

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A1A).withOpacity(0.08),
      borderRadius: BorderRadius.circular(4),
    ),
  );
}

// ── Corpo articolo AI ─────────────────────────────────────────────

class _ArticleBody extends StatelessWidget {
  final String text;
  const _ArticleBody({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drop cap sul primo carattere
        _buildBodyWithDropCap(text),
        const SizedBox(height: 6),
        // Firma redazione
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Redazione Gazzetta del Calcetto  ✦',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 9,
              fontStyle: FontStyle.italic,
              color: const Color(0xFFD40000).withOpacity(0.7),
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildBodyWithDropCap(String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    final first = text[0];
    final rest = text.length > 1 ? text.substring(1) : '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drop cap
        Text(
          first,
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 52,
            fontWeight: FontWeight.w900,
            color: Color(0xFFD40000),
            height: 0.85,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            rest,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 13.5,
              color: Color(0xFF2A2A2A),
              height: 1.55,
            ),
            textAlign: TextAlign.justify,
          ),
        ),
      ],
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


// ═══════════════════════════════════════════════════════════════
//  🎨  MATCH IMAGE GENERATION SCREEN  ──  Generazione DALL-E
// ═══════════════════════════════════════════════════════════════

class MatchImageGenerationScreen extends StatefulWidget {
  final MatchModel match;
  const MatchImageGenerationScreen({required this.match, super.key});

  @override
  State<MatchImageGenerationScreen> createState() => _MatchImageGenerationScreenState();
}

class _MatchImageGenerationScreenState extends State<MatchImageGenerationScreen> {
  static const _storage = FlutterSecureStorage();
  static const _storageKey = 'openai_api_key';

  bool _loading = true;
  String? _base64Image;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _generateImage();
  }

  String _buildImagePrompt() {
    // Costruisci una descrizione epica basandoti sul risultato per darla in pasto a DALL-E
    final m = widget.match;
    String descrizioneEsito = m.scoreA == m.scoreB 
        ? "un pareggio combattuto per ${m.scoreA}-${m.scoreB}" 
        : "una vittoria della squadra ${m.scoreA > m.scoreB ? 'Bianca' : 'Colorata'} per ${m.scoreA}-${m.scoreB}";

    String _resolveName(String id) {
    if (id.isEmpty) return '';
    return HiveBoxes.playersBox.get(id)?.name ?? id;
  }
    String teamSection(List<String> ids, String teamName) {
      return ids.map((id) {
        final name = _resolveName(id);
        final voto = m.votes[id] ?? 0.0;
        final gol = m.goals[id] ?? 0;
        final commento = m.comments[id] ?? '';
        final isMvp = m.mvp == id ? ' [MVP]' : '';
        final isHustle = m.hustlePlayer == id ? ' [COMBATTIVO]' : '';
        final isBG = m.bestGoalPlayer == id ? ' [BEST GOAL]' : '';
        return '  - $name$isMvp$isHustle$isBG: voto ${voto > 0 ? voto.toStringAsFixed(1) : 'N/D'}'
            '${gol > 0 ? ', $gol gol' : ''}'
            '${commento.isNotEmpty ? ', nota: "$commento"' : ''}';
      }).join('\n');
    }

return "generami una Prima pagina della Gazzetta dello Sport, stile autentico 2026, layout classico. Sfondo rosa acceso caratteristico, grana sottile di carta stampata. Grande logo GAZZETTA DEL CALCETTO in alto con font bold condensed bianco e rosso. Foto centrale potente di una partita di calcetto, espressione intensa, luci drammatiche da stadio. Titolo enorme rosso-nero con una frase sensazionale legata alla partita; Sotto, I dati della partita : $teamSection . da mostrare come articoli della pagina di copertina";
  }

  Future<void> _generateImage() async {
    final apiKey = await _storage.read(key: _storageKey);
    if (apiKey == null || apiKey.isEmpty) {
      setState(() {
        _errorMsg = "Chiave API OpenAI non trovata nelle impostazioni.";
        _loading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/images/generations'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-image-1',
          'prompt': _buildImagePrompt(),
          'n': 1,
          'size': '1024x1536',
        }),
      );

      if (response.statusCode == 200) {
  final data = jsonDecode(response.body);

  final base64Image = data['data']?[0]?['b64_json'];

  if (base64Image == null) {
    setState(() {
      _errorMsg = "Risposta API inattesa: base64Image mancante";
      _loading = false;
    });
    return;
  }

  setState(() {
    _base64Image = base64Image;
    _loading = false;
  });
} else {
  final error = jsonDecode(response.body);

  setState(() {
    _errorMsg = error['error']?['message'] ??
        "Errore OpenAI (Status: ${response.statusCode})";
    _loading = false;
  });
}
    } catch (e) {
      setState(() {
        _errorMsg = "Errore di rete: $e";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const FifaLabel('Copertina Illustrata AI', color: AppTheme.textPrimary, fontSize: 13),
        backgroundColor: AppTheme.surface,
      ),
      body: Center(
        child: _loading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppTheme.accentGreen),
                  const SizedBox(height: 16),
                  Text(
                    'DALL-E STA DIPINGENDO LA COPERTINA...',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            : _errorMsg != null
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(_errorMsg!, style: const TextStyle(color: AppTheme.accentRed), textAlign: TextAlign.center),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            base64Decode(_base64Image!),
                              fit: BoxFit.cover,
                            ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "✦ Opera generata dall'intelligenza artificiale di OpenAI basata sui dati reali del match.",
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}