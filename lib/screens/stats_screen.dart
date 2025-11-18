import 'package:calcetto_tracker/data/player_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataService>(context);
    final players = data.getAllPlayers();
    final matches = data.getAllMatches();

    

    // Calcola statistiche
    final stats = <String, Map<String, dynamic>>{};

    for (var player in players) {
      int gamesPlayed = 0;
      double totalVotes = 0;
      int votesCount = 0;

      for (var match in matches) {
        if (match.teamA.contains(player.id) || match.teamB.contains(player.id)) {
          gamesPlayed++;
          if (match.votes.containsKey(player.id)) {
            totalVotes += match.votes[player.id]!;
            votesCount++;
          }
        }
      }

      final avgVote = votesCount > 0 ? totalVotes / gamesPlayed : 0.0;

      stats[player.id] = {
        'games': gamesPlayed,
        'avgVote': avgVote,
      };
    }
    

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiche giocatori')),
      body: ListView(
        children: players.map((player) {
          final s = stats[player.id]!;
          final icona = player.icon;
          final iconData = getPlayerIcon(icona);
          return ListTile(
            //--------------------------------------------------------
            leading: iconData.isAsset
        ? CircleAvatar(
        radius: 22,
        backgroundImage: AssetImage(iconData.assetPath!),
        )
      : CircleAvatar(
        radius: 22,
        child: Icon(iconData.iconData, size: 24),
        ),
            //------------------------------------------------------
            title: Text(player.name +' - '+ player.role),
            subtitle: Text(
              'Partite giocate: ${s['games']}, Voto medio: ${s['avgVote'].toStringAsFixed(2)}',
            ),
          );
        }).toList(),
      ),
    );
  }
}
