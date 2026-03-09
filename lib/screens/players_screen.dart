import 'dart:io';
import 'package:calcetto_tracker/data/player_icons.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
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

    players.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

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
        onPressed: () => _showAddPlayerDialog(context),
      ),
    );
  }

  /// Copia l'immagine scelta nella cartella documenti dell'app (stabile)
  Future<String> _copyImageToAppDir(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'player_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
    final destPath = p.join(appDir.path, fileName);
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  Future<void> _showAddPlayerDialog(BuildContext context) async {
    final data = Provider.of<DataService>(context, listen: false);
    final nameController = TextEditingController();
    String? selectedRole;
    String selectedIcon = 'person';
    String? pickedImagePath; // path locale dopo copia
    bool useGalleryImage = false;

    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Nuovo giocatore'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Avatar preview ──────────────────────────────
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                        maxWidth: 512,
                        maxHeight: 512,
                      );
                      if (picked != null) {
                        final copied = await _copyImageToAppDir(picked.path);
                        setStateDialog(() {
                          pickedImagePath = copied;
                          useGalleryImage = true;
                        });
                      }
                    },
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.grey[700],
                          backgroundImage: useGalleryImage && pickedImagePath != null
                              ? FileImage(File(pickedImagePath!))
                              : null,
                          child: !useGalleryImage
                              ? const Icon(Icons.add_a_photo, size: 32, color: Colors.white70)
                              : null,
                        ),
                        if (useGalleryImage)
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.green,
                            child: const Icon(Icons.edit, size: 14, color: Colors.white),
                          ),
                      ],
                    ),
                  ),

                  // ── Toggle: galleria vs icona ────────────────────
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        icon: Icon(
                          useGalleryImage ? Icons.check_circle : Icons.photo_library,
                          color: useGalleryImage ? Colors.green : null,
                        ),
                        label: Text(useGalleryImage ? 'Foto galleria selezionata' : 'Scegli dalla galleria'),
                        onPressed: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 85,
                            maxWidth: 512,
                            maxHeight: 512,
                          );
                          if (picked != null) {
                            final copied = await _copyImageToAppDir(picked.path);
                            setStateDialog(() {
                              pickedImagePath = copied;
                              useGalleryImage = true;
                            });
                          }
                        },
                      ),
                      if (useGalleryImage)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          tooltip: 'Rimuovi foto, usa icona',
                          onPressed: () {
                            setStateDialog(() {
                              pickedImagePath = null;
                              useGalleryImage = false;
                            });
                          },
                        ),
                    ],
                  ),

                  // ── Icona predefinita (visibile solo se NON usa galleria) ──
                  if (!useGalleryImage) ...[
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedIcon,
                      decoration: const InputDecoration(labelText: 'Icona predefinita'),
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
                  ],

                  // ── Nome ────────────────────────────────────────
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nome giocatore'),
                    textCapitalization: TextCapitalization.words,
                  ),

                  // ── Ruolo ───────────────────────────────────────
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
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
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty || selectedRole == null) return;
                  Navigator.pop(context, true);
                },
                child: const Text('Aggiungi'),
              ),
            ],
          );
        },
      ),
    );

    if (res == true && nameController.text.trim().isNotEmpty) {
      await data.addPlayer(
        nameController.text.trim(),
        selectedIcon,
        role: selectedRole!,
        imagePath: useGalleryImage ? pickedImagePath : null,
      );
      setState(() {});
    }
  }
}
