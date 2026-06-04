import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:calcetto_tracker/screens/ai_coach_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import 'players_screen.dart';
import 'match_promo_form_page.dart';
import 'new_match_screen.dart';
import 'history_match.dart';
import 'stats_screen.dart';
import 'backup_screen.dart';
import '../data/player_icons.dart';
import 'settings_screen.dart';
import 'fields_screen.dart';
import '../services/player_stats_calculator.dart';
import 'package:calcetto_tracker/data/hive_boxes.dart';
 
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
 
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
 
class _HomeScreenState extends State<HomeScreen> {
  AppSettings _settings = const AppSettings();
 
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
 
  Future<void> _loadSettings() async {
    final s = await AppSettings.load();
    setState(() => _settings = s);
  }
 
  /// Costruisce il widget avatar da mostrare nello scudo FIFA.
  /// Priorità: 1) foto galleria, 2) asset icona giocatore, 3) icona generica
  Widget _buildShieldAvatar(dynamic player, double shieldSize) {
    if (player == null) {
      return const Icon(Icons.person_rounded, color: Colors.black45, size: 60);
    }
 
    // 1. Foto dalla galleria
    final hasCustomAvatar = player.imagePath != null &&
        File(player.imagePath!).existsSync();
    if (hasCustomAvatar) {
      return ClipOval(
        child: Image.file(File(player.imagePath!), fit: BoxFit.cover),
      );
    }
 
    // 2. Asset icona personalizzata
    final playerIcon = getPlayerIcon(player.icon);
    if (playerIcon.isAsset) {
      return Image.asset(playerIcon.assetPath!, fit: BoxFit.contain);
    }
 
    // 3. Icona Material generica
    return Icon(playerIcon.iconData ?? Icons.person_rounded,
        color: Colors.black54, size: shieldSize * 0.4);
  }
 
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
 
    final data = Provider.of<DataService>(context, listen: false);
    final players = data.getAllPlayers();
    final mainPlayer = _settings.mainPlayerId != null
        ? players.where((p) => p.id == _settings.mainPlayerId).firstOrNull
        : null;
 
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: const FifaLabel('Champions Calcetto Stats',
            color: AppTheme.textPrimary, fontSize: 12),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_rounded,
                color: AppTheme.textSecondary, size: 22),
            tooltip: 'Promo',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MatchPromoFormPage())),
          ),
 
          IconButton(
            icon: const Icon(Icons.psychology_outlined,
                color: AppTheme.textSecondary, size: 22),
            tooltip: 'AI Coach',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AiCoachPage())),
          ),
 
 
 
          IconButton(
            icon: const Icon(Icons.backup_rounded,
                color: AppTheme.textSecondary, size: 22),
            tooltip: 'Backup CSV',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BackupScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded,
                color: AppTheme.textSecondary, size: 22),
            tooltip: 'Impostazioni',
            onPressed: () async {
              final updated = await Navigator.push<bool>(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
              if (updated == true) _loadSettings();
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: Column(
        children: [
 
          // ── FIFA UT Card ──────────────────────────────────────
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                // Sfondo stadio
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/backgroundStadium.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.35),
                          Colors.black.withOpacity(0.75),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: _FutCard(
                    player: mainPlayer,
                    settings: _settings,
                    buildAvatar: _buildShieldAvatar,
                  ),
                ),
              ],
            ),
          ),
 
          // ── News Ticker ────────────────────────────────────────
          const SmartNewsTicker(),
 
          // ── Info giocatore principale ─────────────────────────
          Expanded(
            flex: 4,
            child: mainPlayer == null
                // Placeholder: nessun giocatore configurato
                ? GestureDetector(
                    onTap: () async {
                      final updated = await Navigator.push<bool>(context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()));
                      if (updated == true) _loadSettings();
                    },
                    child: Container(
                      color: AppTheme.surface,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_rounded,
                              color: AppTheme.accentGold.withOpacity(0.5), size: 40),
                          const SizedBox(height: 12),
                          const Text('Configura il tuo profilo',
                            style: TextStyle(
                              color: AppTheme.accentGold,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text('Tocca per aprire le impostazioni',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                  )
                // Scheda giocatore principale
                : _MainPlayerCard(
                    player: mainPlayer,
                    settings: _settings,
                    data: data,
                    onSettingsTap: () async {
                      final updated = await Navigator.push<bool>(context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()));
                      if (updated == true) _loadSettings();
                    },
                  ),
          ),
        ],
      ),
 
      // ── Bottom Nav Bar ────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: const Border(top: BorderSide(color: AppTheme.border)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 4,
          top: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavBtn(
              icon: Icons.history_rounded,
              label: 'STORICO',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HistoryMatch()))
                  .then((_) => setState(() {})),
            ),
            _NavBtn(
              icon: Icons.bar_chart_rounded,
              label: 'STATS',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const StatsScreen())),
            ),
            // Bottone centrale add
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NewMatchScreen()))
                  .then((_) => setState(() {})),
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                      color: AppTheme.accentGreen.withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 2)],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.black, size: 30),
              ),
            ),
            _NavBtn(
              icon: Icons.people_rounded,
              label: 'ROSA',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PlayersScreen()))
                  .then((_) => setState(() {})),
            ),
            _NavBtn(
              icon: Icons.stadium_rounded,
              label: 'CAMPI',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const FieldsScreen()))
                  .then((_) => setState(() {})),
            ),
          ],
        ),
      ),
    );
  }
}
 
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.label, required this.onTap});
 
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 22),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5)),
        ],
      ),
    ),
  );
}
 
