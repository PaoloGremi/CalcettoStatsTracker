import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/match_model.dart';
import '../models/player.dart';
import '../services/data_service.dart';
import '../widgets/player_avatar.dart';
import '../theme/app_theme.dart';
import 'vote_screen.dart';

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
  String? fieldLocation;
  DateTime? selectedDateTime;
  String? mvpPlayerId;
  String? hustlePlayerId;
  String? bestGoalPlayerId; // ✅ nuovo
  final TextEditingController _scoreACtrl = TextEditingController();
  final TextEditingController _scoreBCtrl = TextEditingController();

  @override
  void dispose() {
    _scoreACtrl.dispose();
    _scoreBCtrl.dispose();
    super.dispose();
  }

  static const _locations = <Map<String, String>>[
    {'value': 'SanFrancesco', 'label': 'San Francesco · Lodi'},
    {'value': 'Montanaso',    'label': 'Campo Sportivo · Montanaso'},
    {'value': 'Faustina',     'label': 'Faustina Arena · Lodi'},
    {'value': 'Pergola',      'label': 'La Pergola · San Martino'},
    {'value': 'Other',        'label': 'Altro Campo'},
  ];

  /// Restituisce la lista di Player selezionati (teamA + teamB uniti)
  List<Player> _selectedPlayers(List<Player> allPlayers) {
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

    final teamAIds = selectedA.entries.where((e) => e.value).map((e) => e.key).toList();
    final teamBIds = selectedB.entries.where((e) => e.value).map((e) => e.key).toList();
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
        title: const FifaLabel('Nuova Partita', color: AppTheme.textPrimary, fontSize: 13),
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
          _FifaCard(
            child: DropdownButtonFormField<String>(
              value: fieldLocation,
              dropdownColor: AppTheme.surfaceAlt,
              decoration: const InputDecoration(
                labelText: 'SELEZIONA CAMPO',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              items: _locations.map((loc) => DropdownMenuItem(
                value: loc['value'],
                child: Text(loc['label']!,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
              )).toList(),
              onChanged: (v) => setState(() => fieldLocation = v),
            ),
          ),

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
                        ? DateFormat('EEE dd MMM yyyy · HH:mm', 'it_IT')
                            .format(selectedDateTime!)
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
          _FifaCard(
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
                  width: 1, height: 50,
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
          _TeamSelector(
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
          _TeamSelector(
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
          _FifaCard(
            child: participatingPlayers.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Seleziona i giocatori prima di assegnare i premi',
                      style: TextStyle(
                          color: AppTheme.textMuted, fontSize: 12),
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
                        onChanged: (id) => setState(() => bestGoalPlayerId = id),
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
                  ? AppTheme.accentGreen.withOpacity(0.3)
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
                    fieldLocation: fieldLocation ?? 'Other',
                    mvp: mvpPlayerId ?? '',
                    hustlePlayer: hustlePlayerId ?? '',
                    bestGoalPlayer: bestGoalPlayerId ?? '',
                  );
                  await data.addMatch(match);
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => VoteScreen(match: match)),
                  ).then((_) => Navigator.pop(context));
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                canSave ? AppTheme.accentGreen : AppTheme.border,
            foregroundColor:
                canSave ? Colors.black : AppTheme.textMuted,
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
  final List<Player> players;
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
            value: selectedId,
            dropdownColor: AppTheme.surfaceAlt,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: accentColor.withOpacity(0.7),
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
                    PlayerAvatar(player: p, radius: 12),
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

// ─────────────────────────────────────────────────────────────
// Widget locali riutilizzati
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

class _ScoreInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _ScoreInput(
      {required this.label,
      required this.controller,
      required this.onChanged});

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

class _TeamSelector extends StatelessWidget {
  final List<Player> players;
  final Map<String, bool> selected;
  final Color accent;
  final void Function(String, bool) onToggle;
  const _TeamSelector(
      {required this.players,
      required this.selected,
      required this.accent,
      required this.onToggle});

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
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    PlayerAvatar(player: p, radius: 18),
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
                        color: isSelected ? accent : AppTheme.textMuted),
                    const SizedBox(width: 10),
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? accent : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? accent : AppTheme.border,
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
            ),
            if (i < players.length - 1)
              Container(
                height: 1,
                color: AppTheme.border,
                margin: const EdgeInsets.symmetric(horizontal: 14),
              ),
          ],
        );
      }).toList(),
    ),
  );
}
