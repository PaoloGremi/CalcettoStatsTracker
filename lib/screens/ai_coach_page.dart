import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'package:calcetto_tracker/models/player.dart';
import 'package:calcetto_tracker/models/match_model.dart';
import 'package:calcetto_tracker/services/data_service.dart';
import 'package:calcetto_tracker/screens/api_key_setup_page.dart';

class AiCoachPage extends StatefulWidget {
  const AiCoachPage({super.key});

  @override
  State<AiCoachPage> createState() => _AiCoachPageState();
}

class _AiCoachPageState extends State<AiCoachPage> {
  final _storage = const FlutterSecureStorage();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  // ⚠️  _ChatMessage ora è mutabile (content non è più final)
  final List<_ChatMessage> _messages = [];
  bool _loading = false;
  String? _apiKey;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
    _messages.add(_ChatMessage(
      role: 'assistant',
      content:
          '⚽ Ciao! Sono il tuo Coach AI. Ho analizzato i dati della squadra. Come posso aiutarti oggi?',
    ));
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

  // ──────────────────────────────────────────────
  // COSTRUZIONE PROMPT CON METODI DATASERVICE
  // ──────────────────────────────────────────────
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
Sei un esperto di calcetto e data analyst.

Il tuo obiettivo è:
- Analizzare i dati dei giocatori
- Fornire consigli tecnici
- Rispondere a domande sulle performance
- Creare squadre equilibrate quando richiesto

UTILIZZO DATI:
- Usa SOLO i dati forniti.
- NON inventare MAI statistiche, ruoli o informazioni mancanti.
- Se un dato non è presente, dichiaralo brevemente (es: "dato non disponibile").
- Non fare assunzioni non giustificate dai dati.

METRICHE DI VALUTAZIONE (uso interno):
1. Media Voto → qualità costante
2. Gol Totali → capacità realizzativa
3. Premi (MVP, Combattivo, Gol Bello) → impatto e leadership
4. Win Rate → contributo alle vittorie

---

### 🧠 GESTIONE RICHIESTE

#### 1. Se viene richiesta la CREAZIONE DELLE SQUADRE:
- Dividi i giocatori in due squadre equilibrate.
- Mantieni:
  - equilibrio nel numero di giocatori (es: 5v5, 6v6, ecc.)
  - equilibrio nel livello complessivo (media voto + gol + impatto)
- Distribuisci i giocatori forti tra le squadre.
- NON mostrare calcoli o ragionamenti.

OUTPUT:

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
- Eventuale leggero vantaggio
- Chiavi tattiche
- Tipo di partita attesa

---

#### 2. Se viene richiesta un'ANALISI o DOMANDA GENERICA:
- Rispondi in modo chiaro e sintetico.
- Usa i dati per supportare le risposte.
- NON inventare informazioni mancanti.
- Se utile, evidenzia:
  - migliori giocatori
  - trend
  - punti di forza/debolezza

---

### ⚠️ REGOLE FONDAMENTALI:
- NON mostrare calcoli o ragionamenti interni
- NON inventare dati
- Sii sintetico ma informativo
- Adatta la risposta alla richiesta dell'utente

---

DATI SQUADRA:
${playerBuffer.toString()}
''';
  }

  // ──────────────────────────────────────────────
  // INVIO MESSAGGIO CON STREAMING
  // ──────────────────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _loading || _apiKey == null) return;

    final ds = Provider.of<DataService>(context, listen: false);

    // Aggiunge il messaggio utente e il placeholder della risposta AI
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

      // Esclude l'ultimo messaggio (placeholder vuoto) dalla history inviata
      final history = _messages.sublist(0, _messages.length - 1);
      final apiMessages = [
        {'role': 'system', 'content': systemPrompt},
        ...history
            .where((m) => m.role == 'user' || m.role == 'assistant')
            .map((m) => {'role': m.role, 'content': m.content}),
      ];

      print("---------- PROMPT INVIATO ----------");
      print(systemPrompt);
      print("------------------------------------");

      // ── Richiesta HTTP con streaming ──────────────────
      final request = http.Request(
        'POST',
        Uri.parse('https://api.openai.com/v1/chat/completions'),
      );
      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      });
      request.body = jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': apiMessages,
        'temperature': 0.7,
        'stream': true, // <-- abilita lo streaming SSE
      });

      final streamedResponse = await http.Client().send(request);

      if (streamedResponse.statusCode != 200) {
        _showError("Errore API: ${streamedResponse.statusCode}");
        return;
      }

      // ── Lettura chunk SSE ─────────────────────────────
      final responseBuffer = StringBuffer(); // testo accumulato della risposta
      String lineBuffer = '';               // frammento di riga incompleta

      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        // Aggiunge il chunk al buffer di riga e processa solo le righe complete
        lineBuffer += chunk;

        while (lineBuffer.contains('\n')) {
          final newlineIndex = lineBuffer.indexOf('\n');
          final line = lineBuffer.substring(0, newlineIndex).trim();
          lineBuffer = lineBuffer.substring(newlineIndex + 1);

          if (!line.startsWith('data: ')) continue;

          final jsonStr = line.substring(6); // rimuove "data: "
          if (jsonStr == '[DONE]') break;

          try {
            final data = jsonDecode(jsonStr);
            final delta =
                data['choices'][0]['delta']['content'] as String? ?? '';
            if (delta.isEmpty) continue;

            responseBuffer.write(delta);

            // Aggiorna il messaggio in-place e ridisegna
            if (mounted) {
              setState(() => assistantMessage.content = responseBuffer.toString());
              _scrollToBottom();
            }
          } catch (_) {
            // Chunk parziale o malformato: ignorato
          }
        }
      }

      // Se per qualsiasi motivo non è arrivato niente
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
      // Rimuove il placeholder vuoto prima di aggiungere l'errore
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
    return Scaffold(
      appBar: AppBar(title: const Text('Coach AI')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              // Il _TypingIndicator appare solo se sta caricando
              // E il messaggio AI è ancora vuoto
              itemCount: _messages.length +
                  (_loading && _messages.last.content.isEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) return const _TypingIndicator();
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Chiedi al coach...',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _loading ? null : _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// CLASSI DI SUPPORTO UI
// ──────────────────────────────────────────────

// ⚠️ content è ora var (non final) per supportare l'aggiornamento in streaming
class _ChatMessage {
  final String role;
  String content; // <-- mutabile
  _ChatMessage({required this.role, required this.content});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final isError = message.role == 'error';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isError
              ? Colors.red.shade900
              : isUser
                  ? Colors.blue.shade700
                  : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.content,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Text(
        "Il Coach sta pensando...",
        style: TextStyle(
            fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
      ),
    );
  }
}
