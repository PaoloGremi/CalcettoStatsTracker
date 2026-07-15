import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:calcetto_tracker/screens/ai_coach_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../core/network/openai_service.dart';
import '../core/util/player_lookup.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../features/players/presentation/pages/players_page.dart';
import 'match_promo_form_page.dart';
import 'new_match_screen.dart';
import 'history_match.dart';
import 'stats_screen.dart';
import 'backup_screen.dart';
import '../data/player_icons.dart';
import 'settings_screen.dart';
import 'fields_screen.dart';
import '../services/player_stats_calculator.dart';

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
    final hasCustomAvatar =
        player.imagePath != null && File(player.imagePath!).existsSync();
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
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.75),
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
                      final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()));
                      if (updated == true) _loadSettings();
                    },
                    child: Container(
                      color: AppTheme.surface,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_rounded,
                              color: AppTheme.accentGold.withValues(alpha: 0.5),
                              size: 40),
                          const SizedBox(height: 12),
                          const Text(
                            'Configura il tuo profilo',
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
                      final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()));
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.accentGreen.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 2)
                  ],
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.black, size: 30),
              ),
            ),
            _NavBtn(
              icon: Icons.people_rounded,
              label: 'ROSA',
              onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PlayersPage()))
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
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    letterSpacing: 1)),
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
    required this.vel,
    required this.tir,
    required this.pas,
    required this.dri,
    required this.dif,
    required this.fis,
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
                  fontSize: 22,
                  color: Colors.black,
                  fontWeight: FontWeight.w900)),
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
  final dynamic player; // Player
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
    int countGoals(DataService d, String playerId) {
      int total = 0;
      for (final m in d.getAllMatches()) {
        total += (m.goals[playerId] ?? 0);
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
              Colors.black.withValues(alpha: 0.6),
              Colors.black.withValues(alpha: 0.88),
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
                            FifaBadge(
                                settings.foot == 'Destro'
                                    ? '🦶D'
                                    : settings.foot == 'Sinistro'
                                        ? '🦶S'
                                        : '🦶B',
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
                  _StatBox(
                      value: '$gamesPlayed',
                      label: 'PARTITE',
                      color: AppTheme.accentBlue),
                  const SizedBox(width: 8),
                  _StatBox(
                      value: '$wins',
                      label: 'VINTE',
                      color: AppTheme.accentGreen),
                  const SizedBox(width: 8),
                  _StatBox(
                      value: '$draws',
                      label: 'PAREGGI',
                      color: AppTheme.accentGold),
                  const SizedBox(width: 8),
                  _StatBox(
                      value: '$losses',
                      label: 'PERSE',
                      color: AppTheme.accentRed),
                  const SizedBox(width: 8),
                  _StatBox(
                    value: votesCount > 0 ? avgVote.toStringAsFixed(1) : '—',
                    label: 'VOTO',
                    color: votesCount > 0
                        ? voteColor(avgVote)
                        : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 8),
                  _StatBox(
                      value: '$winPct%',
                      label: 'WIN%',
                      color: AppTheme.accentOrange),
                ],
              ),

              // ── Badge premi ───────────────────────────────────
              if (player.mvpCount > 0 ||
                  player.hustleCount > 0 ||
                  player.bestGoalCount > 0) ...[
                const SizedBox(height: 10),
                Row(children: [
                  if (player.mvpCount > 0) ...[
                    _AwardPill(
                        '👑', 'MVP', player.mvpCount, AppTheme.accentGold),
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
              if (settings.goalMatches > 0 ||
                  settings.goalWins > 0 ||
                  settings.goalGoals > 0 ||
                  settings.goalMvp > 0) ...[
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
                    current: countGoals(data, player.id as String),
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
              if (settings.birthDate.isNotEmpty ||
                  settings.nationality.isNotEmpty ||
                  settings.favoriteTeam.isNotEmpty ||
                  settings.foot.isNotEmpty) ...[
                if (settings.birthDate.isNotEmpty)
                  _InfoRow('DATA DI NASCITA', settings.birthDate),
                if (settings.nationality.isNotEmpty)
                  _InfoRow('NAZIONALITÀ', settings.nationality),
                if (settings.favoriteTeam.isNotEmpty)
                  _InfoRow('SQUADRA DEL CUORE', settings.favoriteTeam),
                if (settings.foot.isNotEmpty) _InfoRow('PIEDE', settings.foot),
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
  const _StatBox(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 5),
            Text(
              '$label ×$count',
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
              Text(
                label,
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
              backgroundColor: color.withValues(alpha: 0.12),
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
            c.withValues(alpha: 0.25),
            Colors.black.withValues(alpha: 0.85),
            c.withValues(alpha: 0.15),
          ],
        ),
        border: Border.all(color: c.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.45),
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
                                      color: c.withValues(alpha: 0.5),
                                      width: 1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#${settings.jerseyNumber}',
                                  style: TextStyle(
                                    color: c.withValues(alpha: 0.85),
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
                                        color: c.withValues(alpha: 0.3),
                                        size: 80),
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
                        c.withValues(alpha: 0.6),
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
                        color: c.withValues(alpha: 0.25),
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
        color: c.withValues(alpha: 0.6), size: 80);
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
                          color: c.withValues(alpha: 0.7),
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
      _feeds.map((f) =>
          _fetchRssFeed(f.$1, prefix: f.$2, results: results, limit: f.$3)),
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

  /// Estrae i titoli dagli `<item>` di un feed RSS tramite regex leggera
  /// (senza dipendenze esterne come xml package).
  static List<String> _parseRssTitles(String xml, {int limit = 5}) {
    final titles = <String>[];

    final itemRegex =
        RegExp(r'<item[^>]*>([\s\S]*?)<\/item>', caseSensitive: false);
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
  static final _openAiService = OpenAiService();

  /// Genera titoli stile ticker TV sportivo basati sui giocatori/partite locali.
  /// DataService legge sempre live da Hive (nessun caching), quindi i dati
  /// sono aggiornati indipendentemente da quando il Provider è stato creato.
  static Future<List<String>> generateAiNews(DataService data) async {
    final apiKey = await _openAiService.readApiKey();
    if (apiKey == null || apiKey.isEmpty) return [];

    final players = data.getAllPlayers();
    final matches = data.getAllMatches();

    if (players.isEmpty) return [];

    String resolveName(String id) => resolvePlayerName(id);

    final buffer = StringBuffer();
    buffer.writeln('GIOCATORI REGISTRATI:');
    for (final p in players.take(12)) {
      int gol = 0, pg = 0, vinte = 0, mvp = p.mvpCount;
      double totalVoto = 0;
      int nVoti = 0;
      for (final m in matches) {
        final inA = m.teamA.contains(p.id);
        final inB = m.teamB.contains(p.id);
        if (!inA && !inB) continue;
        pg++;
        if (m.scoreA != m.scoreB &&
            ((inA && m.scoreA > m.scoreB) || (inB && m.scoreB > m.scoreA))) {
          vinte++;
        }
        gol += (m.goals[p.id] ?? 0);
        if (m.votes.containsKey(p.id)) {
          totalVoto += m.votes[p.id]!;
          nVoti++;
        }
      }
      final voto = nVoti > 0 ? (totalVoto / nVoti).toStringAsFixed(1) : '—';
      buffer.writeln(
          '- ${p.name} (${p.role}): ${pg}PG $vinte W, $gol gol, $mvp MVP, voto medio $voto');
    }

    if (matches.isNotEmpty) {
      buffer.writeln('\nULTIME PARTITE:');
      for (final m in matches.take(5)) {
        // già ordinate desc per data
        final scoreStr = '${m.scoreA}–${m.scoreB}';
        final teamA =
            m.teamA.map(resolveName).where((n) => n.isNotEmpty).join(', ');
        final teamB =
            m.teamB.map(resolveName).where((n) => n.isNotEmpty).join(', ');
        buffer.writeln(
            '- Squadra Bianca ($teamA) $scoreStr Squadra Colorata ($teamB)');
      }
    }

    final prompt = '''
Sei il ticker di Sky Sport 24. Basandoti SOLO sui seguenti dati reali di una lega di calcetto amatoriale,
genera ESATTAMENTE 15 titoli brevi (max 22 parole ciascuno) stile breaking news / ticker TV sportivo.
Mix consigliato: 5 risultati/statistiche, 5 classifiche/record, 5 gossip/curiosità (inventato ma ispirato ai dati veri e messi in ordine random).
Usa tono giornalistico-sportivo italiano. NO emoji. Separa ogni titolo con il carattere | su una sola riga.

DATI:
${buffer.toString()}

RISPOSTA (solo i titoli separati da |, nessuna numerazione):''';

    try {
      final text = await _openAiService.chatCompletion(
        apiKey: apiKey,
        model: 'gpt-4o-mini',
        maxTokens: 300,
        messages: [
          {'role': 'user', 'content': prompt}
        ],
      );
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

class _SmartNewsTickerState extends State<SmartNewsTicker>
    with SingleTickerProviderStateMixin {
  List<String> _items = [];
  bool _loading = true;

  late AnimationController _controller;
  double _textWidth = 0;

  static const double _pxPerSec = 55.0;

  String get _singlePassText => '${_items.join('     ·     ')}     ·     ';

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 5));
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
      if (ri < realNews.length) {
        mixed.add(realNews[ri++]);
      }
      if (ai < aiNews.length) {
        mixed.add(aiNews[ai++]);
      }
      if (ai < aiNews.length) {
        mixed.add(aiNews[ai++]);
      }
    }

    if (!mounted) return;
    setState(() {
      _items =
          mixed.isEmpty ? ['⚽ Nessuna notizia disponibile al momento'] : mixed;
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMarquee());
  }

  void _startMarquee() {
    if (_items.isEmpty) return;
    final tp = TextPainter(
      text: TextSpan(
        text: _singlePassText,
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3),
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
                                    offset: Offset(
                                        -_controller.value * _textWidth, 0),
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
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 20,
                    child: IgnorePointer(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              colors: [Colors.black, Colors.transparent]),
                        ),
                      ),
                    ),
                  ),

                  // Fade destro
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 20,
                    child: IgnorePointer(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.black]),
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
              color: AppTheme.accentGold.withValues(alpha: 0.15),
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
  static const rosso = Color(0xFFD00000);
  static const crema = Color(0xFFF5F0E8);
  static const cremaDark = Color(0xFFEDE7D5);
  static const inchiostro = Color(0xFF1A1A1A);
  static const sepLine = Color(0xFFCCBFA0);
}

// ─────────────────────────────────────────────────────────────
// Immagini calcio (Unsplash – free to use)
// ─────────────────────────────────────────────────────────────
const List<String> _newsImages = [
  // Serie originale
  'https://images.unsplash.com/photo-1522778119026-d647f0596c20?w=800&q=80',
  'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800&q=80',
  'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=800&q=80',
  'https://images.unsplash.com/photo-1543326727-cf6c39e8f84c?w=800&q=80',
  'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800&q=80',
  'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800&q=80',
  // Immagini aggiuntive – calcio / calcetto / stadio
  'https://images.unsplash.com/photo-1553778263-73a83bab9b0c?w=800&q=80',
  'https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d?w=800&q=80',
  'https://images.unsplash.com/photo-1551958219-acbc630e2914?w=800&q=80',
  'https://images.unsplash.com/photo-1560272564-c83b66b1ad12?w=800&q=80',
  'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800&q=80',
  'https://images.unsplash.com/photo-1517466787929-bc90951d0974?w=800&q=80',
  'https://images.unsplash.com/photo-1518604666860-9ed391f76460?w=800&q=80',
  'https://images.unsplash.com/photo-1589487391730-58f20eb2c308?w=800&q=80',
  'https://images.unsplash.com/photo-1471295253337-3ceaaedca402?w=800&q=80',
  'https://images.unsplash.com/photo-1547347298-4074fc3086f0?w=800&q=80',
  'https://images.unsplash.com/photo-1606925797300-0b35e9d1794e?w=800&q=80',
  'https://images.unsplash.com/photo-1459865264687-595d652de67e?w=800&q=80',
  'https://images.unsplash.com/photo-1530128118208-89f7e4edec1e?w=800&q=80',
  'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=800&q=80',
];

// ─────────────────────────────────────────────────────────────
// Mescola notizie reali e AI in modo alternato
// ─────────────────────────────────────────────────────────────
List<String> _interleaveNews(List<String> items) {
  final real = items.where((s) => !s.startsWith('🤖')).toList();
  final ai = items.where((s) => s.startsWith('🤖')).toList();
  if (real.isEmpty) return ai;
  if (ai.isEmpty) return real;
  final result = <String>[];
  int r = 0, a = 0;
  while (r < real.length && a < ai.length) {
    result.add(real[r++]);
    result.add(ai[a++]);
  }
  while (r < real.length) {
    result.add(real[r++]);
  }
  while (a < ai.length) {
    result.add(ai[a++]);
  }
  return result;
}

// ─────────────────────────────────────────────────────────────
// Suddivide le notizie in "pagine" da distribuire nel giornale
// ─────────────────────────────────────────────────────────────
List<List<String>> _splitIntoPages(List<String> items) {
  if (items.isEmpty) return [];
  final mixed = _interleaveNews(items);
  final pages = <List<String>>[];
  pages.add(mixed.take(3).toList());
  int i = 3;
  while (i < mixed.length) {
    pages.add(mixed.sublist(i, (i + 4).clamp(0, mixed.length)));
    i += 4;
  }
  return pages;
}

// ─────────────────────────────────────────────────────────────
// Sheet principale – PageView con effetto page-flip
// ─────────────────────────────────────────────────────────────
class _NewsJournalSheet extends StatefulWidget {
  final List<String> items;
  const _NewsJournalSheet({required this.items});

  @override
  State<_NewsJournalSheet> createState() => _NewsJournalSheetState();
}

class _NewsJournalSheetState extends State<_NewsJournalSheet> {
  late final PageController _pageCtrl;
  int _currentPage = 0;

  bool _isAi(String s) => s.startsWith('🤖');
  String _clean(String s) => s
      .replaceFirst(RegExp(r'^🤖\s*'), '')
      .replaceFirst(RegExp(r'^⚽\s*'), '')
      .trim();
  String _imgFor(int i) => _newsImages[i % _newsImages.length];
  String _category(bool ai) => ai ? 'AI COACH' : 'CALCIO';
  int _globalNum(int pi, int pos) =>
      pi == 0 ? pos + 1 : 3 + (pi - 1) * 4 + pos + 1;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.92);
    _pageCtrl.addListener(() {
      final p = _pageCtrl.page?.round() ?? 0;
      if (p != _currentPage) setState(() => _currentPage = p);
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    final pages = _splitIntoPages(widget.items);
    if (page < 0 || page >= pages.length) return;
    _pageCtrl.animateToPage(
      page,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final pages = _splitIntoPages(widget.items);
    final today = DateTime.now();
    final dateStr =
        '${today.day} ${_monthIt(today.month)} ${today.year}'.toUpperCase();

    return Container(
      height: screenH * 0.94,
      decoration: const BoxDecoration(
        color: Color(0xFFE0D8C8), // sfondo "cassetto" leggermente più scuro
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // ── Handle ───────────────────────────────────────────
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _GdS.sepLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          _GdSHeader(
            dateStr: dateStr,
            pageNum: _currentPage + 1,
            totalPages: pages.length,
          ),

          // ── PageView con swipe ────────────────────────────────
          Expanded(
            child: pages.isEmpty
                ? const Center(child: Text('Nessuna notizia'))
                : PageView.builder(
                    controller: _pageCtrl,
                    itemCount: pages.length,
                    onPageChanged: (p) => setState(() => _currentPage = p),
                    itemBuilder: (ctx, pi) {
                      return AnimatedBuilder(
                        animation: _pageCtrl,
                        builder: (ctx, child) {
                          // offset della pagina rispetto a quella corrente
                          double offset = 0;
                          if (_pageCtrl.hasClients && _pageCtrl.page != null) {
                            offset =
                                (_pageCtrl.page! - pi).abs().clamp(0.0, 1.0);
                          }
                          // Scala e ombra in base alla distanza
                          final scale = 1.0 - offset * 0.04;
                          final shadowBlur = 16.0 + offset * 0;

                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 8),
                              decoration: BoxDecoration(
                                color: _GdS.crema,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.18 + offset * 0.0),
                                    blurRadius: shadowBlur,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: child,
                            ),
                          );
                        },
                        child: pi == 0
                            ? _FrontPage(
                                pageItems: pages[pi],
                                pageIndex: pi,
                                isAi: _isAi,
                                clean: _clean,
                                imgFor: _imgFor,
                                category: _category,
                                globalNum: _globalNum,
                              )
                            : _InnerPage(
                                pageItems: pages[pi],
                                pageIndex: pi,
                                isAi: _isAi,
                                clean: _clean,
                                imgFor: _imgFor,
                                category: _category,
                                globalNum: _globalNum,
                              ),
                      );
                    },
                  ),
          ),

          // ── Barra navigazione ─────────────────────────────────
          _NavBar(
            currentPage: _currentPage,
            totalPages: pages.length,
            onPrev: () => _goTo(_currentPage - 1),
            onNext: () => _goTo(_currentPage + 1),
          ),
        ],
      ),
    );
  }

  String _monthIt(int m) {
    const mesi = [
      'GEN',
      'FEB',
      'MAR',
      'APR',
      'MAG',
      'GIU',
      'LUG',
      'AGO',
      'SET',
      'OTT',
      'NOV',
      'DIC'
    ];
    return mesi[m - 1];
  }
}

