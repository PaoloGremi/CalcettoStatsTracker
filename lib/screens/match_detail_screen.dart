import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../data/hive_boxes.dart';

class MatchDetailScreen extends StatelessWidget {
  final MatchModel match;
  const MatchDetailScreen({required this.match, super.key});

  @override
  Widget build(BuildContext context) {
    final teamAPlayers = match.teamA.map((id) => HiveBoxes.playersBox.get(id)?.name ?? 'Sconosciuto').toList();
    final teamBPlayers = match.teamB.map((id) => HiveBoxes.playersBox.get(id)?.name ?? 'Sconosciuto').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Dettaglio partita')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            Text(
              'Risultato: ${match.scoreA} - ${match.scoreB}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            const Text('Squadra Bianca', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...teamAPlayers.map((name) {
              final playerId = match.teamA.firstWhere(
                (id) => HiveBoxes.playersBox.get(id)?.name == name,
                orElse: () => '',
              );
              final player = HiveBoxes.playersBox.get(playerId);
              final ruolo = player?.role ?? 'N/D';
              final voto = match.votes[playerId] ?? 0;
              final commento = match.comments[playerId] ?? '';
              return _buildPlayerTile(name, ruolo, voto, commento);
            }),
            const SizedBox(height: 16),

            const Text('Squadra Colorata', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...teamBPlayers.map((name) {
              final playerId = match.teamB.firstWhere(
                (id) => HiveBoxes.playersBox.get(id)?.name == name,
                orElse: () => '',
              );
              final player = HiveBoxes.playersBox.get(playerId);
              final ruolo = player?.role ?? 'N/D';
              final voto = match.votes[playerId] ?? 0;
              final commento = match.comments[playerId] ?? '';
              return _buildPlayerTile(name, ruolo, voto, commento);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerTile(String name, String role, int voto, String commento) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.person),
        title: Text('$name - $role'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voto: $voto'),
            if (commento.isNotEmpty)
              Text(
                'Commento: $commento',
                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
