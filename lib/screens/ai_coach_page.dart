import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:calcetto_tracker/core/network/openai_service.dart';
import 'package:calcetto_tracker/core/util/player_lookup.dart';
import 'package:calcetto_tracker/services/data_service.dart';
import 'package:calcetto_tracker/screens/api_key_setup_page.dart';
import 'package:calcetto_tracker/models/player_model.dart';
import 'package:calcetto_tracker/widgets/player_avatar.dart';

import 'package:fl_chart/fl_chart.dart'; // <-- assicurati di avere questo import

// ─── Palette FIFA-style ───────────────────────────────────────────────────────
class _FifaColors {
  static const bgDeep = Color(0xFF0A0E1A);
  static const bgCard = Color(0xFF111827);
  static const bgInput = Color(0xFF1C2536);
  static const green = Color(0xFF00D46A);
  static const greenDark = Color(0xFF008F48);
  static const gold = Color(0xFFF5C518);
  static const userBubble = Color(0xFF1A3A5C);
  static const aiBubble = Color(0xFF162035);
  static const errorBg = Color(0xFF3A0A0A);
  static const textPrimary = Color(0xFFF0F4FF);
  static const textSecondary = Color(0xFF8A95B0);
  static const divider = Color(0xFF1E2D45);
}

ThemeData fifaTheme() => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _FifaColors.bgDeep,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        primary: _FifaColors.green,
        secondary: _FifaColors.gold,
        surface: _FifaColors.bgCard,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: 2.5,
          color: _FifaColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: _FifaColors.textPrimary),
      ),
    );

// ─── Widget principale ────────────────────────────────────────────────────────
class AiCoachPage extends StatefulWidget {
  const AiCoachPage({super.key});

  @override
  State<AiCoachPage> createState() => _AiCoachPageState();
}

