import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../screens/match_promo_page.dart';
import '../screens/fields_screen.dart';
import '../services/data_service.dart';
import '../models/player.dart';
import '../widgets/player_avatar.dart';
import '../theme/app_theme.dart';

class MatchPromoFormPage extends StatefulWidget {
  const MatchPromoFormPage({super.key});

  @override
  State<MatchPromoFormPage> createState() => _MatchPromoFormPageState();
}

class _MatchPromoFormPageState extends State<MatchPromoFormPage> {
  final TextEditingController _prezzoCtrl = TextEditingController();
  final Map<String, bool> selectedA = {};
  final Map<String, bool> selectedB = {};
  String? fieldId;
  DateTime? selectedDateTime;
  String? numberOfPlayers;

  @override
  void dispose() {
    _prezzoCtrl.dispose();
    super.dispose();
  }

  static const _formats = ['3 vs 3', '4 vs 4', '5 vs 5', '6 vs 6', '8 vs 8', '9 vs 9', '11 vs 11'];

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataService>(context);
    final players = data.getAllPlayers()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final allFields = data.getAllFields();

    // Se il campo selezionato è stato eliminato, resetta
    if (fieldId != null && !allFields.any((f) => f.id == fieldId)) {
      fieldId = null;
    }
    final selectedField = fieldId != null
        ? allFields.where((f) => f.id == fieldId).firstOrNull
        : null;

