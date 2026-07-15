import 'package:flutter/material.dart';

import '../models/player_model.dart';
import '../theme/app_theme.dart';
import 'player_avatar.dart';
import 'player_picker_sheet.dart';

/// Selettore squadra: bottone che apre [PlayerPickerSheet] e chip dei
/// giocatori selezionati. Prima di questo widget la stessa classe privata
/// `_TeamSelector` era duplicata identica in 3 form diversi (nuova
/// partita, modifica partita, locandina).
class TeamSelector extends StatefulWidget {
  final List<PlayerModel> players;
  final Map<String, bool> selected;
  final Color accent;
  final void Function(String, bool) onToggle;

  const TeamSelector({
    required this.players,
    required this.selected,
    required this.accent,
    required this.onToggle,
    super.key,
  });

  @override
  State<TeamSelector> createState() => _TeamSelectorState();
}

class _TeamSelectorState extends State<TeamSelector> {
  void _openPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlayerPickerSheet(
        players: widget.players,
        selected: widget.selected,
        accent: widget.accent,
        onToggle: (id, val) {
          widget.onToggle(id, val);
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedPlayers =
        widget.players.where((p) => widget.selected[p.id] == true).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Bottone apri selezione ────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _openPicker,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Icon(Icons.group_add_rounded, color: widget.accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedPlayers.isEmpty
                          ? 'Seleziona giocatori…'
                          : '${selectedPlayers.length} giocator${selectedPlayers.length == 1 ? 'e' : 'i'} selezionat${selectedPlayers.length == 1 ? 'o' : 'i'}',
                      style: TextStyle(
                        color: selectedPlayers.isEmpty
                            ? AppTheme.textMuted
                            : AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: selectedPlayers.isEmpty
                            ? FontWeight.normal
                            : FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(Icons.expand_more_rounded,
                      color: widget.accent, size: 22),
                ],
              ),
            ),
          ),

          // ── Chips giocatori selezionati ───────────────────────
          if (selectedPlayers.isNotEmpty) ...[
            Container(
                height: 1,
                color: AppTheme.border,
                margin: const EdgeInsets.symmetric(horizontal: 14)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: selectedPlayers
                    .map((p) => GestureDetector(
                          onTap: () {
                            widget.onToggle(p.id, false);
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: widget.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: widget.accent.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PlayerAvatar(
                                    name: p.name,
                                    icon: p.icon,
                                    imagePath: p.imagePath,
                                    radius: 10),
                                const SizedBox(width: 6),
                                Text(
                                  p.name.toUpperCase(),
                                  style: TextStyle(
                                    color: widget.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.close_rounded,
                                    size: 12, color: widget.accent),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
