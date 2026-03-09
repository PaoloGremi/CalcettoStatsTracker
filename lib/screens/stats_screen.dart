import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../widgets/player_avatar.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataService>(context);
    final players = data.getAllPlayers();
    final matches = data.getAllMatches();

    // Ordina i giocatori in ordine alfabetico per nome
    players.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

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

      // ✅ FIX: dividere per votesCount (non gamesPlayed) per la media voti
      final avgVote = votesCount > 0 ? totalVotes / votesCount : 0.0;

      stats[player.id] = {
        'games': gamesPlayed,
        'avgVote': avgVote,
        'votesCount': votesCount,
      };
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiche giocatori')),
      body: ListView(
        children: players.map((player) {
          final s = stats[player.id]!;
          return ListTile(
            leading: PlayerAvatar(player: player, radius: 22),
            title: Text('${player.name} - ${player.role}'),
            subtitle: Text(
              'Partite giocate: ${s['games']}  •  Voto medio: ${(s['avgVote'] as double).toStringAsFixed(2)}',
            ),
          );
        }).toList(),
      ),
    );
  }
}
