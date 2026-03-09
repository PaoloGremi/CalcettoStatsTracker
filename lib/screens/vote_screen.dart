import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../data/hive_boxes.dart';
import '../widgets/player_avatar.dart';

class VoteScreen extends StatefulWidget {
  final MatchModel match;
  const VoteScreen({required this.match, super.key});

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  // ✅ FIX: controllers creati una volta sola nello State, non dentro build()
  late final Map<String, TextEditingController> _commentControllers;

  @override
  void initState() {
    super.initState();
    final allPlayers = [...widget.match.teamA, ...widget.match.teamB];

    // Inizializza voti di default e controller commenti
    _commentControllers = {};
    for (final id in allPlayers) {
      if (!widget.match.votes.containsKey(id)) {
        widget.match.votes[id] = 5.0;
      }
      _commentControllers[id] = TextEditingController(
        text: widget.match.comments[id] ?? '',
      );
    }
  }

  @override
  void dispose() {
    // ✅ FIX: dispose corretto dei controller
    for (final ctrl in _commentControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allPlayers = [...widget.match.teamA, ...widget.match.teamB];

    return Scaffold(
      appBar: AppBar(title: const Text('Vota e Commenta')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ...allPlayers.map((id) {
            final playerName =
                HiveBoxes.playersBox.get(id)?.name ?? 'Sconosciuto';
            final voto = widget.match.votes[id]?.toDouble() ?? 5.0;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (HiveBoxes.playersBox.get(id) != null)
                          PlayerAvatar(player: HiveBoxes.playersBox.get(id)!, radius: 20),
                        const SizedBox(width: 10),
                        Text(playerName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: voto,
                      min: 1,
                      max: 10,
                      divisions: 18,
                      label: voto.toStringAsFixed(1),
                      onChanged: (val) {
                        setState(() {
                          widget.match.votes[id] = val;
                        });
                      },
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Commento (opzionale)',
                        border: OutlineInputBorder(),
                      ),
                      // ✅ FIX: usa il controller persistente
                      controller: _commentControllers[id],
                      onChanged: (text) {
                        widget.match.comments[id] = text;
                      },
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await widget.match.save();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Salva voti e commenti'),
          ),
        ],
      ),
    );
  }
}