class _AiCoachPageState extends State<AiCoachPage>
    with TickerProviderStateMixin {
  final _openAiService = OpenAiService();
  String? _apiKey;

  late final AnimationController _headerAnim;
  late final Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerAnim.forward();
    _checkApiKey();
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  Future<void> _checkApiKey() async {
    final key = await _openAiService.readApiKey();
    if (!mounted) return;
    if (key == null || key.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ApiKeySetupPage()),
      );
    } else {
      setState(() => _apiKey = key);
    }
  }

  void _openChat() {
    if (_apiKey == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ChatPage(apiKey: _apiKey!),
      ),
    );
  }

  void _openTeamBuilder() {
    if (_apiKey == null) return;
    final ds = Provider.of<DataService>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeamBuilderPage(apiKey: _apiKey!, dataService: ds),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: fifaTheme(),
      child: Scaffold(
        backgroundColor: _FifaColors.bgDeep,
        body: Column(
          children: [
            _FifaAppBar(
              fadeAnim: _headerFade,
              onSettingsTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ApiKeySetupPage()),
                ).then((_) => _checkApiKey());
              },
            ),
            _PitchDivider(),
            Expanded(
              child: _apiKey == null
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: _FifaColors.green))
                  : _ModeSelectionBody(
                      onChatTap: _openChat,
                      onTeamBuilderTap: _openTeamBuilder,
                      fadeAnim: _headerFade,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Schermata selezione modalità ─────────────────────────────────────────────
class _ModeSelectionBody extends StatelessWidget {
  final VoidCallback onChatTap;
  final VoidCallback onTeamBuilderTap;
  final Animation<double> fadeAnim;

  const _ModeSelectionBody({
    required this.onChatTap,
    required this.onTeamBuilderTap,
    required this.fadeAnim,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icona centrale
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _FifaColors.greenDark,
                  border: Border.all(color: _FifaColors.green, width: 2),
                ),
                child: const Center(
                  child: Text('⚽', style: TextStyle(fontSize: 36)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Titolo
            const Text(
              'COME POSSO\nAIUTARTI?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _FifaColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scegli la modalità',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _FifaColors.textSecondary,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 48),

            // Card Fai le Squadre
            _ModeCard(
              emoji: '🏆',
              title: 'FAI LE SQUADRE',
              subtitle:
                  'Scegli i giocatori disponibili e l\'AI crea squadre equilibrate con statistiche e pronostico',
              accentColor: _FifaColors.gold,
              onTap: onTeamBuilderTap,
              isHighlighted: true,
            ),

            const SizedBox(height: 16),

            // Card Chat Generale
            _ModeCard(
              emoji: '💬',
              title: 'CHIEDI AL COACH',
              subtitle:
                  'Analisi dati, statistiche giocatori, consigli tattici e qualsiasi domanda sulla squadra',
              accentColor: _FifaColors.green,
              onTap: onChatTap,
              isHighlighted: false,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;
  final bool isHighlighted;

  const _ModeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isHighlighted
              ? accentColor.withValues(alpha: 0.08)
              : _FifaColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted
                ? accentColor.withValues(alpha: 0.5)
                : _FifaColors.divider,
            width: isHighlighted ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color:
                          isHighlighted ? accentColor : _FifaColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _FifaColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: accentColor.withValues(alpha: 0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Team Builder Page ────────────────────────────────────────────────────────
class TeamBuilderPage extends StatefulWidget {
  final String apiKey;
  final DataService dataService;

  const TeamBuilderPage(
      {required this.apiKey, required this.dataService, super.key});

  @override
  State<TeamBuilderPage> createState() => _TeamBuilderPageState();
}

class _TeamBuilderPageState extends State<TeamBuilderPage> {
  final _openAiService = OpenAiService();
  final Set<String> _selectedIds = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _loading = false;
  String? _result;
  bool _hasResult = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PlayerModel> get _allPlayers => widget.dataService.getAllPlayers()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  List<PlayerModel> get _filteredPlayers {
    final all = _allPlayers;
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _generateTeams() async {
    if (_selectedIds.length < 2) return;
    setState(() {
      _loading = true;
      _result = null;
      _hasResult = false;
    });

    final selected =
        _allPlayers.where((p) => _selectedIds.contains(p.id)).toList();
    final allMatches = widget.dataService.getAllMatches();

    // Raccoglie statistiche per ogni giocatore selezionato
    final playerStats = <Map<String, dynamic>>[];
    for (final p in selected) {
      int games = 0, wins = 0;
      double totalVote = 0;
      int voteCount = 0, goals = 0;
      for (final m in allMatches) {
        final inA = m.teamA.contains(p.id);
        final inB = m.teamB.contains(p.id);
        if (!inA && !inB) continue;
        games++;
        final ps = inA ? m.scoreA : m.scoreB;
        final os = inA ? m.scoreB : m.scoreA;
        if (ps > os) wins++;
        goals += m.goals[p.id] ?? 0;
        if (m.votes.containsKey(p.id)) {
          totalVote += m.votes[p.id]!;
          voteCount++;
        }
      }
      playerStats.add({
        'id': p.id,
        'name': p.name,
        'role': p.role,
        'games': games,
        'wins': wins,
        'winRate': games > 0 ? (wins / games * 100).round() : 0,
        'avgVote': voteCount > 0
            ? double.parse((totalVote / voteCount).toStringAsFixed(1))
            : 0.0,
        'goals': goals,
        'mvp': p.mvpCount,
        'hustle': p.hustleCount,
      });
    }

    final systemPrompt = '''
Sei un esperto tattico di calcetto. Il tuo compito è creare due squadre bilanciate dai giocatori forniti.

REGOLE FONDAMENTALI:
- Usa TUTTI e SOLO i giocatori forniti
- Ogni giocatore deve apparire in UNA SOLA squadra
- Se il numero è dispari, indica chi rimane fuori e perché
- Bilancia le squadre considerando: voto medio, win rate, gol, premi MVP
- NON mostrare il JSON grezzo

FORMATO RISPOSTA (rispetta questa struttura esatta):

⚽ SQUADRA A
• [Nome] — [Ruolo] | Voto medio: X.X | Gol: N | Win%: N%
• [Nome] — [Ruolo] | Voto medio: X.X | Gol: N | Win%: N%
...
📊 Media voto squadra: X.X | Win rate medio: N% | Gol totali: N

⚽ SQUADRA B
• [Nome] — [Ruolo] | Voto medio: X.X | Gol: N | Win%: N%
• [Nome] — [Ruolo] | Voto medio: X.X | Gol: N | Win%: N%
...
📊 Media voto squadra: X.X | Win rate medio: N% | Gol totali: N

⚖️ EQUILIBRIO
[2-3 righe su quanto sono bilanciate le squadre e quale team ha qualche piccolo vantaggio]

🔮 PRONOSTICO
[Un pronostico di come potrebbe finire la partita (es. "Partita equilibrata, possibile 3-3 o 2-2") con 2-3 righe di analisi tattica su cosa potrebbe fare la differenza]

DATI GIOCATORI:
${jsonEncode(playerStats)}
''';

    try {
      final responseBuffer = StringBuffer();
      final stream = _openAiService.chatCompletionStream(
        apiKey: widget.apiKey,
        model: 'gpt-4.1-mini',
        temperature: 0.4,
        messages: [
          {'role': 'system', 'content': systemPrompt},
          {
            'role': 'user',
            'content':
                'Crea le squadre con i ${selected.length} giocatori forniti.'
          }
        ],
      );

      await for (final delta in stream) {
        responseBuffer.write(delta);
        if (mounted) {
          setState(() => _result = responseBuffer.toString());
        }
      }

      if (mounted) {
        setState(() {
          _loading = false;
          _hasResult = true;
        });
      }
    } on OpenAiException catch (e) {
      if (mounted) {
        setState(() {
          _result = e.statusCode != null
              ? 'Errore API: ${e.statusCode}'
              : 'Errore di connessione: $e';
          _loading = false;
          _hasResult = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _result = 'Errore di connessione: $e';
          _loading = false;
          _hasResult = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canGenerate = _selectedIds.length >= 2;

    return Theme(
      data: fifaTheme(),
      child: Scaffold(
        backgroundColor: _FifaColors.bgDeep,
        appBar: AppBar(
          backgroundColor: _FifaColors.bgDeep,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: _FifaColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FAI LE SQUADRE',
                style: TextStyle(
                  color: _FifaColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
              Text(
                'COACH AI',
                style: TextStyle(
                  color: _FifaColors.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  _FifaColors.gold,
                  _FifaColors.green,
                  _FifaColors.gold,
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Header selezione
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              decoration: const BoxDecoration(
                color: _FifaColors.bgCard,
                border: Border(bottom: BorderSide(color: _FifaColors.divider)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SELEZIONA I GIOCATORI DISPONIBILI',
                              style: TextStyle(
                                color: _FifaColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_selectedIds.length} selezionati',
                              style: const TextStyle(
                                color: _FifaColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedIds.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(() => _selectedIds.clear()),
                          child: const Text(
                            'DESELEZIONA TUTTI',
                            style: TextStyle(
                                color: _FifaColors.textSecondary,
                                fontSize: 10,
                                letterSpacing: 1),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Barra di ricerca
                  Container(
                    decoration: BoxDecoration(
                      color: _FifaColors.bgInput,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _FifaColors.divider),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(
                          color: _FifaColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Cerca giocatore…',
                        hintStyle: const TextStyle(
                            color: _FifaColors.textSecondary, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: _FifaColors.textSecondary, size: 18),
                        suffixIcon: _query.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                                child: const Icon(Icons.close_rounded,
                                    color: _FifaColors.textSecondary, size: 16),
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Lista giocatori
            Expanded(
              child: _hasResult
                  ? _ResultView(
                      result: _result ?? '',
                      loading: _loading,
                      onReset: () => setState(() {
                        _hasResult = false;
                        _result = null;
                        _selectedIds.clear();
                        _searchCtrl.clear();
                        _query = '';
                      }),
                    )
                  : _filteredPlayers.isEmpty
                      ? const Center(
                          child: Text(
                            'Nessun giocatore trovato',
                            style: TextStyle(
                                color: _FifaColors.textSecondary, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: _filteredPlayers.length,
                          itemBuilder: (context, i) {
                            final p = _filteredPlayers[i];
                            final isSelected = _selectedIds.contains(p.id);
                            return _PlayerSelectTile(
                              player: p,
                              isSelected: isSelected,
                              onTap: () => setState(() {
                                if (isSelected) {
                                  _selectedIds.remove(p.id);
                                } else {
                                  _selectedIds.add(p.id);
                                }
                              }),
                            );
                          },
                        ),
            ),

            // Bottone genera
            if (!_hasResult)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                decoration: const BoxDecoration(
                  color: _FifaColors.bgCard,
                  border: Border(top: BorderSide(color: _FifaColors.divider)),
                ),
                child: _loading
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _FifaColors.bgInput,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _FifaColors.green.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _FifaColors.green,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'ANALISI IN CORSO...',
                              style: TextStyle(
                                color: _FifaColors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: canGenerate ? _generateTeams : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: canGenerate
                                ? _FifaColors.gold.withValues(alpha: 0.15)
                                : _FifaColors.bgInput,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: canGenerate
                                  ? _FifaColors.gold.withValues(alpha: 0.5)
                                  : _FifaColors.divider,
                              width: canGenerate ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '🏆',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: canGenerate
                                      ? _FifaColors.gold
                                      : _FifaColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                canGenerate
                                    ? 'GENERA SQUADRE CON ${_selectedIds.length} GIOCATORI'
                                    : 'SELEZIONA ALMENO 2 GIOCATORI',
                                style: TextStyle(
                                  color: canGenerate
                                      ? _FifaColors.gold
                                      : _FifaColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── PlayerModel Select Tile ───────────────────────────────────────────────────────
class _PlayerSelectTile extends StatelessWidget {
  final PlayerModel player;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlayerSelectTile({
    required this.player,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? _FifaColors.green.withValues(alpha: 0.08)
              : _FifaColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? _FifaColors.green.withValues(alpha: 0.5)
                : _FifaColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            PlayerAvatar(
                name: player.name,
                icon: player.icon,
                imagePath: player.imagePath,
                radius: 20),
            const SizedBox(width: 12),
            // Nome + ruolo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name.toUpperCase(),
                    style: TextStyle(
                      color: isSelected
                          ? _FifaColors.textPrimary
                          : _FifaColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _RoleBadge(role: player.role),
                      if (player.mvpCount > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '👑×${player.mvpCount}',
                          style: const TextStyle(
                              fontSize: 11, color: _FifaColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _FifaColors.green : Colors.transparent,
                border: Border.all(
                  color: isSelected ? _FifaColors.green : _FifaColors.divider,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.black)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  Color get _color => switch (role) {
        'P' => _FifaColors.gold,
        'D' => const Color(0xFF00B0FF),
        'C' => _FifaColors.green,
        'A' => const Color(0xFFFF4444),
        _ => _FifaColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: _color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ─── Result View ──────────────────────────────────────────────────────────────
class _ResultView extends StatelessWidget {
  final String result;
  final bool loading;
  final VoidCallback onReset;

  const _ResultView({
    required this.result,
    required this.loading,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra azioni
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: _FifaColors.bgCard,
            border: Border(bottom: BorderSide(color: _FifaColors.divider)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: loading ? _FifaColors.gold : _FifaColors.green,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                loading ? 'ANALISI IN CORSO...' : 'ANALISI COMPLETATA',
                style: TextStyle(
                  color: loading ? _FifaColors.gold : _FifaColors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              if (!loading)
                GestureDetector(
                  onTap: onReset,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _FifaColors.bgInput,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _FifaColors.divider),
                    ),
                    child: const Text(
                      '↺ RICOMINCIA',
                      style: TextStyle(
                        color: _FifaColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Contenuto risultato
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ResultCard(text: result),
                if (loading) ...[
                  const SizedBox(height: 16),
                  _TypingIndicatorSmall(),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String text;
  const _ResultCard({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox();

    final sections = _parseResult(text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections.map((s) => _SectionWidget(section: s)).toList(),
    );
  }

  List<_Section> _parseResult(String text) {
    final lines = text.split('\n');
    final sections = <_Section>[];
    _Section? current;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('⚽') ||
          trimmed.startsWith('⚖️') ||
          trimmed.startsWith('🔮') ||
          trimmed.startsWith('📊')) {
        if (current != null) sections.add(current);
        current = _Section(header: trimmed, lines: []);
      } else if (current != null) {
        current.lines.add(trimmed);
      } else {
        current = _Section(header: '', lines: [trimmed]);
      }
    }
    if (current != null) sections.add(current);
    return sections;
  }
}

class _Section {
  final String header;
  final List<String> lines;
  _Section({required this.header, required this.lines});
}

class _SectionWidget extends StatelessWidget {
  final _Section section;
  const _SectionWidget({required this.section});

  Color _headerColor() {
    if (section.header.startsWith('⚽')) return _FifaColors.green;
    if (section.header.startsWith('⚖️')) return _FifaColors.gold;
    if (section.header.startsWith('🔮')) return const Color(0xFFAA88FF);
    if (section.header.startsWith('📊')) return const Color(0xFF00B0FF);
    return _FifaColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _headerColor();
    final isTeam = section.header.startsWith('⚽');
    final isStats = section.header.startsWith('📊');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isTeam ? color.withValues(alpha: 0.06) : _FifaColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: isTeam ? 0.35 : 0.2),
          width: isTeam ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.header.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Text(
                section.header,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          if (section.header.isNotEmpty && section.lines.isNotEmpty)
            Container(
                height: 1,
                color: color.withValues(alpha: 0.15),
                margin: const EdgeInsets.symmetric(horizontal: 14)),
          ...section.lines.map(
            (line) => Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: Text(
                line,
                style: TextStyle(
                  color: isStats ? color : _FifaColors.textPrimary,
                  fontSize: isStats ? 12 : 13,
                  fontWeight: isStats ? FontWeight.w700 : FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _TypingIndicatorSmall extends StatefulWidget {
  @override
  State<_TypingIndicatorSmall> createState() => _TypingIndicatorSmallState();
}

class _TypingIndicatorSmallState extends State<_TypingIndicatorSmall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: const Text(
        '● ● ●',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _FifaColors.green,
          fontSize: 12,
          letterSpacing: 4,
        ),
      ),
    );
  }
}

// ─── Chat Page (chat generica) ────────────────────────────────────────────────
class _ChatPage extends StatefulWidget {
  final String apiKey;
  const _ChatPage({required this.apiKey});

  @override
  State<_ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<_ChatPage> with TickerProviderStateMixin {
  final _openAiService = OpenAiService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _loading = false;

  late final AnimationController _headerAnim;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _headerAnim.forward();

    _messages.add(_ChatMessage(
      role: 'assistant',
      content:
          '⚽ Ciao! Sono il tuo Coach AI.\nHo analizzato i dati della squadra. Come posso aiutarti oggi?',
    ));
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // DataService legge sempre live da Hive (nessun caching), quindi i dati
  // sono aggiornati indipendentemente da quando il Provider è stato creato.
  String _buildSystemPrompt() {
    final data = Provider.of<DataService>(context, listen: false);
    final allPlayers = data.getAllPlayers();
    final allMatches = data.getAllMatches();

    String resolveName(String id) => resolvePlayerName(id);

    // Statistiche aggregate per giocatore
    final playerStats = allPlayers.map((p) {
      int games = 0, wins = 0, draws = 0, losses = 0, votesCount = 0;
      double totalVotes = 0;
      int goalsScored = 0;

      for (final m in allMatches) {
        final inA = m.teamA.contains(p.id);
        final inB = m.teamB.contains(p.id);
        if (!inA && !inB) continue;
        games++;
        final myScore = inA ? m.scoreA : m.scoreB;
        final oppScore = inA ? m.scoreB : m.scoreA;
        if (myScore > oppScore) {
          wins++;
        } else if (myScore == oppScore) {
          draws++;
        } else {
          losses++;
        }
        if (m.votes.containsKey(p.id)) {
          totalVotes += m.votes[p.id]!;
          votesCount++;
        }
        goalsScored += m.goals[p.id] ?? 0;
      }

      return {
        'nome': p.name,
        'ruolo': p.role,
        'partite_giocate': games,
        'vittorie': wins,
        'pareggi': draws,
        'sconfitte': losses,
        'win_rate_pct':
            games > 0 ? (wins / games * 100).toStringAsFixed(1) : '0',
        'voto_medio': votesCount > 0
            ? (totalVotes / votesCount).toStringAsFixed(2)
            : null,
        'gol_totali': goalsScored,
        'premi_mvp': p.mvpCount,
        'premi_combattivo': p.hustleCount,
        'premi_best_goal': p.bestGoalCount,
      };
    }).toList();

    // Partite con nomi risolti (non ID grezzi)
    final matchesData = allMatches.map((m) {
      final votesNamed = <String, double>{};
      for (final entry in m.votes.entries) {
        final name = resolveName(entry.key);
        if (name.isNotEmpty) votesNamed[name] = entry.value;
      }
      final goalsNamed = <String, int>{};
      for (final entry in m.goals.entries) {
        if (entry.value > 0) {
          final name = resolveName(entry.key);
          if (name.isNotEmpty) goalsNamed[name] = entry.value;
        }
      }
      final field = data.getFieldById(m.fieldLocation);
      return {
        'data': m.date.toIso8601String().substring(0, 10),
        'campo': field?.name ?? m.fieldLocation,
        'squadra_bianca':
            m.teamA.map(resolveName).where((n) => n.isNotEmpty).toList(),
        'squadra_colorata':
            m.teamB.map(resolveName).where((n) => n.isNotEmpty).toList(),
        'risultato': '${m.scoreA}-${m.scoreB}',
        'voti': votesNamed,
        'gol': goalsNamed,
        'MVP': resolveName(m.mvp),
        'Combattivo': resolveName(m.hustlePlayer),
        'Gol_piu_bello': resolveName(m.bestGoalPlayer),
      };
    }).toList();

    final contextJson = {
      'statistiche_giocatori': playerStats,
      'partite': matchesData,
    };

    return '''
Sei un esperto di calcetto e data analyst che assiste l'utente nella gestione del proprio gruppo di Calcetto.
Il tuo obiettivo è:
- Analizzare i dati dei giocatori registrati nell'app
- Fornire consigli tecnici
- Rispondere a domande sulle performance

REGOLE:
- NON mostrare mai il JSON
- NON copiare i dati raw nella risposta
- Usa i dati solo per analisi
- NON inventare MAI statistiche
- Se un dato non è presente, dichiaralo brevemente
- Quando devi mostrare un grafico, restituisci SOLO un JSON come questo:

{
  "type": "chart",
  "chartType": "line",
  "data": [
    {"x": "Gen", "y": 12},
    {"x": "Feb", "y": 20}
  ]
}

Non includere testo fuori dal JSON.

DATI (NON MOSTRARLI ALL'UTENTE):
${jsonEncode(contextJson)}
''';
  }

  void _resetChat() {
    setState(() {
      _messages.clear();
      _messages.add(_ChatMessage(
        role: 'assistant',
        content:
            '⚽ Ciao! Sono il tuo Coach AI.\nHo analizzato i dati aggiornati della squadra. Come posso aiutarti oggi?',
      ));
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _loading) return;

    final assistantMessage = _ChatMessage(role: 'assistant', content: '');
    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: text));
      _messages.add(assistantMessage);
      _loading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      // System prompt rigenerato ad ogni messaggio con dati freschi da Hive
      final systemPrompt = _buildSystemPrompt();
      final history = _messages.sublist(0, _messages.length - 1);
      final apiMessages = [
        {'role': 'system', 'content': systemPrompt},
        ...history
            .where((m) => m.role == 'user' || m.role == 'assistant')
            .map((m) => {'role': m.role, 'content': m.content}),
      ];

      final responseBuffer = StringBuffer();
      final stream = _openAiService.chatCompletionStream(
        apiKey: widget.apiKey,
        model: 'gpt-4.1-mini',
        temperature: 0.3,
        messages: apiMessages,
      );

      await for (final delta in stream) {
        // Accumula sempre il testo durante lo streaming
        responseBuffer.write(delta);
        if (mounted) {
          setState(() => assistantMessage.content = responseBuffer.toString());
          _scrollToBottom();
        }
      }

      // --- PARSE JSON PER GRAFICO (a risposta completa) ---
      final fullResponse = responseBuffer.toString().trim();
      try {
        final jsonData = jsonDecode(fullResponse);
        if (jsonData is Map && jsonData["type"] == "chart") {
          // È un grafico: svuota il testo e imposta i dati del grafico
          if (mounted) {
            setState(() {
              assistantMessage.content = '';
              assistantMessage.chartType = jsonData["chartType"] as String?;
              assistantMessage.chartData =
                  List<Map<String, dynamic>>.from(jsonData["data"]);
            });
          }
        }
      } catch (_) {
        // Non è JSON → risposta testuale normale, non fare nulla
      }

      if (fullResponse.isEmpty) {
        setState(() => assistantMessage.content = '(nessuna risposta)');
      }
    } on OpenAiException catch (e) {
      _showError(e.statusCode != null
          ? 'Errore API: ${e.statusCode}'
          : 'Errore di connessione: $e');
      return;
    } catch (e) {
      _showError('Errore di connessione: $e');
    }

    if (mounted) setState(() => _loading = false);
    _scrollToBottom();
  }

  void _showError(String message) {
    setState(() {
      if (_messages.isNotEmpty && _messages.last.content.isEmpty) {
        _messages.removeLast();
      }
      _messages.add(_ChatMessage(role: 'error', content: message));
      _loading = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: fifaTheme(),
      child: Scaffold(
        backgroundColor: _FifaColors.bgDeep,
        appBar: AppBar(
          backgroundColor: _FifaColors.bgDeep,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: _FifaColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COACH AI',
                style: TextStyle(
                  color: _FifaColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
              Text(
                'ANALISI SQUADRA',
                style: TextStyle(
                  color: _FifaColors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: _FifaColors.green, size: 22),
              tooltip: 'Nuova chat',
              onPressed: _resetChat,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  _FifaColors.green,
                  _FifaColors.gold,
                  _FifaColors.green,
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length +
                    (_loading && _messages.last.content.isEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return const _TypingIndicator();
                  }
                  return _MessageBubble(message: _messages[index]);
                },
              ),
            ),
            _InputBar(
              controller: _messageController,
              loading: _loading,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── AppBar FIFA (per la pagina principale) ───────────────────────────────────
class _FifaAppBar extends StatelessWidget {
  final Animation<double> fadeAnim;
  final VoidCallback onSettingsTap;
  const _FifaAppBar({required this.fadeAnim, required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: top + 12, bottom: 14, left: 20, right: 20),
      decoration: const BoxDecoration(color: _FifaColors.bgDeep),
      child: FadeTransition(
        opacity: fadeAnim,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: _FifaColors.textPrimary, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _FifaColors.greenDark,
                border: Border.all(color: _FifaColors.green, width: 2),
              ),
              child: const Center(
                  child: Text('⚽', style: TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COACH AI',
                  style: TextStyle(
                    color: _FifaColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'ASSISTENTE SQUADRA',
                  style: TextStyle(
                    color: _FifaColors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.settings_outlined,
                  color: _FifaColors.textSecondary, size: 20),
              onPressed: onSettingsTap,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _FifaColors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: _FifaColors.green.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: _FifaColors.green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: _FifaColors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Divisore campo ───────────────────────────────────────────────────────────
class _PitchDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.transparent,
          _FifaColors.green,
          _FifaColors.gold,
          _FifaColors.green,
          Colors.transparent,
        ]),
      ),
    );
  }
}

// ─── Bubble messaggi ──────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final isError = message.role == 'error';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _Avatar(isUser: false, isError: isError),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isError
                    ? _FifaColors.errorBg
                    : isUser
                        ? _FifaColors.userBubble
                        : _FifaColors.aiBubble,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isError
                      ? Colors.red.withValues(alpha: 0.4)
                      : isUser
                          ? _FifaColors.green.withValues(alpha: 0.25)
                          : _FifaColors.divider,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Testo normale
                  if (message.content.isNotEmpty)
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isError
                            ? Colors.red.shade300
                            : _FifaColors.textPrimary,
                        fontSize: 14.5,
                        height: 1.5,
                      ),
                    ),

                  // --- GRAFICO ---
                  if (message.chartData != null) ...[
                    const SizedBox(height: 12),
                    _ChartWidget(
                      type: message.chartType!,
                      data: message.chartData!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            _Avatar(isUser: true, isError: false),
          ],
        ],
      ),
    );
  }
}

class _ChartWidget extends StatelessWidget {
  final String type;
  final List<Map<String, dynamic>> data;

  const _ChartWidget({required this.type, required this.data});

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case "line":
        return SizedBox(
          height: 240,
          child: LineChart(
            LineChartData(
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  barWidth: 3,
                  color: Colors.greenAccent,
                  spots: data.asMap().entries.map(
                    (e) {
                      final i = e.key.toDouble();
                      final y = (e.value["y"] as num).toDouble();
                      return FlSpot(i, y);
                    },
                  ).toList(),
                ),
              ],
            ),
          ),
        );

      case "bar":
        return SizedBox(
          height: 240,
          child: BarChart(
            BarChartData(
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map(
                (e) {
                  final i = e.key.toDouble();
                  final y = (e.value["y"] as num).toDouble();
                  return BarChartGroupData(
                    x: i.toInt(),
                    barRods: [
                      BarChartRodData(toY: y, color: Colors.greenAccent)
                    ],
                  );
                },
              ).toList(),
            ),
          ),
        );

      default:
        return const Text("Grafico non supportato");
    }
  }
}

class _Avatar extends StatelessWidget {
  final bool isUser;
  final bool isError;
  const _Avatar({required this.isUser, required this.isError});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUser ? _FifaColors.userBubble : _FifaColors.greenDark,
        border: Border.all(
          color: isUser
              ? _FifaColors.gold.withValues(alpha: 0.5)
              : _FifaColors.green.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          isUser ? '👤' : '🎯',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _Avatar(isUser: false, isError: false),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _FifaColors.aiBubble,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: _FifaColors.divider),
            ),
            child: Row(
              children: [
                FadeTransition(
                  opacity: _anim,
                  child: const Text(
                    '● ● ●',
                    style: TextStyle(
                      color: _FifaColors.green,
                      fontSize: 12,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'ANALISI IN CORSO',
                  style: TextStyle(
                    color: _FifaColors.textSecondary,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Input Bar ────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.loading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 12,
        top: 12,
        bottom: bottom + 12,
      ),
      decoration: BoxDecoration(
        color: _FifaColors.bgDeep,
        border: const Border(
          top: BorderSide(color: _FifaColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _FifaColors.bgInput,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _FifaColors.divider, width: 1),
              ),
              child: TextField(
                controller: controller,
                style: const TextStyle(
                  color: _FifaColors.textPrimary,
                  fontSize: 14.5,
                ),
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Chiedi al Coach...',
                  hintStyle: TextStyle(
                    color: _FifaColors.textSecondary,
                    fontSize: 14,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 12, right: 4),
                    child: Text('⚽', style: TextStyle(fontSize: 16)),
                  ),
                  prefixIconConstraints: BoxConstraints(minWidth: 0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: loading ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: loading ? _FifaColors.bgInput : _FifaColors.green,
                boxShadow: loading
                    ? null
                    : [
                        BoxShadow(
                          color: _FifaColors.green.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _FifaColors.green,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ChatMessage (mutabile per streaming) ─────────────────────────────────────
class _ChatMessage {
  final String role;
  String content;

  // NUOVI CAMPI PER I GRAFICI
  String? chartType; // "line", "bar", etc.
  List<Map<String, dynamic>>? chartData;

  _ChatMessage({
    required this.role,
    required this.content,
  });
}
