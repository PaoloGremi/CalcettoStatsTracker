import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../data/hive_boxes.dart';

class VoteScreen extends StatefulWidget {
  final MatchModel match;
  const VoteScreen({required this.match, super.key});

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
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
            if (!widget.match.votes.containsKey(id)) {
              widget.match.votes[id] = 5;
            }
            final commento = widget.match.comments[id] ?? '';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(playerName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Slider(
                      value: voto,
                      min: 1,
                      max: 10,
                      divisions: 18,
                      label: voto.toString(),
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
                      controller: TextEditingController(text: commento),
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