class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
 
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1)),
        Text(value,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800)),
      ],
    ),
  );
}
 
class FifaStats extends StatelessWidget {
  final int vel, tir, pas, dri, dif, fis;
  const FifaStats({
    super.key,
    required this.vel, required this.tir, required this.pas,
    required this.dri, required this.dif, required this.fis,
  });
 
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stat('$vel', 'VEL'),
        _stat('$tir', 'TIR'),
        _stat('$pas', 'PAS'),
      ]),
      const SizedBox(width: 24),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _stat('$dri', 'DRI'),
        _stat('$dif', 'DIF'),
        _stat('$fis', 'FIS'),
      ]),
    ],
  );
 
  Widget _stat(String val, String lbl) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text(val,
          style: const TextStyle(
              fontSize: 22, color: Colors.black, fontWeight: FontWeight.w900)),
      const SizedBox(width: 6),
      Text(lbl,
          style: const TextStyle(
              fontSize: 16, color: Colors.black, letterSpacing: 1)),
    ]),
  );
}
 
// ─────────────────────────────────────────────────────────────
// Scheda giocatore principale nella home
// ─────────────────────────────────────────────────────────────
class _MainPlayerCard extends StatelessWidget {
  final dynamic player;   // Player
  final AppSettings settings;
  final DataService data;
  final VoidCallback onSettingsTap;
 
  const _MainPlayerCard({
    required this.player,
    required this.settings,
    required this.data,
    required this.onSettingsTap,
  });
 
