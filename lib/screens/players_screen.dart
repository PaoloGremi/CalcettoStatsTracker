import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../widgets/player_tile.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataService>(context);
    final players = data.getAllPlayers();

    return Scaffold(
      appBar: AppBar(title: const Text('Giocatori')),
      body: ListView.builder(
        itemCount: players.length,
        itemBuilder: (_, i) => PlayerTile(
          player: players[i],
          onChanged: () => setState(() {}),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final controller = TextEditingController();
          final res = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Nuovo giocatore'),
              content: TextField(controller: controller),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, controller.text),
                    child: const Text('Aggiungi')),
              ],
            ),
          );

          if (res != null && res.trim().isNotEmpty) {
            await data.addPlayer(res.trim());
            setState(() {});
          }
        },
      ),
    );
  }
}
