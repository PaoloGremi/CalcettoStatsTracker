import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../models/player.dart';
import '../data/player_icons.dart';
import '../widgets/player_avatar.dart';
import '../theme/app_theme.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  Future<String> _copyImageToAppDir(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'player_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
    final dest = p.join(appDir.path, fileName);
    await File(sourcePath).copy(dest);
    return dest;
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataService>(context);
    final players = data.getAllPlayers()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const FifaLabel('Rosa Giocatori', color: AppTheme.textPrimary, fontSize: 13),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: players.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_outline, size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  FifaLabel('Nessun giocatore', color: AppTheme.textMuted, fontSize: 12),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              itemCount: players.length,
              itemBuilder: (_, i) => _PlayerRow(
                player: players[i],
                onChanged: () => setState(() {}),
                copyImage: _copyImageToAppDir,
              ),
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.person_add_rounded),
        onPressed: () => _showAddDialog(context),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final data = Provider.of<DataService>(context, listen: false);
    final nameCtrl = TextEditingController();
    String? selectedRole;
    String selectedIcon = 'person';
    String? pickedImagePath;
    bool useGallery = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: const FifaLabel('Nuovo Giocatore', color: AppTheme.accentGreen, fontSize: 12),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar picker
                GestureDetector(
                  onTap: () async {
                    final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery, imageQuality: 85, maxWidth: 512, maxHeight: 512);
                    if (picked != null) {
                      final copied = await _copyImageToAppDir(picked.path);
                      setD(() { pickedImagePath = copied; useGallery = true; });
                    }
                  },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surfaceAlt,
                          border: Border.all(color: AppTheme.accentGreen.withOpacity(0.4), width: 2),
                        ),
                        child: useGallery && pickedImagePath != null
                            ? ClipOval(child: Image.file(File(pickedImagePath!), fit: BoxFit.cover))
                            : const Icon(Icons.add_a_photo_rounded, color: AppTheme.textMuted, size: 28),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.accentGreen),
                        child: const Icon(Icons.edit, size: 12, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (useGallery)
                  TextButton(
                    onPressed: () => setD(() { pickedImagePath = null; useGallery = false; }),
                    child: const FifaLabel('Usa icona predefinita', color: AppTheme.textSecondary),
                  ),
                if (!useGallery) ...[
                  DropdownButtonFormField<String>(
                    value: selectedIcon,
                    decoration: const InputDecoration(labelText: 'ICONA'),
                    dropdownColor: AppTheme.surfaceAlt,
                    items: availableIcons.map((icon) => DropdownMenuItem(
                      value: icon.key,
                      child: Row(children: [
                        icon.isAsset
                            ? Image.asset(icon.assetPath!, width: 24, height: 24)
                            : Icon(icon.iconData, size: 24, color: AppTheme.textPrimary),
                        const SizedBox(width: 8),
                        Text(icon.key, style: const TextStyle(color: AppTheme.textPrimary)),
                      ]),
                    )).toList(),
                    onChanged: (v) => setD(() => selectedIcon = v ?? selectedIcon),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'NOME'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'RUOLO'),
                  dropdownColor: AppTheme.surfaceAlt,
                  items: const [
                    DropdownMenuItem(value: 'P', child: Text('P — Portiere', style: TextStyle(color: AppTheme.textPrimary))),
                    DropdownMenuItem(value: 'D', child: Text('D — Difensore', style: TextStyle(color: AppTheme.textPrimary))),
                    DropdownMenuItem(value: 'C', child: Text('C — Centrocampista', style: TextStyle(color: AppTheme.textPrimary))),
                    DropdownMenuItem(value: 'A', child: Text('A — Attaccante', style: TextStyle(color: AppTheme.textPrimary))),
                  ],
                  onChanged: (v) => setD(() => selectedRole = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const FifaLabel('Annulla', color: AppTheme.textSecondary),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || selectedRole == null) return;
                Navigator.pop(context, true);
              },
              child: const Text('AGGIUNGI'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && nameCtrl.text.trim().isNotEmpty) {
      await data.addPlayer(nameCtrl.text.trim(), selectedIcon,
          role: selectedRole!, imagePath: useGallery ? pickedImagePath : null);
      setState(() {});
    }
  }
}

class _PlayerRow extends StatelessWidget {
  final Player player;
  final VoidCallback onChanged;
  final Future<String> Function(String) copyImage;
  const _PlayerRow({required this.player, required this.onChanged, required this.copyImage});

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataService>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: GestureDetector(
          onTap: () async {
            final picked = await ImagePicker().pickImage(
                source: ImageSource.gallery, imageQuality: 85, maxWidth: 512, maxHeight: 512);
            if (picked != null) {
              final copied = await copyImage(picked.path);
              player.imagePath = copied;
              await data.updatePlayer(player);
              onChanged();
            }
          },
          child: PlayerAvatar(player: player, radius: 22),
        ),
        title: Text(player.name.toUpperCase(),
          style: const TextStyle(color: AppTheme.textPrimary,
              fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: FifaBadge(player.role, color: AppTheme.accentBlue),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: AppTheme.textSecondary, size: 20),
              onPressed: () async {
                final ctrl = TextEditingController(text: player.name);
                final res = await showDialog<String>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppTheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppTheme.border)),
                    title: const FifaLabel('Modifica Nome', color: AppTheme.accentGreen, fontSize: 11),
                    content: TextField(controller: ctrl,
                        style: const TextStyle(color: AppTheme.textPrimary)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context),
                          child: const FifaLabel('Annulla', color: AppTheme.textSecondary)),
                      ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text),
                          child: const Text('SALVA')),
                    ],
                  ),
                );
                if (res != null && res.trim().isNotEmpty) {
                  player.name = res.trim();
                  await data.updatePlayer(player);
                  onChanged();
                }
              },
            ),
            // Delete
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.accentRed, size: 20),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppTheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: AppTheme.accentRed.withOpacity(0.4))),
                    title: const FifaLabel('Elimina Giocatore?', color: AppTheme.accentRed, fontSize: 11),
                    content: const Text('Il giocatore verrà rimosso da tutte le partite.',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false),
                          child: const FifaLabel('No', color: AppTheme.textSecondary)),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed,
                            foregroundColor: Colors.white),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('ELIMINA'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  if (player.imagePath != null) {
                    final f = File(player.imagePath!);
                    if (await f.exists()) await f.delete();
                  }
                  await data.deletePlayer(player.id);
                  onChanged();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
