import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/data_service.dart';
import '../widgets/player_avatar.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// Chiavi SharedPreferences
// ─────────────────────────────────────────────────────────────
class SettingsKeys {
  static const mainPlayerId   = 'main_player_id';
  static const birthDate      = 'info_birth_date';
  static const foot           = 'info_foot';
  static const nationality    = 'info_nationality';
  static const favoriteTeam   = 'info_favorite_team';
  static const jerseyNumber   = 'info_jersey_number';
  // Obiettivi annuali
  static const goalMatches    = 'goal_matches';
  static const goalWins       = 'goal_wins';
  static const goalGoals      = 'goal_goals';
  static const goalMvp        = 'goal_mvp';
}

// ─────────────────────────────────────────────────────────────
// Helper per leggere le impostazioni da SharedPreferences
// ─────────────────────────────────────────────────────────────
class AppSettings {
  final String? mainPlayerId;
  final String birthDate, foot, nationality, favoriteTeam, jerseyNumber;
  // Obiettivi annuali
  final int goalMatches, goalWins, goalGoals, goalMvp;

  const AppSettings({
    this.mainPlayerId,
    this.birthDate = '',
    this.foot = 'Destro',
    this.nationality = '',
    this.favoriteTeam = '',
    this.jerseyNumber = '',
    this.goalMatches = 0,
    this.goalWins = 0,
    this.goalGoals = 0,
    this.goalMvp = 0,
  });

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      mainPlayerId:  prefs.getString(SettingsKeys.mainPlayerId),
      birthDate:     prefs.getString(SettingsKeys.birthDate) ?? '',
      foot:          prefs.getString(SettingsKeys.foot) ?? 'Destro',
      nationality:   prefs.getString(SettingsKeys.nationality) ?? '',
      favoriteTeam:  prefs.getString(SettingsKeys.favoriteTeam) ?? '',
      jerseyNumber:  prefs.getString(SettingsKeys.jerseyNumber) ?? '',
      goalMatches:   prefs.getInt(SettingsKeys.goalMatches) ?? 0,
      goalWins:      prefs.getInt(SettingsKeys.goalWins) ?? 0,
      goalGoals:     prefs.getInt(SettingsKeys.goalGoals) ?? 0,
      goalMvp:       prefs.getInt(SettingsKeys.goalMvp) ?? 0,
    );
  }

  static Future<void> save({
    String? mainPlayerId,
    String? birthDate, String? foot, String? nationality,
    String? favoriteTeam, String? jerseyNumber,
    int? goalMatches, int? goalWins, int? goalGoals, int? goalMvp,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (mainPlayerId != null) await prefs.setString(SettingsKeys.mainPlayerId, mainPlayerId);
    if (birthDate != null) await prefs.setString(SettingsKeys.birthDate, birthDate);
    if (foot != null) await prefs.setString(SettingsKeys.foot, foot);
    if (nationality != null) await prefs.setString(SettingsKeys.nationality, nationality);
    if (favoriteTeam != null) await prefs.setString(SettingsKeys.favoriteTeam, favoriteTeam);
    if (jerseyNumber != null) await prefs.setString(SettingsKeys.jerseyNumber, jerseyNumber);
    if (goalMatches != null) await prefs.setInt(SettingsKeys.goalMatches, goalMatches);
    if (goalWins != null) await prefs.setInt(SettingsKeys.goalWins, goalWins);
    if (goalGoals != null) await prefs.setInt(SettingsKeys.goalGoals, goalGoals);
    if (goalMvp != null) await prefs.setInt(SettingsKeys.goalMvp, goalMvp);
  }
}

