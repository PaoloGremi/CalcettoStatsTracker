import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/player_avatar.dart';
import '../../domain/entities/player.dart';

/// Valore restituito da [PlayerFormDialog] quando l'utente conferma.
class PlayerFormResult {
  const PlayerFormResult(
      {required this.name, required this.role, this.imagePath});

  final String name;
  final String role;
  final String? imagePath;
}

/// Form "Nuovo giocatore" / "Modifica giocatore" — stesso dialog per
/// entrambi i casi: la differenza (titolo, colore accento, avatar di
/// fallback, obbligatorietà del ruolo) dipende solo dalla presenza di
/// [initialPlayer]. Prima di questo widget la stessa UI era duplicata
/// quasi identica in due punti di `players_screen.dart`.
class PlayerFormDialog extends StatefulWidget {
  const PlayerFormDialog({
    required this.pickImage,
    this.initialPlayer,
    super.key,
  });

  /// Se non null, il dialog si apre in modalità "modifica" precompilato
  /// con questi valori; altrimenti è in modalità "nuovo giocatore".
  final Player? initialPlayer;

  /// Apre il picker di sistema e copia l'immagine scelta nella cartella
  /// documenti dell'app, ritornando il path locale. Iniettata dal
  /// chiamante per non accoppiare il dialog a `image_picker`/`path_provider`.
  final Future<String?> Function() pickImage;

  @override
  State<PlayerFormDialog> createState() => _PlayerFormDialogState();
}

class _PlayerFormDialogState extends State<PlayerFormDialog> {
  late final TextEditingController _nameCtrl;
  String? _selectedRole;
  String? _pickedImagePath;

  bool get _isEdit => widget.initialPlayer != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialPlayer?.name ?? '');
    _selectedRole = widget.initialPlayer?.role;
    _pickedImagePath = widget.initialPlayer?.imagePath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final copied = await widget.pickImage();
    if (copied == null) return;
    if (!mounted) return;
    setState(() => _pickedImagePath = copied);
  }

  void _confirm() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    if (!_isEdit && _selectedRole == null) return;

    Navigator.pop(
      context,
      PlayerFormResult(
        name: name,
        role: _selectedRole!,
        imagePath: _pickedImagePath,
      ),
    );
  }

  Widget _buildAvatarPreview(Color accent) {
    final path = _pickedImagePath;
    if (path != null && File(path).existsSync()) {
      return ClipOval(child: Image.file(File(path), fit: BoxFit.cover));
    }
    final existing = widget.initialPlayer;
    if (existing != null) {
      return ClipOval(
        child: PlayerAvatar(
          name: existing.name,
          icon: existing.icon,
          radius: 40,
        ),
      );
    }
    return const Icon(Icons.add_a_photo_rounded,
        color: AppTheme.textMuted, size: 28);
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isEdit ? AppTheme.accentGold : AppTheme.accentGreen;

    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      title: FifaLabel(
        _isEdit ? 'Modifica Giocatore' : 'Nuovo Giocatore',
        color: accent,
        fontSize: _isEdit ? 11 : 12,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.surfaceAlt,
                        border: Border.all(
                            color: accent.withValues(alpha: 0.4), width: 2),
                      ),
                      child: _buildAvatarPreview(accent),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, color: accent),
                      child:
                          const Icon(Icons.edit, size: 12, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'NOME'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(labelText: 'RUOLO'),
                dropdownColor: AppTheme.surfaceAlt,
                items: const [
                  DropdownMenuItem(
                      value: 'P',
                      child: Text('P — Portiere',
                          style: TextStyle(color: AppTheme.textPrimary))),
                  DropdownMenuItem(
                      value: 'D',
                      child: Text('D — Difensore',
                          style: TextStyle(color: AppTheme.textPrimary))),
                  DropdownMenuItem(
                      value: 'C',
                      child: Text('C — Centrocampista',
                          style: TextStyle(color: AppTheme.textPrimary))),
                  DropdownMenuItem(
                      value: 'A',
                      child: Text('A — Attaccante',
                          style: TextStyle(color: AppTheme.textPrimary))),
                ],
                onChanged: (v) => setState(
                    () => _selectedRole = _isEdit ? (v ?? _selectedRole) : v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const FifaLabel('Annulla', color: AppTheme.textSecondary),
        ),
        ElevatedButton(
          style: _isEdit
              ? ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: Colors.black,
                )
              : null,
          onPressed: _confirm,
          child: Text(_isEdit ? 'SALVA' : 'AGGIUNGI'),
        ),
      ],
    );
  }
}
