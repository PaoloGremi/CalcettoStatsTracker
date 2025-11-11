import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/data_service.dart';
import 'package:provider/provider.dart';

class PlayerTile extends StatelessWidget {
  final Player player;
  final VoidCallback? onChanged;
  const PlayerTile({required this.player, this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataService>(context, listen: false);

    return ListTile(
      leading: Image.asset(
        './assets/icons/player_icon.png',
        width: 40,
        height: 40,
      ),
      title: Text(player.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final controller = TextEditingController(text: player.name);
              final res = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Modifica nome'),
                  content: TextField(controller: controller),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
                    ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Salva')),
                  ],
                ),
              );

              if (res != null && res.trim().isNotEmpty) {
                player.name = res.trim();
                await data.updatePlayer(player);
                if (onChanged != null) onChanged!();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Elimina giocatore?'),
                  content: const Text('Vuoi eliminare questo giocatore (verrà rimosso dalle partite)?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                    ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sì')),
                  ],
                ),
              );

              if (ok == true) {
                await data.deletePlayer(player.id);
                if (onChanged != null) onChanged!();
              }
            },
          ),
        ],
      ),
    );
  }
}
