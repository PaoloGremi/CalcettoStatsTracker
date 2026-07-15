import 'package:flutter/material.dart';

import '../models/player_model.dart';
import '../theme/app_theme.dart';
import 'player_avatar.dart';

/// Bottom sheet con ricerca e lista giocatori, usato da [TeamSelector] per
/// selezionare i partecipanti di una squadra. Prima di questo widget la
/// stessa classe privata `_PlayerPickerSheet` era duplicata identica in
/// 3 form diversi (nuova partita, modifica partita, locandina).
class PlayerPickerSheet extends StatefulWidget {
  final List<PlayerModel> players;
  final Map<String, bool> selected;
  final Color accent;
  final void Function(String, bool) onToggle;

  const PlayerPickerSheet({
    required this.players,
    required this.selected,
    required this.accent,
    required this.onToggle,
    super.key,
  });

  @override
  State<PlayerPickerSheet> createState() => _PlayerPickerSheetState();
}

class _PlayerPickerSheetState extends State<PlayerPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.players
        .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ── Handle ───────────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Titolo ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.group_rounded, color: widget.accent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Seleziona giocatori',
                    style: TextStyle(
                      color: widget.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  // Contatore selezionati
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.selected.values.where((v) => v).length} sel.',
                      style: TextStyle(
                        color: widget.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Barra di ricerca ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Cerca giocatore…',
                    hintStyle: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppTheme.textMuted, size: 18),
                    suffixIcon: _query.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                            child: const Icon(Icons.close_rounded,
                                color: AppTheme.textMuted, size: 16),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ),

            Container(height: 1, color: AppTheme.border),

            // ── Lista giocatori ───────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Nessun giocatore trovato',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => Container(
                        height: 1,
                        color: AppTheme.border,
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      itemBuilder: (_, i) {
                        final p = filtered[i];
                        final isSelected = widget.selected[p.id] ?? false;
                        return InkWell(
                          onTap: () {
                            widget.onToggle(p.id, !isSelected);
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 11),
                            child: Row(
                              children: [
                                PlayerAvatar(
                                    name: p.name,
                                    icon: p.icon,
                                    imagePath: p.imagePath,
                                    radius: 18),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    p.name.toUpperCase(),
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppTheme.textPrimary
                                          : AppTheme.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                FifaBadge(p.role,
                                    color: isSelected
                                        ? widget.accent
                                        : AppTheme.textMuted),
                                const SizedBox(width: 10),
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? widget.accent
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? widget.accent
                                          : AppTheme.border,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check_rounded,
                                          size: 14, color: Colors.black)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // ── Bottone chiudi ────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accent,
                  foregroundColor: Colors.black,
                ),
                child: const Text('CONFERMA'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
