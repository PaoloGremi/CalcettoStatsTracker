import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

          // ── Hero card scudo FIFA ──────────────────────────────
          Expanded(
            flex: 5,
            child: LayoutBuilder(builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final shieldSize = (w * 0.85).clamp(0.0, h * 0.95);

              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.hardEdge,
                children: [
                  // Sfondo stadio
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/backgroundStadium.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Overlay gradiente
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Scudo centrato
                  Center(
                    child: SizedBox(
                      width: shieldSize,
                      height: shieldSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Immagine scudo
                          Image.asset(
                            'assets/shields/GoldShield.png',
                            width: shieldSize,
                            height: shieldSize,
                            fit: BoxFit.contain,
                          ),
                          // Avatar giocatore principale
                          Positioned(
                            top: shieldSize * 0.08,
                            child: SizedBox(
                              width: shieldSize * 0.55,
                              height: shieldSize * 0.55,
                              child: _buildShieldAvatar(mainPlayer, shieldSize),
                            ),
                          ),
                          // Stats FIFA
                          Positioned(
                            bottom: shieldSize * 0.08,
                            child: FifaStats(
                              vel: _settings.vel,
                              tir: _settings.tir,
                              pas: _settings.pas,
                              dri: _settings.dri,
                              dif: _settings.dif,
                              fis: _settings.fis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),

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
              icon: Icons.campaign_rounded,
              label: 'PROMO',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MatchPromoFormPage())),
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

              // ── Info anagrafiche ──────────────────────────────
              if (settings.birthDate.isNotEmpty)
                _InfoRow('DATA DI NASCITA', settings.birthDate),
              if (settings.nationality.isNotEmpty)
                _InfoRow('NAZIONALITÀ', settings.nationality),
              if (settings.favoriteTeam.isNotEmpty)
                _InfoRow('SQUADRA DEL CUORE', settings.favoriteTeam),
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