  @override
  Widget build(BuildContext context) {
    final matches = data.getAllMatches();
 
    // Calcola stats reali
    int gamesPlayed = 0, wins = 0, draws = 0, losses = 0, votesCount = 0;
    double totalVotes = 0;
    for (final m in matches) {
      final inA = m.teamA.contains(player.id);
      final inB = m.teamB.contains(player.id);
      if (!inA && !inB) continue;
      gamesPlayed++;
      if (m.scoreA == m.scoreB) {
        draws++;
      } else if ((inA && m.scoreA > m.scoreB) || (inB && m.scoreB > m.scoreA)) {
        wins++;
      } else {
        losses++;
      }
      if (m.votes.containsKey(player.id)) {
        totalVotes += m.votes[player.id]!;
        votesCount++;
      }
    }
    final avgVote = votesCount > 0 ? totalVotes / votesCount : 0.0;
    final winPct = gamesPlayed > 0 ? (wins / gamesPlayed * 100).round() : 0;
 
    // Helper: conta i gol del giocatore
    int _countGoals(DataService d, String playerId) {
      int total = 0;
      for (final m in d.getAllMatches()) {
        total += (m.goals[playerId] ?? 0) as int;
      }
      return total;
    }
 
    Color voteColor(double v) {
      if (v >= 8.0) return AppTheme.accentGreen;
      if (v >= 6.5) return AppTheme.accentGold;
      if (v >= 5.0) return AppTheme.accentOrange;
      return AppTheme.accentRed;
    }
 
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/backgroundcity.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.black.withOpacity(0.88),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
 
              // ── Header: nome + impostazioni ───────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(children: [
                          FifaBadge(player.role, color: AppTheme.accentBlue),
                          if (settings.jerseyNumber.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            FifaBadge('#${settings.jerseyNumber}',
                                color: AppTheme.accentGold),
                          ],
                          if (settings.foot.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            FifaBadge(settings.foot == 'Destro' ? '🦶D'
                                : settings.foot == 'Sinistro' ? '🦶S' : '🦶B',
                                color: AppTheme.textMuted),
                          ],
                        ]),
                      ],
                    ),
                  ),
 
                ],
              ),
 
              const SizedBox(height: 10),
              Container(height: 1, color: Colors.white10),
              const SizedBox(height: 10),
 
              // ── Stats partite ─────────────────────────────────
              Row(
                children: [
                  _StatBox(value: '$gamesPlayed', label: 'PARTITE',
                      color: AppTheme.accentBlue),
                  const SizedBox(width: 8),
                  _StatBox(value: '$wins', label: 'VINTE',
                      color: AppTheme.accentGreen),
                  const SizedBox(width: 8),
                  _StatBox(value: '$draws', label: 'PAREGGI',
                      color: AppTheme.accentGold),
                  const SizedBox(width: 8),
                  _StatBox(value: '$losses', label: 'PERSE',
                      color: AppTheme.accentRed),
                  const SizedBox(width: 8),
                  _StatBox(
                    value: votesCount > 0 ? avgVote.toStringAsFixed(1) : '—',
                    label: 'VOTO',
                    color: votesCount > 0 ? voteColor(avgVote) : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 8),
                  _StatBox(value: '$winPct%', label: 'WIN%',
                      color: AppTheme.accentOrange),
                ],
              ),
 
              // ── Badge premi ───────────────────────────────────
              if (player.mvpCount > 0 || player.hustleCount > 0 ||
                  player.bestGoalCount > 0) ...[
                const SizedBox(height: 10),
                Row(children: [
                  if (player.mvpCount > 0) ...[
                    _AwardPill('👑', 'MVP', player.mvpCount, AppTheme.accentGold),
                    const SizedBox(width: 6),
                  ],
                  if (player.hustleCount > 0) ...[
                    _AwardPill('🔥', 'COMBATTIVO', player.hustleCount,
                        AppTheme.accentOrange),
                    const SizedBox(width: 6),
                  ],
                  if (player.bestGoalCount > 0)
                    _AwardPill('⚽', 'BEST GOAL', player.bestGoalCount,
                        AppTheme.accentGreen),
                ]),
              ],
 
              const SizedBox(height: 10),
              Container(height: 1, color: Colors.white10),
              const SizedBox(height: 10),
 
              // ── Obiettivi annuali ──────────────────────────────
              if (settings.goalMatches > 0 || settings.goalWins > 0 ||
                  settings.goalGoals > 0 || settings.goalMvp > 0) ...[
                const Text(
                  'OBIETTIVI ANNUALI',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                if (settings.goalMatches > 0)
                  _GoalProgressRow(
                    icon: Icons.sports_soccer_rounded,
                    label: 'PARTITE',
                    current: gamesPlayed,
                    target: settings.goalMatches,
                    color: AppTheme.accentBlue,
                  ),
                if (settings.goalWins > 0)
                  _GoalProgressRow(
                    icon: Icons.emoji_events_rounded,
                    label: 'VITTORIE',
                    current: wins,
                    target: settings.goalWins,
                    color: AppTheme.accentGold,
                  ),
                if (settings.goalGoals > 0)
                  _GoalProgressRow(
                    icon: Icons.sports_score_rounded,
                    label: 'GOL',
                    current: _countGoals(data, player.id as String),
                    target: settings.goalGoals,
                    color: AppTheme.accentGreen,
                  ),
                if (settings.goalMvp > 0)
                  _GoalProgressRow(
                    icon: Icons.workspace_premium_rounded,
                    label: 'MVP',
                    current: player.mvpCount as int,
                    target: settings.goalMvp,
                    color: AppTheme.accentOrange,
                  ),
                const SizedBox(height: 10),
                Container(height: 1, color: Colors.white10),
                const SizedBox(height: 10),
              ],
 
              // ── Info anagrafiche ──────────────────────────────
              if (settings.birthDate.isNotEmpty || settings.nationality.isNotEmpty ||
                  settings.favoriteTeam.isNotEmpty || settings.foot.isNotEmpty) ...[
                if (settings.birthDate.isNotEmpty)
                  _InfoRow('DATA DI NASCITA', settings.birthDate),
                if (settings.nationality.isNotEmpty)
                  _InfoRow('NAZIONALITÀ', settings.nationality),
                if (settings.favoriteTeam.isNotEmpty)
                  _InfoRow('SQUADRA DEL CUORE', settings.favoriteTeam),
                if (settings.foot.isNotEmpty)
                  _InfoRow('PIEDE', settings.foot),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
 
class _StatBox extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatBox({required this.value, required this.label, required this.color});
 
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    ),
  );
}
 
class _AwardPill extends StatelessWidget {
  final String emoji, label;
  final int count;
  final Color color;
  const _AwardPill(this.emoji, this.label, this.count, this.color);
 
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 5),
        Text('$label ×$count',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}
 