    final teamAIds = selectedA.entries.where((e) => e.value).map((e) => e.key).toList();
    final teamBIds = selectedB.entries.where((e) => e.value).map((e) => e.key).toList();
    final canGenerate = teamAIds.isNotEmpty && teamBIds.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const FifaLabel('Promuovi Partita', color: AppTheme.textPrimary, fontSize: 13),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [

          // ── DATA E ORA ────────────────────────────────────────
          const FifaSectionHeader('Data e Ora'),
          _FifaCard(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (date == null || !mounted) return;
                final time = await showTimePicker(
                    context: context, initialTime: TimeOfDay.now());
                if (time == null) return;
                setState(() => selectedDateTime = DateTime(
                    date.year, date.month, date.day, time.hour, time.minute));
              },
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: AppTheme.accentGreen, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    selectedDateTime != null
                        ? DateFormat('EEE dd MMM yyyy · HH:mm', 'it_IT')
                            .format(selectedDateTime!)
                        : 'Seleziona data e ora',
                    style: TextStyle(
                      color: selectedDateTime != null
                          ? AppTheme.textPrimary : AppTheme.textMuted,
                      fontSize: 13,
                      fontWeight: selectedDateTime != null
                          ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
                ],
              ),
            ),
          ),

          // ── DETTAGLI PARTITA ──────────────────────────────────
          const FifaSectionHeader('Dettagli Partita'),
          // Anteprima immagine campo selezionato
          if (selectedField != null &&
              selectedField.imagePath != null &&
              File(selectedField.imagePath!).existsSync())
            Container(
              height: 100,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.file(
                File(selectedField.imagePath!),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          _FifaCard(
            child: Column(
              children: [
                // ── Selettore campo ──────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: allFields.isEmpty
                          ? GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const FieldsScreen()),
                              ).then((_) => setState(() {})),
                              child: const Row(
                                children: [
                                  Icon(Icons.stadium_rounded,
                                      color: AppTheme.textMuted, size: 18),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Nessun campo — tocca + per aggiungerne uno',
                                      style: TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : DropdownButtonFormField<String>(
                              value: fieldId,
                              dropdownColor: AppTheme.surfaceAlt,
                              decoration: const InputDecoration(
                                labelText: 'CAMPO',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              hint: const Text('— Nessuno —',
                                  style: TextStyle(
                                      color: AppTheme.textMuted, fontSize: 13)),
                              items: allFields
                                  .map((f) => DropdownMenuItem(
                                        value: f.id,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (f.imagePath != null &&
                                                File(f.imagePath!)
                                                    .existsSync())
                                              Container(
                                                width: 28,
                                                height: 28,
                                                margin: const EdgeInsets.only(
                                                    right: 8),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  image: DecorationImage(
                                                    image: FileImage(
                                                        File(f.imagePath!)),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              )
                                            else
                                              const Padding(
                                                padding:
                                                    EdgeInsets.only(right: 8),
                                                child: Icon(
                                                    Icons.stadium_rounded,
                                                    color: AppTheme.textMuted,
                                                    size: 20),
                                              ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(f.name,
                                                    style: const TextStyle(
                                                        color: AppTheme
                                                            .textPrimary,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                                if (f.address.isNotEmpty)
                                                  Text(f.address,
                                                      style: const TextStyle(
                                                          color: AppTheme
                                                              .textMuted,
                                                          fontSize: 10)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => fieldId = v),
                            ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FieldsScreen()),
                      ).then((_) => setState(() {})),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.accentGreen.withOpacity(0.35)),
                        ),
                        child: const Icon(Icons.add_location_alt_rounded,
                            color: AppTheme.accentGreen, size: 18),
                      ),
                    ),
                  ],
                ),
                const FifaDivider(),
                DropdownButtonFormField<String>(
                  value: numberOfPlayers,
                  dropdownColor: AppTheme.surfaceAlt,
                  decoration: const InputDecoration(
                    labelText: 'FORMATO',
                    border: InputBorder.none, enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none, contentPadding: EdgeInsets.zero,
                  ),
                  items: _formats.map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(f, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                  )).toList(),
                  onChanged: (v) => setState(() => numberOfPlayers = v),
                ),
                const FifaDivider(),
                Row(
                  children: [
                    const Icon(Icons.euro_rounded, color: AppTheme.accentGreen, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _prezzoCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppTheme.textPrimary,
                            fontSize: 13, fontWeight: FontWeight.w700),
                        decoration: const InputDecoration(
                          labelText: 'PREZZO A PERSONA',
                          border: InputBorder.none, enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none, contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── SQUADRA BIANCA ────────────────────────────────────
          FifaSectionHeader('Maglia Bianca (${teamAIds.length})', accent: AppTheme.accentBlue),
          _TeamSelector(
            players: players,
            selected: selectedA,
            accent: AppTheme.accentBlue,
            onToggle: (id, val) => setState(() {
              selectedA[id] = val;
              if (val && (selectedB[id] ?? false)) selectedB[id] = false;
            }),
          ),

          // ── SQUADRA COLORATA ──────────────────────────────────
          FifaSectionHeader('Maglia Colorata (${teamBIds.length})', accent: AppTheme.accentOrange),
          _TeamSelector(
            players: players,
            selected: selectedB,
            accent: AppTheme.accentOrange,
            onToggle: (id, val) => setState(() {
              selectedB[id] = val;
              if (val && (selectedA[id] ?? false)) selectedA[id] = false;
            }),
          ),

          const SizedBox(height: 8),
        ],
      ),

      // ── Bottone genera ────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(
              color: canGenerate ? AppTheme.accentGreen.withOpacity(0.3) : AppTheme.border,
            ),
          ),
        ),
        child: ElevatedButton(
          onPressed: canGenerate
              ? () {
                  final formattedDate = DateFormat('dd/MM/yyyy · HH:mm')
                      .format(selectedDateTime ?? DateTime.now());
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MatchPromoPage(
                        dataOra: formattedDate,
                        fieldModel: selectedField,
                        prezzo: _prezzoCtrl.text.isEmpty ? '—' : _prezzoCtrl.text,
                        nGiocatori: numberOfPlayers ?? '5 vs 5',
                        teamWhite: teamAIds,
                        teamBlack: teamBIds,
                      ),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canGenerate ? AppTheme.accentGreen : AppTheme.border,
            foregroundColor: canGenerate ? Colors.black : AppTheme.textMuted,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rocket_launch_rounded, size: 18),
              SizedBox(width: 10),
              Text('GENERA LOCANDINA'),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Widget locali
// ─────────────────────────────────────────────────────────────

class _FifaCard extends StatelessWidget {
  final Widget child;
  const _FifaCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.border),
    ),
    child: child,
  );
}

class _TeamSelector extends StatelessWidget {
  final List<Player> players;
  final Map<String, bool> selected;
  final Color accent;
  final void Function(String, bool) onToggle;
  const _TeamSelector({
    required this.players, required this.selected,
    required this.accent, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(
      children: players.asMap().entries.map((entry) {
        final i = entry.key;
        final p = entry.value;
        final isSelected = selected[p.id] ?? false;
        return Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onToggle(p.id, !isSelected),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    PlayerAvatar(player: p, radius: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(p.name.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                          fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    FifaBadge(p.role, color: isSelected ? accent : AppTheme.textMuted),
                    const SizedBox(width: 10),
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? accent : Colors.transparent,
                        border: Border.all(
                            color: isSelected ? accent : AppTheme.border, width: 1.5),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, size: 14, color: Colors.black)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            if (i < players.length - 1)
              Container(height: 1, color: AppTheme.border,
                  margin: const EdgeInsets.symmetric(horizontal: 14)),
          ],
        );
      }).toList(),
    ),
  );
}
