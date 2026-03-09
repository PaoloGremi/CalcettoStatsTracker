import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../services/data_service.dart';
import '../widgets/player_avatar.dart';

class PlayerTile extends StatelessWidget {
  final Player player;
  final VoidCallback? onChanged;
  const PlayerTile({required this.player, this.onChanged, super.key});

  Future<String> _copyImageToAppDir(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'player_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
    final destPath = p.join(appDir.path, fileName);
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataService>(context, listen: false);

    return ListTile(
      leading: GestureDetector(
        onTap: () async {
          // Tap sull'avatar → cambia foto direttamente
          final picker = ImagePicker();
          final picked = await picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
            maxWidth: 512,
            maxHeight: 512,
          );
          if (picked != null) {
            final copied = await _copyImageToAppDir(picked.path);
            player.imagePath = copied;
            await data.updatePlayer(player);
            if (onChanged != null) onChanged!();
          }
        },
        child: PlayerAvatar(player: player, radius: 22),
      ),
      title: Text('${player.name} - ${player.role}'),
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
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annulla')),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(context, controller.text),
                        child: const Text('Salva')),
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
                  content: const Text(
                      'Vuoi eliminare questo giocatore (verrà rimosso dalle partite)?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('No')),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sì')),
                  ],
                ),
              );

              if (ok == true) {
                // Elimina anche il file immagine locale se esiste
                if (player.imagePath != null && player.imagePath!.isNotEmpty) {
                  final file = File(player.imagePath!);
                  if (await file.exists()) await file.delete();
                }
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