// ─────────────────────────────────────────────────────────────
// Barra progresso obiettivo annuale
// ─────────────────────────────────────────────────────────────
class _GoalProgressRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int current, target;
  final Color color;
 
  const _GoalProgressRow({
    required this.icon,
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });
 
  @override
  Widget build(BuildContext context) {
    final pct = (current / target).clamp(0.0, 1.0);
    final done = current >= target;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 6),
              Text(label,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                done ? '✓ $target/$target' : '$current/$target',
                style: TextStyle(
                  color: done ? AppTheme.accentGreen : AppTheme.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                done ? AppTheme.accentGreen : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _FutCard extends StatelessWidget {
  final dynamic player; // Player?
  final AppSettings settings;
  final Widget Function(dynamic, double) buildAvatar;
 
  const _FutCard({
    required this.player,
    required this.settings,
    required this.buildAvatar,
  });
 
  // ── Stat calcolate dai dati reali ─────────────────────────────────────
  ComputedFifaStats get _computed {
    if (player == null) return ComputedFifaStats.empty();
    return PlayerStatsCalculator.compute(player.id as String);
  }
 
  /// Overall: media delle 6 stat calcolate
  int get _overall => _computed.overall;
 
  /// Colore card in base all'overall (invariato)
  Color get _cardColor {
    if (_overall >= 85) return const Color(0xFFFFD700); // oro
    if (_overall >= 75) return const Color(0xFFC0C0C0); // argento
    return const Color(0xFFCD7F32); // bronzo
  }
 
  @override
  Widget build(BuildContext context) {
    final c = _cardColor;
    final cardW = 200.0;
    final cardH = 280.0;
    final stats = _computed; // calcolate una sola volta
 
    return Container(
      width: cardW,
      height: cardH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.withOpacity(0.25),
            Colors.black.withOpacity(0.85),
            c.withOpacity(0.15),
          ],
        ),
        border: Border.all(color: c.withOpacity(0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: c.withOpacity(0.45),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Trama interna
            Positioned.fill(
              child: CustomPaint(painter: _CardPatternPainter(c)),
            ),
 
            // Contenuto
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                children: [
                  // ── Riga superiore: rating + foto + ruolo ──────
                  SizedBox(
                    height: cardH * 0.52,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Colonna sinistra: overall + ruolo
                        Column(
                          children: [
                            Text(
                              '$_overall',
                              style: TextStyle(
                                color: c,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              player?.role ?? '—',
                              style: TextStyle(
                                color: c,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Numero maglia
                            if (settings.jerseyNumber.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: c.withOpacity(0.5), width: 1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#${settings.jerseyNumber}',
                                  style: TextStyle(
                                    color: c.withOpacity(0.85),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                          ],
                        ),
 
                        // Foto centrata che fuoriesce
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 0),
                            child: player == null
                                ? Center(
                                    child: Icon(Icons.person_rounded,
                                        color: c.withOpacity(0.3), size: 80),
                                  )
                                : OverflowBox(
                                    maxHeight: cardH * 0.56,
                                    alignment: Alignment.topCenter,
                                    child: _buildPlayerImage(c),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
 
                  // Linea divisoria
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        c.withOpacity(0.6),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                  const SizedBox(height: 8),
 
                  // ── Nome ──────────────────────────────────────
                  Text(
                    (player?.name ?? 'Nessun Giocatore').toUpperCase(),
                    style: TextStyle(
                      color: c,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
 
                  // ── Stats a 2 colonne (ora calcolate) ─────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _statCol(c, [
                        (stats.vel, 'VEL'),
                        (stats.tir, 'TIR'),
                        (stats.pas, 'PAS'),
                      ]),
                      Container(
                        width: 1,
                        height: 52,
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        color: c.withOpacity(0.25),
                      ),
                      _statCol(c, [
                        (stats.dri, 'DRI'),
                        (stats.dif, 'DIF'),
                        (stats.fis, 'FIS'),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildPlayerImage(Color c) {
    if (player == null) return const SizedBox();
    if (player.imagePath != null &&
        player.imagePath!.isNotEmpty &&
        File(player.imagePath!).existsSync()) {
      return Image.file(
        File(player.imagePath!),
        fit: BoxFit.contain,
        alignment: Alignment.topCenter,
      );
    }
    final icon = getPlayerIcon(player.icon);
    if (icon.isAsset) {
      return Image.asset(icon.assetPath!, fit: BoxFit.contain);
    }
    return Icon(icon.iconData ?? Icons.person_rounded,
        color: c.withOpacity(0.6), size: 80);
  }
 
  Widget _statCol(Color c, List<(int, String)> stats) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: stats
            .map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${s.$1}',
                          style: TextStyle(
                            color: c,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                      Text(
                        s.$2,
                        style: TextStyle(
                          color: c.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      );
}
 
 
// ─────────────────────────────────────────────────────────────
// Service: notizie calcio da feed RSS italiani
// Fonti: Gazzetta dello Sport + Corriere dello Sport + Tuttosport
// ─────────────────────────────────────────────────────────────
class _FootballNewsService {
  /// Feed Google News RSS — gratuito, aggregato, sempre UTF-8.
  /// Ogni entry è (url, prefisso, limite notizie).
  static const _feeds = [
    (
      'https://news.google.com/rss/search?q=serie+a&hl=it&gl=IT&ceid=IT:it',
      '🇮🇹 Serie A:',
      6,
    ),
    (
      'https://news.google.com/rss/search?q=calcio+italiano&hl=it&gl=IT&ceid=IT:it',
      '⚽',
      5,
    ),
    (
      'https://news.google.com/rss/search?q=champions+league&hl=it&gl=IT&ceid=IT:it',
      '🏆 UCL:',
      4,
    ),
  ];

  static Future<List<String>> fetchLatestNews() async {
    final List<String> results = [];

    // Scarica tutti i feed in parallelo
    await Future.wait(
      _feeds.map((f) => _fetchRssFeed(f.$1, prefix: f.$2, results: results, limit: f.$3)),
    );

    // Mischia le notizie per varietà di fonte
    results.shuffle();

    if (results.isEmpty) {
      results.addAll([
        '⚽ Nessuna notizia disponibile al momento',
        '📡 Controlla la connessione internet',
      ]);
    }

    return results;
  }

  /// Scarica e parsa un feed RSS, estrae i titoli degli articoli.
  static Future<void> _fetchRssFeed(
    String url, {
    required String prefix,
    required List<String> results,
    int limit = 5,
  }) async {
    try {
      final resp = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; CalcettoTracker/1.0)',
          'Accept': 'application/rss+xml, application/xml, text/xml',
        },
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode != 200) return;

      // Rileva l'encoding dichiarato nel feed (es. ISO-8859-1, Windows-1252)
      // e decodifica di conseguenza; fallback a UTF-8
      final body = _decodeRssBody(resp.bodyBytes);
      final titles = _parseRssTitles(body, limit: limit);

      for (final title in titles) {
        if (title.isNotEmpty) {
          results.add('$prefix $title');
        }
      }
    } catch (_) {}
  }

  /// Google News RSS è sempre UTF-8; fallback con allowMalformed per sicurezza.
  static String _decodeRssBody(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return utf8.decode(bytes, allowMalformed: true);
    }
  }


  /// Estrae i titoli dagli <item> di un feed RSS tramite regex leggera
  /// (senza dipendenze esterne come xml package).
  static List<String> _parseRssTitles(String xml, {int limit = 5}) {
    final titles = <String>[];

    final itemRegex = RegExp(r'<item[^>]*>([\s\S]*?)<\/item>', caseSensitive: false);
    final titleRegex = RegExp(
      r'<title[^>]*><!\[CDATA\[([\s\S]*?)\]\]><\/title>|<title[^>]*>([\s\S]*?)<\/title>',
      caseSensitive: false,
    );

    for (final item in itemRegex.allMatches(xml)) {
      if (titles.length >= limit) break;
      final itemContent = item.group(1) ?? '';
      final titleMatch = titleRegex.firstMatch(itemContent);
      if (titleMatch == null) continue;

      var title = (titleMatch.group(1) ?? titleMatch.group(2) ?? '').trim();
      title = title.replaceAll(RegExp(r'<[^>]+>'), '').trim();
      title = title
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll('&nbsp;', ' ');

      if (title.length < 10) continue;
      titles.add(title);
    }

    return titles;
  }
}

 
// ─────────────────────────────────────────────────────────────
// Service: news AI stile Sky Sport 24 basate sui dati locali
// ─────────────────────────────────────────────────────────────
class _AiNewsService {
  static const _storageKey = 'openai_api_key';
  static const _storage = FlutterSecureStorage();
 
/// Genera titoli stile ticker TV sportivo basati sui giocatori/partite locali.
/// Legge SEMPRE direttamente da HiveBoxes per dati 100% aggiornati,
/// indipendentemente dallo stato del DataService provider.
static Future<List<String>> generateAiNews(DataService data) async {
  final apiKey = await _storage.read(key: _storageKey);
  if (apiKey == null || apiKey.isEmpty) return [];

  // ── Legge da HiveBoxes (come fa _buildSystemPrompt in ai_coach_page) ──
  final players = HiveBoxes.playersBox.values.toList();
  final matches = HiveBoxes.matchesBox.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  if (players.isEmpty) return [];

  String resolveName(String id) {
    if (id.isEmpty) return '';
    return HiveBoxes.playersBox.get(id)?.name ?? id;
  }

  final buffer = StringBuffer();
  buffer.writeln('GIOCATORI REGISTRATI:');
  for (final p in players.take(12)) {
    int gol = 0, pg = 0, vinte = 0, mvp = p.mvpCount as int;
    double totalVoto = 0; int nVoti = 0;
    for (final m in matches) {
      final inA = m.teamA.contains(p.id);
      final inB = m.teamB.contains(p.id);
      if (!inA && !inB) continue;
      pg++;
      if (m.scoreA != m.scoreB &&
          ((inA && m.scoreA > m.scoreB) || (inB && m.scoreB > m.scoreA))) vinte++;
      gol += (m.goals[p.id] ?? 0) as int;
      if (m.votes.containsKey(p.id)) { totalVoto += m.votes[p.id]!; nVoti++; }
    }
    final voto = nVoti > 0 ? (totalVoto / nVoti).toStringAsFixed(1) : '—';
    buffer.writeln('- ${p.name} (${p.role}): ${pg}PG $vinte W, $gol gol, $mvp MVP, voto medio $voto');
  }

  if (matches.isNotEmpty) {
    buffer.writeln('\nULTIME PARTITE:');
    for (final m in matches.take(5)) {  // già ordinate desc per data
      final scoreStr = '${m.scoreA}–${m.scoreB}';
      final teamA = m.teamA.map(resolveName).where((n) => n.isNotEmpty).join(', ');
      final teamB = m.teamB.map(resolveName).where((n) => n.isNotEmpty).join(', ');
      buffer.writeln('- Squadra Bianca ($teamA) $scoreStr Squadra Colorata ($teamB)');
    }
  }

  final prompt = '''
Sei il ticker di Sky Sport 24. Basandoti SOLO sui seguenti dati reali di una lega di calcetto amatoriale,
genera ESATTAMENTE 8 titoli brevi (max 12 parole ciascuno) stile breaking news / ticker TV sportivo.
Mix consigliato: 3 risultati/statistiche, 2 classifiche/record, 3 gossip/curiosità (inventato ma ispirato ai dati veri).
Usa tono giornalistico-sportivo italiano. NO emoji. Separa ogni titolo con il carattere | su una sola riga.

DATI:
${buffer.toString()}

RISPOSTA (solo i titoli separati da |, nessuna numerazione):''';

  try {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'max_tokens': 300,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    ).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) return [];
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final text = (body['choices'] as List?)
            ?.firstOrNull?['message']?['content'] as String? ?? '';
    return text
        .split('|')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => '🤖 $s')
        .toList();
  } catch (_) {
    return [];
  }
}
}
 
// ─────────────────────────────────────────────────────────────
// Widget: banner scorrevole notizie calcistiche (con AI)
// ─────────────────────────────────────────────────────────────
class SmartNewsTicker extends StatefulWidget {
  const SmartNewsTicker({super.key});
 
  @override
  State<SmartNewsTicker> createState() => _SmartNewsTickerState();
}
 
class _SmartNewsTickerState extends State<SmartNewsTicker> with SingleTickerProviderStateMixin {
  List<String> _items = [];
  bool _loading = true;
 
  late AnimationController _controller;
  double _textWidth = 0;
 
  static const double _pxPerSec = 55.0;
 
  String get _singlePassText => _items.join('     ·     ') + '     ·     ';
 
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _loadNews();
  }
 
  Future<void> _loadNews() async {
    final data = Provider.of<DataService>(context, listen: false);
 
    // Carica news reali e news AI in parallelo
    final results = await Future.wait([
      _FootballNewsService.fetchLatestNews(),
      _AiNewsService.generateAiNews(data),
    ]);
 
    final realNews = results[0];
    final aiNews = results[1];
 
    // Intercala: 1 reale, 2 AI, 1 reale, 2 AI...
    final mixed = <String>[];
    int ri = 0, ai = 0;
    while (ri < realNews.length || ai < aiNews.length) {
      if (ri < realNews.length) { mixed.add(realNews[ri++]); }
      if (ai < aiNews.length)   { mixed.add(aiNews[ai++]); }
      if (ai < aiNews.length)   { mixed.add(aiNews[ai++]); }
    }
 
    if (!mounted) return;
    setState(() {
      _items = mixed.isEmpty ? ['⚽ Nessuna notizia disponibile al momento'] : mixed;
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMarquee());
  }
 
  void _startMarquee() {
    if (_items.isEmpty) return;
    final tp = TextPainter(
      text: TextSpan(
        text: _singlePassText,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: double.infinity);
    _textWidth = tp.width;
    final durationMs = (_textWidth / _pxPerSec * 1000).round();
    _controller.duration = Duration(milliseconds: durationMs);
    _controller.repeat();
  }
 
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
 
  void _openNewsSheet() {
    if (_items.isEmpty) return;
    _controller.stop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewsJournalSheet(items: _items),
    ).whenComplete(() {
      if (mounted) _controller.repeat();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading ? null : _openNewsSheet,
      child: Container(
        height: 30,
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.white24, width: 0.5),
          bottom: BorderSide(color: Colors.white24, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // ── Badge sinistro ────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: AppTheme.accentGreen,
            alignment: Alignment.center,
            child: const Text(
              'CALCIO',
              style: TextStyle(
                color: Colors.black,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Container(width: 0.5, color: Colors.white24),
 
          // ── Area scorrevole ───────────────────
          Expanded(
            child: Stack(
              children: [
                ClipRect(
                  child: _loading
                      ? const Center(
                          child: SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppTheme.accentGold,
                            ),
                          ),
                        )
                      : _items.isEmpty
                          ? const SizedBox()
                          : AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(-_controller.value * _textWidth, 0),
                                  child: child,
                                );
                              },
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _singlePassText + _singlePassText,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                            ),
                ),
 
                // Fade sinistro
                Positioned(
                  left: 0, top: 0, bottom: 0, width: 20,
                  child: IgnorePointer(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.black, Colors.transparent]),
                      ),
                    ),
                  ),
                ),
 
                // Fade destro
                Positioned(
                  right: 0, top: 0, bottom: 0, width: 20,
                  child: IgnorePointer(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.transparent, Colors.black]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
 
          Container(width: 0.5, color: Colors.white24),
 
          // ── Badge destro ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: AppTheme.accentGold.withOpacity(0.15),
            alignment: Alignment.center,
            child: const Text(
              'NEWS',
              style: TextStyle(
                color: AppTheme.accentGold,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Colori Gazzetta
// ─────────────────────────────────────────────────────────────
class _GdS {
  static const rosso   = Color(0xFFD00000);
  static const crema   = Color(0xFFF5F0E8);
  static const cremaDark = Color(0xFFEDE7D5);
  static const inchiostro = Color(0xFF1A1A1A);
  static const grigio  = Color(0xFF555555);
  static const grigioLight = Color(0xFF888888);
  static const sepLine = Color(0xFFCCBFA0);
}

// ─────────────────────────────────────────────────────────────
// Immagini calcio usate come copertine per le notizie
// (Unsplash – uso libero)
// ─────────────────────────────────────────────────────────────
const List<String> _newsImages = [
  'https://images.unsplash.com/photo-1522778119026-d647f0596c20?w=600&q=80', // stadio
  'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=600&q=80', // palla
  'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=600&q=80', // giocatore
  'https://images.unsplash.com/photo-1543326727-cf6c39e8f84c?w=600&q=80', // pallone erba
  'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=600&q=80', // tifosi
  'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=600&q=80', // portiere
];

// ─────────────────────────────────────────────────────────────
// Widget: popup stile Gazzetta dello Sport
// ─────────────────────────────────────────────────────────────
class _NewsJournalSheet extends StatelessWidget {
  final List<String> items;
  const _NewsJournalSheet({required this.items});

  bool _isAi(String s) => s.startsWith('🤖');

  String _cleanText(String s) => s
      .replaceFirst(RegExp(r'^🤖\s*'), '')
      .replaceFirst(RegExp(r'^⚽\s*'), '')
      .trim();

  String _imageFor(int index) =>
      _newsImages[index % _newsImages.length];

  // Restituisce la categoria da mostrare sul bollino
  String _category(bool isAi) => isAi ? 'AI COACH' : 'CALCIO';

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final today = DateTime.now();
    final dateStr =
        '${today.day} ${_monthIt(today.month)} ${today.year}'.toUpperCase();

    return Container(
      height: screenH * 0.92,
      decoration: const BoxDecoration(
        color: _GdS.crema,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // ── Handle ───────────────────────────────────────────
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: _GdS.sepLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Testata ───────────────────────────────────────────
          Container(
            color: _GdS.rosso,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Pallone SVG stilizzato
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Text('⚽', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Titolo testata
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LA GAZZETTA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              height: 1,
                            ),
                          ),
                          Text(
                            'DEL CALCETTO',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 4,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Data
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const Text(
                          'EDIZIONE SPECIALE',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 7,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Striscia nera sotto testata
          Container(height: 3, color: _GdS.inchiostro),

          // ── Contenuto ─────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: items.length + 1, // +1 per l'articolo hero
              itemBuilder: (context, i) {
                // Item 0 = articolo hero (prima notizia grande con immagine)
                if (i == 0) {
                  if (items.isEmpty) return const SizedBox();
                  return _HeroArticle(
                    text: _cleanText(items[0]),
                    imageUrl: _imageFor(0),
                    isAi: _isAi(items[0]),
                    category: _category(_isAi(items[0])),
                    number: 1,
                  );
                }

                final idx = i - 1; // indice reale nella lista items
                if (idx >= items.length) return const SizedBox();

                final item = items[idx];
                final isAi = _isAi(item);
                final text = _cleanText(item);

                // Ogni 4 notizie mostra un articolo con immagine thumbnail
                if (idx % 4 == 0 && idx > 0) {
                  return _ThumbArticle(
                    text: text,
                    imageUrl: _imageFor(idx),
                    isAi: isAi,
                    category: _category(isAi),
                    number: idx + 1,
                  );
                }

                return _TextArticle(
                  text: text,
                  isAi: isAi,
                  category: _category(isAi),
                  number: idx + 1,
                );
              },
            ),
          ),

          // ── Footer ───────────────────────────────────────────
          Container(
            color: _GdS.inchiostro,
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
            child: Row(
              children: [
                const Text('⚽', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Text(
                  'CALCETTO TRACKER  ·  ${items.length} NOTIZIE',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: _GdS.rosso,
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthIt(int m) {
    const mesi = ['GEN','FEB','MAR','APR','MAG','GIU',
                   'LUG','AGO','SET','OTT','NOV','DIC'];
    return mesi[m - 1];
  }
}

// ─────────────────────────────────────────────────────────────
// Articolo hero (grande, con immagine a tutta larghezza)
// ─────────────────────────────────────────────────────────────
class _HeroArticle extends StatelessWidget {
  final String text, imageUrl, category;
  final bool isAi;
  final int number;
  const _HeroArticle({
    required this.text,
    required this.imageUrl,
    required this.isAi,
    required this.category,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Immagine hero
        SizedBox(
          height: 200,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: _GdS.cremaDark,
                  child: const Center(
                    child: Icon(Icons.sports_soccer_rounded,
                        color: _GdS.sepLine, size: 48),
                  ),
                ),
              ),
              // Gradiente basso
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.55),
                      ],
                    ),
                  ),
                ),
              ),
              // Bollino categoria
              Positioned(
                top: 10, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  color: isAi ? const Color(0xFFC9A84C) : _GdS.rosso,
                  child: Text(
                    category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Testo titolo hero con numero
        Container(
          color: _GdS.inchiostro,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$number',
                style: const TextStyle(
                  color: _GdS.rosso,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1.35,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),

        Container(height: 4, color: _GdS.rosso),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Articolo con thumbnail (immagine a destra)
// ─────────────────────────────────────────────────────────────
class _ThumbArticle extends StatelessWidget {
  final String text, imageUrl, category;
  final bool isAi;
  final int number;
  const _ThumbArticle({
    required this.text,
    required this.imageUrl,
    required this.isAi,
    required this.category,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Numero rosso
              SizedBox(
                width: 26,
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: _GdS.rosso,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              // Testo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CategoryPill(label: category, isAi: isAi),
                    const SizedBox(height: 6),
                    Text(
                      text,
                      style: const TextStyle(
                        color: _GdS.inchiostro,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 90, height: 75,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: _GdS.cremaDark,
                      child: const Icon(Icons.sports_soccer_rounded,
                          color: _GdS.sepLine, size: 28),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(height: 0.5, color: _GdS.sepLine,
            margin: const EdgeInsets.symmetric(horizontal: 14)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Articolo solo testo (stile notizia breve)
// ─────────────────────────────────────────────────────────────
class _TextArticle extends StatelessWidget {
  final String text, category;
  final bool isAi;
  final int number;
  const _TextArticle({
    required this.text,
    required this.isAi,
    required this.category,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Numero articolo in rosso
              SizedBox(
                width: 26,
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: _GdS.rosso,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              // Testo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CategoryPill(label: category, isAi: isAi),
                    const SizedBox(height: 5),
                    Text(
                      text,
                      style: const TextStyle(
                        color: _GdS.inchiostro,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(height: 0.5, color: _GdS.sepLine,
            margin: const EdgeInsets.symmetric(horizontal: 14)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bollino categoria (rosso / oro)
// ─────────────────────────────────────────────────────────────
class _CategoryPill extends StatelessWidget {
  final String label;
  final bool isAi;
  const _CategoryPill({required this.label, required this.isAi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      color: isAi ? const Color(0xFFC9A84C) : _GdS.rosso,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

 
class _CardPatternPainter extends CustomPainter {
  final Color color;
  _CardPatternPainter(this.color);
 
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.04)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
 
    const spacing = 18.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }
 
  @override
  bool shouldRepaint(_CardPatternPainter old) => old.color != color;
}