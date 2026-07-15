import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/player_avatar.dart';
import '../../domain/entities/player.dart';
import '../controllers/players_controller.dart';
import '../widgets/player_form_dialog.dart';

/// Schermata "Rosa Giocatori" — sostituisce `screens/players_screen.dart`,
/// stessa UI/UX, ma passa dal layer domain/data della feature Players
/// invece di leggere `DataService` direttamente.
///
/// Wrapper sottile che cabla il [PlayersController] tramite get_it; tutto
/// il contenuto vero e proprio è in [PlayersView], che non conosce get_it
/// e legge solo dal `Provider` — così è testabile iniettando un
/// controller fake/mock senza toccare il service locator.
class PlayersPage extends StatelessWidget {
  const PlayersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PlayersController>(
      create: (_) => getIt<PlayersController>()..load(),
      child: const PlayersView(),
    );
  }
}

/// Contenuto della schermata Giocatori. Legge [PlayersController] dal
/// `Provider` più vicino nell'albero — nei test viene fornito con
/// `ChangeNotifierProvider.value(value: fakeController)`.
class PlayersView extends StatelessWidget {
  const PlayersView({super.key});

  Future<String> _copyImageToAppDir(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName =
        'player_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
    final dest = p.join(appDir.path, fileName);
    await File(sourcePath).copy(dest);
    return dest;
  }

  Future<String?> _pickAndCopyImage() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512);
    if (picked == null) return null;
    return _copyImageToAppDir(picked.path);
  }

  Future<void> _showAddDialog(
      BuildContext context, PlayersController controller) async {
    final result = await showDialog<PlayerFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PlayerFormDialog(pickImage: _pickAndCopyImage),
    );
    if (result == null) return;

    await controller.add(
      name: result.name,
      icon: 'person',
      role: result.role,
      imagePath: result.imagePath,
    );
  }

  Future<void> _showEditDialog(
      BuildContext context, PlayersController controller, Player player) async {
    final result = await showDialog<PlayerFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          PlayerFormDialog(pickImage: _pickAndCopyImage, initialPlayer: player),
    );
    if (result == null) return;

    await controller.update(player.copyWith(
      name: result.name,
      role: result.role,
      imagePath: result.imagePath,
    ));
  }

  Future<void> _confirmDelete(
      BuildContext context, PlayersController controller, Player player) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppTheme.accentRed.withValues(alpha: 0.4))),
        title: const FifaLabel('Elimina Giocatore?',
            color: AppTheme.accentRed, fontSize: 11),
        content: const Text('Il giocatore verrà rimosso da tutte le partite.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const FifaLabel('No', color: AppTheme.textSecondary)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentRed,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ELIMINA'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    if (player.imagePath != null) {
      final f = File(player.imagePath!);
      if (await f.exists()) await f.delete();
    }
    await controller.remove(player.id);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayersController>();
    final players = controller.players;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const FifaLabel('Rosa Giocatori',
            color: AppTheme.textPrimary, fontSize: 13),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: controller.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentGreen))
          : players.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outline,
                          size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      FifaLabel('Nessun giocatore',
                          color: AppTheme.textMuted, fontSize: 12),
                    ],
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  itemCount: players.length,
                  itemBuilder: (_, i) => _PlayerRow(
                    player: players[i],
                    onEdit: () =>
                        _showEditDialog(context, controller, players[i]),
                    onDelete: () =>
                        _confirmDelete(context, controller, players[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, controller),
        child: const Icon(Icons.person_add_rounded),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow(
      {required this.player, required this.onEdit, required this.onDelete});

  final Player player;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: PlayerAvatar(
            name: player.name,
            icon: player.icon,
            imagePath: player.imagePath,
            radius: 22),
        title: Text(player.name.toUpperCase(),
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FifaBadge(player.role,
                  color: switch (player.role) {
                    'P' => AppTheme.accentGold,
                    'D' => AppTheme.accentBlue,
                    'C' => AppTheme.accentGreen,
                    'A' => AppTheme.accentRed,
                    _ => AppTheme.textMuted,
                  }),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded,
                  color: AppTheme.textSecondary, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.accentRed, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
