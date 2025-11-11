import 'package:calcetto_tracker/screens/vote_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../models/match_model.dart';
import '../services/data_service.dart';
import 'package:uuid/uuid.dart';

class NewMatchScreen extends StatefulWidget {
  const NewMatchScreen({super.key});

  @override
  State<NewMatchScreen> createState() => _NewMatchScreenState();
}

class _NewMatchScreenState extends State<NewMatchScreen> {
  final Map<String, bool> selectedA = {};
  final Map<String, bool> selectedB = {};
  int scoreA = 0;
  int scoreB = 0;

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataService>(context);
    final players = data.getAllPlayers();

    return Scaffold(
      appBar: AppBar(title: const Text('Nuova Partita')),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          const Text('Squadra Bianca', style: TextStyle(fontWeight: FontWeight.bold)),
          ...players.map((p) => CheckboxListTile(
                title: Text(p.name),
                value: selectedA[p.id] ?? false,
                onChanged: (v) {
                  setState(() {
                    selectedA[p.id] = v!;
                    if (v && (selectedB[p.id] ?? false)) selectedB[p.id] = false;
                  });
                },
              )),
          const SizedBox(height: 10),
          const Text('Squadra Colorata', style: TextStyle(fontWeight: FontWeight.bold)),
          ...players.map((p) => CheckboxListTile(
                title: Text(p.name),
                value: selectedB[p.id] ?? false,
                onChanged: (v) {
                  setState(() {
                    selectedB[p.id] = v!;
                    if (v && (selectedA[p.id] ?? false)) selectedA[p.id] = false;
                  });
                },
              )),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(children: [
                const Text('Punteggio Bianchi'),
                SizedBox(
                  width: 60,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (v) => scoreA = int.tryParse(v) ?? 0,
                    decoration: const InputDecoration(hintText: '0'),
                  ),
                ),
              ]),
              Column(children: [
                const Text('Punteggio Colorati'),
                SizedBox(
                  width: 60,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (v) => scoreB = int.tryParse(v) ?? 0,
                    decoration: const InputDecoration(hintText: '0'),
                  ),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 20),

          
          ElevatedButton(
  onPressed: () async {
    final teamAIds = selectedA.entries.where((e) => e.value).map((e) => e.key).toList();
    final teamBIds = selectedB.entries.where((e) => e.value).map((e) => e.key).toList();

    if (teamAIds.isEmpty || teamBIds.isEmpty) return;

    final match = MatchModel(
      id: const Uuid().v4(),
      date: DateTime.now(),
      teamA: teamAIds,
      teamB: teamBIds,
      scoreA: scoreA,
      scoreB: scoreB,
    );

    await data.addMatch(match);

    // Apri la pagina dei voti subito dopo
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VoteScreen(match: match)),
    ).then((_) => Navigator.pop(context)); // torna alla home dopo
  },
  child: const Text('Salva Partita e Vota Giocatori'),
),

        ],
      ),
    );
  }
}