// ─────────────────────────────────────────────────────────────
// Testata stile Gazzetta
// ─────────────────────────────────────────────────────────────
class _GdSHeader extends StatelessWidget {
  final String dateStr;
  final int pageNum, totalPages;
  const _GdSHeader(
      {required this.dateStr, required this.pageNum, required this.totalPages});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: _GdS.rosso,
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                    child: Text('⚽', style: TextStyle(fontSize: 19))),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LA GAZZETTA',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            height: 1)),
                    Text('DEL CALCETTO',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                            height: 1.1)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(dateStr,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8)),
                  Text('PAG. $pageNum / $totalPages',
                      style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 8,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
        Container(height: 3, color: _GdS.inchiostro),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Barra navigazione pagine
// ─────────────────────────────────────────────────────────────
class _NavBar extends StatelessWidget {
  final int currentPage, totalPages;
  final VoidCallback onPrev, onNext;
  const _NavBar(
      {required this.currentPage,
      required this.totalPages,
      required this.onPrev,
      required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _GdS.inchiostro,
      padding: EdgeInsets.fromLTRB(
          14, 8, 14, MediaQuery.of(context).padding.bottom + 8),
      child: Row(
        children: [
          // Freccia sinistra
          GestureDetector(
            onTap: currentPage > 0 ? onPrev : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: currentPage > 0 ? _GdS.rosso : Colors.white12,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.chevron_left_rounded,
                      color: currentPage > 0 ? Colors.white : Colors.white38,
                      size: 16),
                  Text('PREC.',
                      style: TextStyle(
                          color:
                              currentPage > 0 ? Colors.white : Colors.white38,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Indicatori pagina
          Row(
            children: List.generate(
                totalPages,
                (i) => Container(
                      width: i == currentPage ? 16 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i == currentPage ? _GdS.rosso : Colors.white24,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )),
          ),
          const Spacer(),
          // Freccia destra
          GestureDetector(
            onTap: currentPage < totalPages - 1 ? onNext : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color:
                    currentPage < totalPages - 1 ? _GdS.rosso : Colors.white12,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Text('SUCC.',
                      style: TextStyle(
                          color: currentPage < totalPages - 1
                              ? Colors.white
                              : Colors.white38,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                  Icon(Icons.chevron_right_rounded,
                      color: currentPage < totalPages - 1
                          ? Colors.white
                          : Colors.white38,
                      size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PRIMA PAGINA – layout Gazzetta (hero grande + 2 notizie spalla)
// ─────────────────────────────────────────────────────────────
class _FrontPage extends StatelessWidget {
  final List<String> pageItems;
  final int pageIndex;
  final bool Function(String) isAi;
  final String Function(String) clean;
  final String Function(int) imgFor;
  final String Function(bool) category;
  final int Function(int, int) globalNum;

  const _FrontPage({
    required this.pageItems,
    required this.pageIndex,
    required this.isAi,
    required this.clean,
    required this.imgFor,
    required this.category,
    required this.globalNum,
  });

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Container(
      color: _GdS.crema,
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Articolo hero ─────────────────────────────────
            if (pageItems.isNotEmpty) ...[
              _buildHero(context, pageItems[0], 0, h),
            ],

            // ── Linea divisoria rossa ─────────────────────────
            Container(
                height: 3,
                color: _GdS.rosso,
                margin: const EdgeInsets.symmetric(vertical: 10)),

            // ── Notizie spalla (affiancate) ───────────────────
            if (pageItems.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int j = 1; j < pageItems.length; j++) ...[
                      if (j > 1)
                        Container(
                            width: 0.5,
                            color: _GdS.sepLine,
                            margin: const EdgeInsets.symmetric(horizontal: 8)),
                      Expanded(
                        child: _ShoulderArticle(
                          text: clean(pageItems[j]),
                          imgUrl: imgFor(j),
                          isAiItem: isAi(pageItems[j]),
                          cat: category(isAi(pageItems[j])),
                          num: globalNum(pageIndex, j),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, String item, int pos, double h) {
    final ai = isAi(item);
    final num = globalNum(pageIndex, pos);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Immagine hero grande
        SizedBox(
          height: h * 0.32,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(imgFor(0),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      color: _GdS.cremaDark,
                      child: const Icon(Icons.sports_soccer_rounded,
                          color: _GdS.sepLine, size: 56))),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7)
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                  top: 10,
                  left: 10,
                  child: _GdSPill(label: category(ai), isAi: ai)),
            ],
          ),
        ),
        // Titolone + numero
        Container(
          color: _GdS.inchiostro,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$num',
                  style: const TextStyle(
                      color: _GdS.rosso,
                      fontSize: 22,
                      fontWeight: FontWeight.w900)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(clean(item),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.35)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PAGINA INTERNA – 4 notizie in layout misto
// ─────────────────────────────────────────────────────────────
class _InnerPage extends StatelessWidget {
  final List<String> pageItems;
  final int pageIndex;
  final bool Function(String) isAi;
  final String Function(String) clean;
  final String Function(int) imgFor;
  final String Function(bool) category;
  final int Function(int, int) globalNum;

  const _InnerPage({
    required this.pageItems,
    required this.pageIndex,
    required this.isAi,
    required this.clean,
    required this.imgFor,
    required this.category,
    required this.globalNum,
  });

  @override
  Widget build(BuildContext context) {
    // Layout: prima notizia con thumbnail, le altre solo testo
    return Container(
      color: _GdS.crema,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
        child: Column(
          children: [
            for (int j = 0; j < pageItems.length; j++) ...[
              _buildItem(j),
              if (j < pageItems.length - 1)
                Container(
                    height: 0.5,
                    color: _GdS.sepLine,
                    margin: const EdgeInsets.symmetric(vertical: 10)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItem(int pos) {
    final item = pageItems[pos];
    final ai = isAi(item);
    final text = clean(item);
    final num = globalNum(pageIndex, pos);
    final hasImg = pos == 0 || pos == 2; // alterna presenza immagine

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Numero
        SizedBox(
          width: 28,
          child: Text('$num',
              style: const TextStyle(
                  color: _GdS.rosso,
                  fontSize: 16,
                  fontWeight: FontWeight.w900)),
        ),
        // Corpo
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GdSPill(label: category(ai), isAi: ai),
              const SizedBox(height: 6),
              if (hasImg) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: Image.network(imgFor(num),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            color: _GdS.cremaDark,
                            child: const Icon(Icons.sports_soccer_rounded,
                                color: _GdS.sepLine, size: 36))),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(text,
                  style: TextStyle(
                    color: _GdS.inchiostro,
                    fontSize: hasImg ? 14 : 13,
                    fontWeight: hasImg ? FontWeight.w800 : FontWeight.w700,
                    height: 1.4,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Notizia spalla (prima pagina, colonna laterale)
// ─────────────────────────────────────────────────────────────
class _ShoulderArticle extends StatelessWidget {
  final String text, imgUrl, cat;
  final bool isAiItem;
  final int num;
  const _ShoulderArticle({
    required this.text,
    required this.imgUrl,
    required this.isAiItem,
    required this.cat,
    required this.num,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(imgUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    color: _GdS.cremaDark,
                    child: const Icon(Icons.sports_soccer_rounded,
                        color: _GdS.sepLine, size: 28))),
          ),
        ),
        const SizedBox(height: 6),
        _GdSPill(label: cat, isAi: isAiItem),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$num',
                style: const TextStyle(
                    color: _GdS.rosso,
                    fontSize: 14,
                    fontWeight: FontWeight.w900)),
            const SizedBox(width: 5),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: _GdS.inchiostro,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.35)),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bollino categoria
// ─────────────────────────────────────────────────────────────
class _GdSPill extends StatelessWidget {
  final String label;
  final bool isAi;
  const _GdSPill({required this.label, required this.isAi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      color: isAi ? const Color(0xFFC9A84C) : _GdS.rosso,
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2)),
    );
  }
}

class _CardPatternPainter extends CustomPainter {
  final Color color;
  _CardPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.04)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 18.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
          Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_CardPatternPainter old) => old.color != color;
}
