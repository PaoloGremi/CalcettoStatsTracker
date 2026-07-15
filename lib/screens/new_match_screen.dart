import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/util/date_formatters.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../services/data_service.dart';
import '../widgets/fifa_card.dart';
import '../widgets/player_avatar.dart';
import '../widgets/team_selector.dart';
import '../theme/app_theme.dart';
import 'vote_screen.dart';
import 'fields_screen.dart';

class NewMatchScreen extends StatefulWidget {
  const NewMatchScreen({super.key});

  @override
  State<NewMatchScreen> createState() => _NewMatchScreenState();
}

class _NewMatchScreenState extends State<NewMatchScreen> {
  final Map<String, bool> selectedA = {};
  final Map<String, bool> selectedB = {};
  int scoreA = 0;
  int scoreB = 0;
  String? fieldId; // ID del FieldModel selezionato
  DateTime? selectedDateTime;
  String? mvpPlayerId;
  String? hustlePlayerId;
  String? bestGoalPlayerId;
  final TextEditingController _scoreACtrl = TextEditingController();
  final TextEditingController _scoreBCtrl = TextEditingController();

  @override
  void dispose() {
    _scoreACtrl.dispose();
    _scoreBCtrl.dispose();
    super.dispose();
  }

  /// Restituisce la lista di PlayerModel selezionati (teamA + teamB uniti)
  List<PlayerModel> _selectedPlayers(List<PlayerModel> allPlayers) {
    final selectedIds = {
      ...selectedA.entries.where((e) => e.value).map((e) => e.key),
      ...selectedB.entries.where((e) => e.value).map((e) => e.key),
    };
    return allPlayers.where((p) => selectedIds.contains(p.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataService>(context);
    final allPlayers = data.getAllPlayers()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final allFields = data.getAllFields();

    // Se il campo selezionato è stato eliminato, resetta
    if (fieldId != null && !allFields.any((f) => f.id == fieldId)) {
      fieldId = null;
    }

    final selectedField = fieldId != null
        ? allFields.where((f) => f.id == fieldId).firstOrNull
        : null;

    final teamAIds =
        selectedA.entries.where((e) => e.value).map((e) => e.key).toList();
    final teamBIds =
        selectedB.entries.where((e) => e.value).map((e) => e.key).toList();
    final canSave = teamAIds.isNotEmpty && teamBIds.isNotEmpty;
    final participatingPlayers = _selectedPlayers(allPlayers);

    // Se MVP/Hustle selezionati non sono più nella partita, resetta
    if (mvpPlayerId != null &&
        !participatingPlayers.any((p) => p.id == mvpPlayerId)) {
      mvpPlayerId = null;
    }
    if (hustlePlayerId != null &&
        !participatingPlayers.any((p) => p.id == hustlePlayerId)) {
      hustlePlayerId = null;
    }
    if (bestGoalPlayerId != null &&
        !participatingPlayers.any((p) => p.id == bestGoalPlayerId)) {
      bestGoalPlayerId = null;
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const FifaLabel('Nuova Partita',
            color: AppTheme.textPrimary, fontSize: 13),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // ── CAMPO ─────────────────────────────────────────────
          const FifaSectionHeader('Campo'),
          // Anteprima immagine campo selezionato
          if (selectedField != null &&
              selectedField.imagePath != null &&
              File(selectedField.imagePath!).existsSync())
            Container(
              height: 110,
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
          FifaCard(
            child: Row(
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
                                      color: AppTheme.textMuted, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          initialValue: fieldId,
                          dropdownColor: AppTheme.surfaceAlt,
                          decoration: const InputDecoration(
                            labelText: 'SELEZIONA CAMPO',
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
                                            File(f.imagePath!).existsSync())
                                          Container(
                                            width: 28,
                                            height: 28,
                                            margin:
                                                const EdgeInsets.only(right: 8),
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
                                            padding: EdgeInsets.only(right: 8),
                                            child: Icon(Icons.stadium_rounded,
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
                                                    color: AppTheme.textPrimary,
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            if (f.address.isNotEmpty)
                                              Text(f.address,
                                                  style: const TextStyle(
                                                      color: AppTheme.textMuted,
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
                // Bottone gestione campi
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FieldsScreen()),
                  ).then((_) => setState(() {})),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.accentGreen.withValues(alpha: 0.35)),
                    ),
                    child: const Icon(
                      Icons.add_location_alt_rounded,
                      color: AppTheme.accentGreen,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── DATA E ORA ────────────────────────────────────────
          const FifaSectionHeader('Data e Ora'),
          FifaCard(
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
                setState(() {
                  selectedDateTime = DateTime(
                      date.year, date.month, date.day, time.hour, time.minute);
                });
              },
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: AppTheme.accentGreen, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    selectedDateTime != null
                        ? formatFullDateTime(selectedDateTime!)
                        : 'Seleziona data e ora',
                    style: TextStyle(
                      color: selectedDateTime != null
                          ? AppTheme.textPrimary
                          : AppTheme.textMuted,
                      fontSize: 13,
                      fontWeight: selectedDateTime != null
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      color: AppTheme.textMuted, size: 18),
                ],
              ),
            ),
          ),

          // ── PUNTEGGIO ─────────────────────────────────────────
          const FifaSectionHeader('Punteggio Finale'),
          FifaCard(
            child: Row(
              children: [
                Expanded(
                  child: _ScoreInput(
                    label: 'BIANCHI',
                    controller: _scoreACtrl,
                    onChanged: (v) => scoreA = int.tryParse(v) ?? 0,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: AppTheme.border,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: _ScoreInput(
                    label: 'COLORATI',
                    controller: _scoreBCtrl,
                    onChanged: (v) => scoreB = int.tryParse(v) ?? 0,
                  ),
                ),
              ],
            ),
          ),

          // ── SQUADRA BIANCA ────────────────────────────────────
          FifaSectionHeader('Squadra Bianca (${teamAIds.length})',
              accent: AppTheme.accentBlue),
          TeamSelector(
            players: allPlayers,
            selected: selectedA,
            accent: AppTheme.accentBlue,
            onToggle: (id, val) => setState(() {
              selectedA[id] = val;
              if (val && (selectedB[id] ?? false)) selectedB[id] = false;
            }),
          ),

          // ── SQUADRA COLORATA ──────────────────────────────────
          FifaSectionHeader('Squadra Colorata (${teamBIds.length})',
              accent: AppTheme.accentOrange),
          TeamSelector(
            players: allPlayers,
            selected: selectedB,
            accent: AppTheme.accentOrange,
            onToggle: (id, val) => setState(() {
              selectedB[id] = val;
              if (val && (selectedA[id] ?? false)) selectedA[id] = false;
            }),
          ),

          // ── PREMI ─────────────────────────────────────────────
          const FifaSectionHeader('Premi Partita'),
          FifaCard(
            child: participatingPlayers.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Seleziona i giocatori prima di assegnare i premi',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  )
                : Column(
                    children: [
                      // MVP
                      _AwardDropdown(
                        emoji: '👑',
                        label: 'MVP DELLA PARTITA',
                        accentColor: AppTheme.accentGold,
                        players: participatingPlayers,
                        selectedId: mvpPlayerId,
                        onChanged: (id) => setState(() => mvpPlayerId = id),
                      ),
                      const FifaDivider(),
                      // Combattivo
                      _AwardDropdown(
                        emoji: '🔥',
                        label: 'GIOCATORE PIÙ COMBATTIVO',
                        accentColor: AppTheme.accentOrange,
                        players: participatingPlayers,
                        selectedId: hustlePlayerId,
                        onChanged: (id) => setState(() => hustlePlayerId = id),
                      ),
                      const FifaDivider(),
                      // Best Goal
                      _AwardDropdown(
                        emoji: '⚽',
                        label: 'BEST GOAL',
                        accentColor: AppTheme.accentGreen,
                        players: participatingPlayers,
                        selectedId: bestGoalPlayerId,
                        onChanged: (id) =>
                            setState(() => bestGoalPlayerId = id),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 16),
        ],
      ),

      // ── Bottone salva ─────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(
              color: canSave
                  ? AppTheme.accentGreen.withValues(alpha: 0.3)
                  : AppTheme.border,
            ),
          ),
        ),
        child: ElevatedButton(
          onPressed: canSave
              ? () async {
                  final match = MatchModel(
                    id: const Uuid().v4(),
                    date: selectedDateTime ?? DateTime.now(),
                    teamA: teamAIds,
                    teamB: teamBIds,
                    scoreA: scoreA,
                    scoreB: scoreB,
                    fieldLocation: fieldId ?? '',
                    mvp: mvpPlayerId ?? '',
                    hustlePlayer: hustlePlayerId ?? '',
                    bestGoalPlayer: bestGoalPlayerId ?? '',
                  );
                  await data.addMatch(match);
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => VoteScreen(match: match)),
                  ).then((_) => Navigator.pop(context));
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canSave ? AppTheme.accentGreen : AppTheme.border,
            foregroundColor: canSave ? Colors.black : AppTheme.textMuted,
          ),
          child: Text(canSave
              ? 'SALVA E VOTA GIOCATORI'
              : 'SELEZIONA ALMENO 1 GIOCATORE PER SQUADRA'),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Dropdown per assegnare MVP / Combattivo
// ─────────────────────────────────────────────────────────────

class _AwardDropdown extends StatelessWidget {
  final String emoji;
  final String label;
  final Color accentColor;
  final List<PlayerModel> players;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _AwardDropdown({
    required this.emoji,
    required this.label,
    required this.accentColor,
    required this.players,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: selectedId,
            dropdownColor: AppTheme.surfaceAlt,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: accentColor.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            hint: const Text('— Nessuno —',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            items: [
              // Opzione "nessuno"
              const DropdownMenuItem<String>(
                value: null,
                child: Text('— Nessuno —',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              ),
              // Un item per ogni giocatore partecipante
              ...players.map((p) => DropdownMenuItem<String>(
                    value: p.id,
                    child: Row(
                      children: [
                        PlayerAvatar(
                            name: p.name,
                            icon: p.icon,
                            imagePath: p.imagePath,
                            radius: 12),
                        const SizedBox(width: 8),
                        Text(
                          p.name,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  )),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _ScoreInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _ScoreInput(
      {required this.label, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          FifaLabel(label, color: AppTheme.textSecondary),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900),
            onChanged: onChanged,
            decoration: const InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 28,
                  fontWeight: FontWeight.w900),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      );
}
