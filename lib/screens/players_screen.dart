import 'package:calcetto_tracker/data/player_icons.dart';
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
          final nameController = TextEditingController();
          String? selectedRole;
          String selectedIcon = 'person'; // default icon

          final res = await showDialog<Map<String, String>>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Nuovo giocatore'),
              content: StatefulBuilder(
                builder: (context, setStateDialog) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nome giocatore'),
                      ),
                      const SizedBox(height: 16),

                  
          DropdownButtonFormField<String>(
            initialValue: selectedIcon,
            decoration: const InputDecoration(labelText: 'Icona giocatore'),
            items: availableIcons.map((playerIcon) {
              return DropdownMenuItem(
              value: playerIcon.key,
              child: Row(
                children: [
                playerIcon.isAsset
                ? Image.asset(playerIcon.assetPath!, width: 24, height: 24)
                : Icon(playerIcon.iconData, size: 24),
                const SizedBox(width: 8),
                Text(playerIcon.key),
              ],
            ),
          );
        }).toList(),
  onChanged: (val) {
    setStateDialog(() {
      selectedIcon = val ?? selectedIcon;
    });
  },
),

                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        decoration: const InputDecoration(labelText: 'Ruolo'),
                        items: const [
                          DropdownMenuItem(value: 'P', child: Text('P - Portiere')),
                          DropdownMenuItem(value: 'D', child: Text('D - Difensore')),
                          DropdownMenuItem(value: 'C', child: Text('C - Centrocampista')),
                          DropdownMenuItem(value: 'A', child: Text('A - Attaccante')),
                        ],
                        onChanged: (val) => setStateDialog(() => selectedRole = val),
                      ),
                    ],
                  );
                },
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annulla')),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty || selectedRole == null) return;
                    Navigator.pop(context, {
                      'name': nameController.text.trim(),
                      'icon': selectedIcon,
                      'role': selectedRole!,
                    });
                  },
                  child: const Text('Aggiungi'),
                ),
              ],
            ),
          );

          if (res != null && res['name']!.isNotEmpty) {
            await data.addPlayer(res['name']!,res['icon']! , role: res['role']!);
            setState(() {});
          }
        },
      ),
    );
  }
}
