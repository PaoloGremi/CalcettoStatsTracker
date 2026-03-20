import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../models/field_model.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';

class FieldsScreen extends StatefulWidget {
  const FieldsScreen({super.key});

  @override
  State<FieldsScreen> createState() => _FieldsScreenState();
}

class _FieldsScreenState extends State<FieldsScreen> {
  Future<String> _copyImageToAppDir(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName =
        'field_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
    final dest = p.join(appDir.path, fileName);
    await File(sourcePath).copy(dest);
    return dest;
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final data = Provider.of<DataService>(context, listen: false);
    final nameCtrl    = TextEditingController();
    final addressCtrl = TextEditingController();
    String? pickedImagePath;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: const Row(children: [
            Icon(Icons.stadium_rounded, color: AppTheme.accentGreen, size: 18),
            SizedBox(width: 8),
            FifaLabel('Nuovo Campo', color: AppTheme.accentGreen, fontSize: 11),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Foto campo ──────────────────────────────────
                GestureDetector(
                  onTap: () async {
                    final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                        maxWidth: 1024,
                        maxHeight: 768);
                    if (picked != null) {
                      final copied = await _copyImageToAppDir(picked.path);
                      setD(() => pickedImagePath = copied);
                    }
                  },
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.accentGreen.withOpacity(0.3),
                          width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: pickedImagePath != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(File(pickedImagePath!),
                                  fit: BoxFit.cover),
                              Positioned(
                                bottom: 6, right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit_rounded,
                                      color: AppTheme.accentGreen, size: 14),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded,
                                  color: AppTheme.accentGreen.withOpacity(0.6),
                                  size: 36),
                              const SizedBox(height: 8),
                              const FifaLabel('Aggiungi Foto',
                                  color: AppTheme.textMuted, fontSize: 9),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                // ── Nome ────────────────────────────────────────
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    labelText: 'NOME CAMPO',
                    hintText: 'es. San Francesco',
                    prefixIcon: Icon(Icons.stadium_rounded,
                        color: AppTheme.textMuted, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                // ── Indirizzo ───────────────────────────────────
                TextField(
                  controller: addressCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    labelText: 'INDIRIZZO',
                    hintText: 'es. Via Roma 10, Lodi',
                    prefixIcon: Icon(Icons.location_on_rounded,
                        color: AppTheme.textMuted, size: 18),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const FifaLabel('Annulla', color: AppTheme.textSecondary),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('AGGIUNGI'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && nameCtrl.text.trim().isNotEmpty) {
      await data.addField(
        nameCtrl.text.trim(),
        addressCtrl.text.trim(),
        imagePath: pickedImagePath,
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final data   = Provider.of<DataService>(context);
    final fields = data.getAllFields();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const FifaLabel('Campi di Gioco',
            color: AppTheme.textPrimary, fontSize: 13),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: fields.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stadium_outlined,
                      size: 52, color: AppTheme.textMuted.withOpacity(0.5)),
                  const SizedBox(height: 14),
                  const FifaLabel('Nessun campo',
                      color: AppTheme.textMuted, fontSize: 12),
                  const SizedBox(height: 6),
                  const Text('Tocca + per aggiungere il primo',
                      style: TextStyle(
                          color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              itemCount: fields.length,
              itemBuilder: (_, i) => _FieldCard(
                field: fields[i],
                copyImage: _copyImageToAppDir,
                onChanged: () => setState(() {}),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Card singolo campo
// ─────────────────────────────────────────────────────────────
class _FieldCard extends StatelessWidget {
  final FieldModel field;
  final Future<String> Function(String) copyImage;
  final VoidCallback onChanged;

  const _FieldCard({
    required this.field,
    required this.copyImage,
    required this.onChanged,
  });

  Future<void> _showEditDialog(BuildContext context) async {
    final data        = Provider.of<DataService>(context, listen: false);
    final nameCtrl    = TextEditingController(text: field.name);
    final addressCtrl = TextEditingController(text: field.address);
    String? newImagePath = field.imagePath;
    bool imageChanged = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: const Row(children: [
            Icon(Icons.edit_location_alt_rounded,
                color: AppTheme.accentGold, size: 18),
            SizedBox(width: 8),
            FifaLabel('Modifica Campo', color: AppTheme.accentGold, fontSize: 11),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Foto ────────────────────────────────────────
                GestureDetector(
                  onTap: () async {
                    final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                        maxWidth: 1024,
                        maxHeight: 768);
                    if (picked != null) {
                      final copied = await copyImage(picked.path);
                      setD(() {
                        newImagePath  = copied;
                        imageChanged  = true;
                      });
                    }
                  },
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.accentGold.withOpacity(0.3),
                          width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: newImagePath != null &&
                            File(newImagePath!).existsSync()
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(File(newImagePath!),
                                  fit: BoxFit.cover),
                              Positioned(
                                bottom: 6, right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit_rounded,
                                      color: AppTheme.accentGold, size: 14),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded,
                                  color: AppTheme.accentGold.withOpacity(0.6),
                                  size: 36),
                              const SizedBox(height: 8),
                              const FifaLabel('Cambia Foto',
                                  color: AppTheme.textMuted, fontSize: 9),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    labelText: 'NOME CAMPO',
                    prefixIcon: Icon(Icons.stadium_rounded,
                        color: AppTheme.textMuted, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    labelText: 'INDIRIZZO',
                    prefixIcon: Icon(Icons.location_on_rounded,
                        color: AppTheme.textMuted, size: 18),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const FifaLabel('Annulla', color: AppTheme.textSecondary),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('SALVA'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      field.name    = nameCtrl.text.trim();
      field.address = addressCtrl.text.trim();
      if (imageChanged) field.imagePath = newImagePath;
      await data.updateField(field);
      onChanged();
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final data = Provider.of<DataService>(context, listen: false);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppTheme.accentRed.withOpacity(0.4)),
        ),
        title: const FifaLabel('Elimina Campo?',
            color: AppTheme.accentRed, fontSize: 11),
        content: Text(
          'Vuoi eliminare "${field.name}"?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const FifaLabel('No', color: AppTheme.textSecondary),
          ),
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

    if (ok == true) {
      // Elimina l'immagine locale se esiste
      if (field.imagePath != null) {
        final f = File(field.imagePath!);
        if (await f.exists()) await f.delete();
      }
      await data.deleteField(field.id);
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage =
        field.imagePath != null && File(field.imagePath!).existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Immagine campo ──────────────────────────────────
          if (hasImage)
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Image.file(
                File(field.imagePath!),
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 90,
              width: double.infinity,
              color: AppTheme.surfaceAlt,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stadium_rounded,
                      size: 36,
                      color: AppTheme.textMuted.withOpacity(0.4)),
                  const SizedBox(height: 6),
                  const FifaLabel('Nessuna foto',
                      color: AppTheme.textMuted, fontSize: 9),
                ],
              ),
            ),

          // ── Info + azioni ───────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.name.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (field.address.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: AppTheme.textMuted, size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                field.address,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Edit
                IconButton(
                  icon: const Icon(Icons.edit_rounded,
                      color: AppTheme.textSecondary, size: 20),
                  onPressed: () => _showEditDialog(context),
                ),
                // Delete
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppTheme.accentRed, size: 20),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