// ─────────────────────────────────────────────────────────────
// Schermata Impostazioni
// ─────────────────────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;

  // Giocatore principale
  String? _mainPlayerId;

  // Info personali
  final _birthCtrl      = TextEditingController();
  final _nationalityCtrl = TextEditingController();
  final _teamCtrl       = TextEditingController();
  final _jerseyCtrl     = TextEditingController();
  String _foot = 'Destro';

  // Obiettivi annuali
  final _goalMatchesCtrl  = TextEditingController();
  final _goalWinsCtrl     = TextEditingController();
  final _goalGoalsCtrl    = TextEditingController();
  final _goalMvpCtrl      = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await AppSettings.load();
    setState(() {
      _mainPlayerId    = s.mainPlayerId;
      _birthCtrl.text       = s.birthDate;
      _foot                 = s.foot;
      _nationalityCtrl.text = s.nationality;
      _teamCtrl.text        = s.favoriteTeam;
      _jerseyCtrl.text      = s.jerseyNumber;
      _goalMatchesCtrl.text  = s.goalMatches > 0 ? '${s.goalMatches}' : '';
      _goalWinsCtrl.text     = s.goalWins    > 0 ? '${s.goalWins}'    : '';
      _goalGoalsCtrl.text    = s.goalGoals   > 0 ? '${s.goalGoals}'   : '';
      _goalMvpCtrl.text      = s.goalMvp     > 0 ? '${s.goalMvp}'     : '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    await AppSettings.save(
      mainPlayerId:  _mainPlayerId ?? '',
      birthDate:    _birthCtrl.text.trim(),
      foot:         _foot,
      nationality:  _nationalityCtrl.text.trim(),
      favoriteTeam: _teamCtrl.text.trim(),
      jerseyNumber: _jerseyCtrl.text.trim(),
      goalMatches:  int.tryParse(_goalMatchesCtrl.text.trim()) ?? 0,
      goalWins:     int.tryParse(_goalWinsCtrl.text.trim()) ?? 0,
      goalGoals:    int.tryParse(_goalGoalsCtrl.text.trim()) ?? 0,
      goalMvp:      int.tryParse(_goalMvpCtrl.text.trim()) ?? 0,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.black, size: 18),
          SizedBox(width: 8),
          Text('Impostazioni salvate',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
    Navigator.pop(context, true); // true = aggiorna la home
  }

  Future<void> _pickAvatarForMainPlayer() async {
    if (_mainPlayerId == null) return;
    final data = Provider.of<DataService>(context, listen: false);
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 512, maxHeight: 512);
    if (picked == null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'player_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
    final dest = p.join(appDir.path, fileName);
    await File(picked.path).copy(dest);
    final player = data.getAllPlayers().firstWhere((p) => p.id == _mainPlayerId);
    player.imagePath = dest;
    await data.updatePlayer(player);
    setState(() {});
  }

  @override
  void dispose() {
    _birthCtrl.dispose();
    _nationalityCtrl.dispose();
    _teamCtrl.dispose();
    _jerseyCtrl.dispose();
    _goalMatchesCtrl.dispose();
    _goalWinsCtrl.dispose();
    _goalGoalsCtrl.dispose();
    _goalMvpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataService>(context);
    final players = data.getAllPlayers()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final mainPlayer = _mainPlayerId != null
        ? players.where((p) => p.id == _mainPlayerId).firstOrNull
        : null;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const FifaLabel('Impostazioni', color: AppTheme.textPrimary, fontSize: 13),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGreen))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [

                // ── GIOCATORE PRINCIPALE ──────────────────────────
                const FifaSectionHeader('Giocatore Principale',
                    accent: AppTheme.accentGold),
                _FifaCard(
                  child: Column(
                    children: [
                      // Selezione giocatore
                      DropdownButtonFormField<String>(
                        value: _mainPlayerId,
                        dropdownColor: AppTheme.surfaceAlt,
                        decoration: const InputDecoration(
                          labelText: 'SELEZIONA GIOCATORE',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        items: players.map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Row(children: [
                            PlayerAvatar(player: p, radius: 14),
                            const SizedBox(width: 10),
                            Text(p.name,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary, fontSize: 13)),
                          ]),
                        )).toList(),
                        onChanged: (v) => setState(() => _mainPlayerId = v),
                      ),

                      // Anteprima + cambio foto
                      if (mainPlayer != null) ...[
                        const FifaDivider(),
                        Row(
                          children: [
                            // Avatar grande
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppTheme.accentGold.withOpacity(0.4),
                                    width: 2),
                              ),
                              child: PlayerAvatar(player: mainPlayer, radius: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(mainPlayer.name.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  FifaBadge(mainPlayer.role, color: AppTheme.accentBlue),
                                ],
                              ),
                            ),
                            // Pulsante cambia foto
                            GestureDetector(
                              onTap: _pickAvatarForMainPlayer,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentGold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppTheme.accentGold.withOpacity(0.35)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.photo_camera_rounded,
                                        color: AppTheme.accentGold, size: 16),
                                    SizedBox(width: 6),
                                    Text('FOTO',
                                        style: TextStyle(
                                            color: AppTheme.accentGold,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // ── OBIETTIVI ANNUALI ─────────────────────────────
                const FifaSectionHeader('Obiettivi Annuali',
                    accent: AppTheme.accentGreen),
                _FifaCard(
                  child: Column(
                    children: [
                      _InfoField(
                        label: 'PARTITE GIOCATE',
                        controller: _goalMatchesCtrl,
                        hint: 'es. 50',
                        icon: Icons.sports_soccer_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      const FifaDivider(),
                      _InfoField(
                        label: 'VITTORIE',
                        controller: _goalWinsCtrl,
                        hint: 'es. 30',
                        icon: Icons.emoji_events_rounded,
                        iconColor: AppTheme.accentGold,
                        keyboardType: TextInputType.number,
                      ),
                      const FifaDivider(),
                      _InfoField(
                        label: 'GOL',
                        controller: _goalGoalsCtrl,
                        hint: 'es. 20',
                        icon: Icons.sports_score_rounded,
                        iconColor: AppTheme.accentGreen,
                        keyboardType: TextInputType.number,
                      ),
                      const FifaDivider(),
                      _InfoField(
                        label: 'PREMI MVP',
                        controller: _goalMvpCtrl,
                        hint: 'es. 5',
                        icon: Icons.workspace_premium_rounded,
                        iconColor: AppTheme.accentOrange,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),

                // ── INFO PERSONALI ────────────────────────────────
                const FifaSectionHeader('Info Personali',
                    accent: AppTheme.accentBlue),
                _FifaCard(
                  child: Column(
                    children: [
                      _InfoField(label: 'DATA DI NASCITA',
                          controller: _birthCtrl,
                          hint: 'es. 10 Agosto 1991',
                          icon: Icons.cake_rounded),
                      const FifaDivider(),
                      // Piede dominante
                      Row(
                        children: [
                          const Icon(Icons.sports_soccer_rounded,
                              color: AppTheme.textMuted, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _foot,
                              dropdownColor: AppTheme.surfaceAlt,
                              decoration: const InputDecoration(
                                labelText: 'PIEDE',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              items: ['Destro', 'Sinistro', 'Entrambi']
                                  .map((f) => DropdownMenuItem(
                                    value: f,
                                    child: Text(f,
                                        style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 13)),
                                  ))
                                  .toList(),
                              onChanged: (v) => setState(() => _foot = v ?? _foot),
                            ),
                          ),
                        ],
                      ),
                      const FifaDivider(),
                      _InfoField(label: 'NAZIONALITÀ',
                          controller: _nationalityCtrl,
                          hint: 'es. Italiana',
                          icon: Icons.flag_rounded),
                      const FifaDivider(),
                      _InfoField(label: 'SQUADRA DEL CUORE',
                          controller: _teamCtrl,
                          hint: 'es. Juventus',
                          icon: Icons.favorite_rounded,
                          iconColor: AppTheme.accentRed),
                      const FifaDivider(),
                      _InfoField(label: 'NUMERO DI MAGLIA',
                          controller: _jerseyCtrl,
                          hint: 'es. 10',
                          icon: Icons.tag_rounded,
                          keyboardType: TextInputType.number),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),

      // ── Bottone salva ─────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: ElevatedButton(
          onPressed: _save,
          child: const Text('SALVA IMPOSTAZIONI'),
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

class _InfoField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final IconData icon;
  final Color iconColor;
  final TextInputType keyboardType;
  const _InfoField({
    required this.label, required this.controller, required this.hint,
    required this.icon, this.iconColor = AppTheme.textMuted,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: iconColor, size: 18),
      const SizedBox(width: 12),
      Expanded(
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
              color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    ],
  );
}
