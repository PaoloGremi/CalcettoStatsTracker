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
      int totalVotes = 0;
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
          return ListTile(
            title: Text(player.name),
            subtitle: Text(
              'Partite giocate: ${s['games']}, Voto medio: ${s['avgVote'].toStringAsFixed(2)}',
            ),
          );
        }).toList(),
      ),
    );
  }
}
