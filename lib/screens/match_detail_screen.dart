

import 'package:calcetto_tracker/data/player_icons.dart';
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
              final icona = player?.icon ?? 'person';
              final ruolo = player?.role ?? 'N/D';
              final voto = match.votes[playerId] ?? 0;
              final commento = match.comments[playerId] ?? '';
              return _buildPlayerTile(name, icona, ruolo, voto, commento);
            }),
            const SizedBox(height: 16),

            const Text('Squadra Colorata', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...teamBPlayers.map((name) {
              final playerId = match.teamB.firstWhere(
                (id) => HiveBoxes.playersBox.get(id)?.name == name,
                orElse: () => '',
              );
              final player = HiveBoxes.playersBox.get(playerId);
              final icona = player?.icon ?? 'person';
              final ruolo = player?.role ?? 'N/D';
              final voto = match.votes[playerId] ?? 0;
              final commento = match.comments[playerId] ?? '';
              
              return _buildPlayerTile(name, icona, ruolo, voto, commento);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerTile(String name, String icon, String role, int voto, String commento) {

    final iconData = getPlayerIcon(icon);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
      leading: iconData.isAsset
        ? CircleAvatar(
        radius: 22,
        backgroundImage: AssetImage(iconData.assetPath!),
        )
      : CircleAvatar(
        radius: 22,
        child: Icon(iconData.iconData, size: 24),
        ),

        title: Text('$name - $role'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voto: $voto'),
            if (commento.isNotEmpty)
              Text(
                commento,
                style: const TextStyle(fontStyle: FontStyle.normal, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
