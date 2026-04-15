import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'package:calcetto_tracker/services/data_service.dart';
import 'package:calcetto_tracker/screens/api_key_setup_page.dart';

// ─── Palette FIFA-style ───────────────────────────────────────────────────────
class _FifaColors {
  static const bgDeep = Color(0xFF0A0E1A); // sfondo principale, blu notte
  static const bgCard = Color(0xFF111827); // card messaggi
  static const bgInput = Color(0xFF1C2536); // input bar
  static const green = Color(0xFF00D46A); // verde erba luminoso
  static const greenDark = Color(0xFF008F48); // verde campo scuro
  static const gold = Color(0xFFF5C518); // oro FIFA
  static const goldDark = Color(0xFFB8890E);
  static const userBubble = Color(0xFF1A3A5C); // blu maglia
  static const aiBubble = Color(0xFF162035);
  static const errorBg = Color(0xFF3A0A0A);
  static const textPrimary = Color(0xFFF0F4FF);
  static const textSecondary = Color(0xFF8A95B0);
  static const divider = Color(0xFF1E2D45);
}

// ─── Theme helper ─────────────────────────────────────────────────────────────
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
  final _storage = const FlutterSecureStorage();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  bool _loading = false;
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

  Future<void> _checkApiKey() async {
    final key = await _storage.read(key: 'openai_api_key');
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

  // ── Prompt builder (invariato dalla versione originale) ───────────────────
  String _buildSystemPrompt(DataService ds) {
    final players = ds.getAllPlayers();
    final matches = ds.getAllMatches();
    final playerBuffer = StringBuffer();
    playerBuffer.writeln('ROSA GIOCATORI E STATISTICHE ANALITICHE:');
    if (players.isEmpty) {
      playerBuffer.writeln('Nessun giocatore registrato.');
    } else {
      for (var p in players) {
        final pMatches = matches
            .where((m) => m.teamA.contains(p.id) || m.teamB.contains(p.id))
            .toList();
        pMatches.sort((a, b) => b.date.compareTo(a.date));
        final totalGames = pMatches.length;
        int wins = 0;
        for (var m in pMatches) {
          final inTeamA = m.teamA.contains(p.id);
          if (inTeamA && m.scoreA > m.scoreB) wins++;
          if (!inTeamA && m.scoreB > m.scoreA) wins++;
        }
        final winRate =
            totalGames > 0 ? (wins / totalGames * 100).toStringAsFixed(0) : '0';
        final allVotes = pMatches
            .map((m) => m.votes[p.id])
            .where((v) => v != null)
            .cast<double>()
            .toList();
        final avgVote = allVotes.isNotEmpty
            ? (allVotes.reduce((a, b) => a + b) / allVotes.length)
                .toStringAsFixed(2)
            : 'N/A';

        playerBuffer.writeln('- ${p.name} [Ruolo: ${p.role}]: '
            'Media Voto: $avgVote, '
            'Gol Totali: ${p.totalGoals}, '
            'MVP: ${p.mvpCount}, '
            'Combattivo: ${p.hustleCount}, '
            'Gol più bello: ${p.bestGoalCount}, '
            'Win Rate: $winRate% ($totalGames partite).');
      }
    }
    return '''
Sei un esperto di calcetto e data analyst che assiste l'utente nella gestione del proprio gruppo di Calcetto.
Il tuo obiettivo è:
- Analizzare i dati dei giocatori registrati nell'app
- Fornire consigli tecnici
- Rispondere a domande sulle performance
- Creare squadre equilibrate quando richiesto, con lo stesso numero di giocatori per squadra(quando possibile)
- usa tutti i giocatori che sono disponibili per quella partita

UTILIZZO DATI:
- Usa SOLO i dati forniti.
- NON inventare MAI statistiche, ruoli o informazioni mancanti.
- Se un dato non è presente, dichiaralo brevemente.
- Non fare assunzioni non giustificate dai dati.

METRICHE DI VALUTAZIONE:
1. Media Voto → qualità costante
2. Gol Totali → capacità realizzativa
3. Premi (MVP, Combattivo, Gol Bello) → impatto e leadership
4. Win Rate → contributo alle vittorie

### GESTIONE RICHIESTE

#### 1. Creazione SQUADRE:

Quando l’utente richiede la creazione delle squadre:
Usa tutti i giocatori disponibili.
NON ripetere nessun giocatore.
Dividi i giocatori in due squadre con lo stesso numero di membri, quando possibile.
Se il numero è dispari, indica chiaramente chi resta fuori.
Assicurati che ogni giocatore compaia una sola volta.

Squadra A:
- Nome — Ruolo
  Punti di forza: ...
  Impatto: ...
Squadra B:
- Nome — Ruolo
  Punti di forza: ...
  Impatto: ...
CONSIDERAZIONI FINALI:
- Equilibrio generale
- Chiavi tattiche

#### 2. Analisi o domanda generica:
Rispondi in modo chiaro e sintetico usando i dati.

### REGOLE:
- NON mostrare calcoli o ragionamenti interni
- NON inventare dati
- Sii sintetico ma informativo

DATI SQUADRA:
${playerBuffer.toString()}
''';
  }

  // ── Send con streaming ────────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _loading || _apiKey == null) return;

    final ds = Provider.of<DataService>(context, listen: false);
    final assistantMessage = _ChatMessage(role: 'assistant', content: '');
    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: text));
      _messages.add(assistantMessage);
      _loading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final systemPrompt = _buildSystemPrompt(ds);
      final history = _messages.sublist(0, _messages.length - 1);
      final apiMessages = [
        {'role': 'system', 'content': systemPrompt},
        ...history
            .where((m) => m.role == 'user' || m.role == 'assistant')
            .map((m) => {'role': m.role, 'content': m.content}),
      ];

      final request = http.Request(
        'POST',
        Uri.parse('https://api.openai.com/v1/chat/completions'),
      );
      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      });
      request.body = jsonEncode({
        'model': 'gpt-4.1-mini',
        'messages': apiMessages,
        'temperature': 0.3,
        'stream': true,
      });

      final streamedResponse = await http.Client().send(request);
      if (streamedResponse.statusCode != 200) {
        _showError("Errore API: ${streamedResponse.statusCode}");
        return;
      }

      final responseBuffer = StringBuffer();
      String lineBuffer = '';

      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        lineBuffer += chunk;
        while (lineBuffer.contains('\n')) {
          final newlineIndex = lineBuffer.indexOf('\n');
          final line = lineBuffer.substring(0, newlineIndex).trim();
          lineBuffer = lineBuffer.substring(newlineIndex + 1);
          if (!line.startsWith('data: ')) continue;
          final jsonStr = line.substring(6);
          if (jsonStr == '[DONE]') break;
          try {
            final data = jsonDecode(jsonStr);
            final delta =
                data['choices'][0]['delta']['content'] as String? ?? '';
            if (delta.isEmpty) continue;
            responseBuffer.write(delta);
            if (mounted) {
              setState(
                  () => assistantMessage.content = responseBuffer.toString());
              _scrollToBottom();
            }
          } catch (_) {}
        }
      }

      if (responseBuffer.isEmpty) {
        setState(() => assistantMessage.content = '(nessuna risposta)');
      }
    } catch (e) {
      _showError("Errore di connessione: $e");
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: fifaTheme(),
      child: Scaffold(
        backgroundColor: _FifaColors.bgDeep,
        body: Column(
          children: [
            _FifaAppBar(fadeAnim: _headerFade),
            _PitchDivider(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length +
                    (_loading && _messages.last.content.isEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length)
                    return const _TypingIndicator();
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

// ─── AppBar FIFA ──────────────────────────────────────────────────────────────
class _FifaAppBar extends StatelessWidget {
  final Animation<double> fadeAnim;
  const _FifaAppBar({required this.fadeAnim});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: top + 12, bottom: 14, left: 20, right: 20),
      decoration: const BoxDecoration(
        color: _FifaColors.bgDeep,
      ),
      child: FadeTransition(
        opacity: fadeAnim,
        child: Row(
          children: [
            // Badge rotondo verde
            Container(
              width: 44,
              height: 44,
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
            const Spacer(),
            // --- NUOVO TASTO IMPOSTAZIONI ---
            IconButton(
              icon: const Icon(Icons.settings_outlined,
                  color: _FifaColors.textSecondary, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ApiKeySetupPage()),
                ).then((_) {
                  // Quando si torna indietro, ricarichiamo la chiave nel caso sia cambiata
                  final state =
                      context.findAncestorStateOfType<_AiCoachPageState>();
                  state?._checkApiKey();
                });
              },
            ),
            // --------------------------------
            const SizedBox(width: 8),
            // Pill "LIVE"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _FifaColors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _FifaColors.green.withOpacity(0.4)),
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
                      ? Colors.red.withOpacity(0.4)
                      : isUser
                          ? _FifaColors.green.withOpacity(0.25)
                          : _FifaColors.divider,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? _FifaColors.green.withOpacity(0.08)
                        : Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color:
                      isError ? Colors.red.shade300 : _FifaColors.textPrimary,
                  fontSize: 14.5,
                  height: 1.5,
                ),
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

// ─── Avatar ───────────────────────────────────────────────────────────────────
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
              ? _FifaColors.gold.withOpacity(0.5)
              : _FifaColors.green.withOpacity(0.6),
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

// ─── Typing indicator FIFA style ──────────────────────────────────────────────
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
                decoration: InputDecoration(
                  hintText: 'Chiedi al Coach...',
                  hintStyle: const TextStyle(
                    color: _FifaColors.textSecondary,
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 12, right: 4),
                    child: Text('⚽', style: TextStyle(fontSize: 16)),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Bottone invio FIFA-style
          GestureDetector(
            onTap: loading ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: loading
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_FifaColors.green, _FifaColors.greenDark],
                      ),
                color: loading ? _FifaColors.bgInput : null,
                boxShadow: loading
                    ? null
                    : [
                        BoxShadow(
                          color: _FifaColors.green.withOpacity(0.35),
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
  _ChatMessage({required this.role, required this.content});
}
