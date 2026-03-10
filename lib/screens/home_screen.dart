import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'players_screen.dart';
import 'match_promo_form_page.dart';
import 'new_match_screen.dart';
import 'history_match.dart';
import 'stats_screen.dart';
import 'backup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: const FifaLabel('Champions Calcetto Stats', color: AppTheme.textPrimary, fontSize: 12),
        actions: [
          IconButton(
            icon: const Icon(Icons.backup_rounded, color: AppTheme.textSecondary, size: 22),
            tooltip: 'Backup CSV',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BackupScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.campaign_rounded, color: AppTheme.textSecondary, size: 22),
            tooltip: 'Promuovi partita',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MatchPromoFormPage())),
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
              // Dimensione scudo: occupa 85% della larghezza o altezza (il minore)
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
                          // Icona giocatore sovrapposta allo scudo
                          Positioned(
                            top: shieldSize * 0.08,
                            child: SizedBox(
                              width: shieldSize * 0.55,
                              height: shieldSize * 0.55,
                              child: Image.asset(
                                'assets/icons/jack-removebg.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          // Stats FIFA nella parte bassa dello scudo
                          Positioned(
                            bottom: shieldSize * 0.08,
                            child: const FifaStats(
                              vel: 78, tir: 61, pas: 76,
                              dri: 56, dif: 70, fis: 77,
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

          // ── Info giocatore ────────────────────────────────────
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/images/backgroundcity.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.55), Colors.black.withOpacity(0.8)],
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FifaLabel('Info Giocatore', color: AppTheme.accentGold, fontSize: 10),
                      const SizedBox(height: 10),
                      _InfoRow('DATA DI NASCITA', '10 Agosto 1991'),
                      _InfoRow('RUOLO', 'Attaccante'),
                      _InfoRow('PIEDE', 'Sinistro'),
                      _InfoRow('NAZIONALITÀ', 'Italiana'),
                      _InfoRow('SQUADRA DEL CUORE', 'Juventus'),
                      _InfoRow('NUMERO DI MAGLIA', '21'),
                    ],
                  ),
                ),
              ),
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
            _NavBtn(icon: Icons.history_rounded, label: 'STORICO',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryMatch())).then((_) => setState(() {}))),
            _NavBtn(icon: Icons.bar_chart_rounded, label: 'STATS',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen()))),
            // Bottone centrale add
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NewMatchScreen())).then((_) => setState(() {})),
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppTheme.accentGreen.withOpacity(0.4),
                      blurRadius: 16, spreadRadius: 2)],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.black, size: 30),
              ),
            ),
            _NavBtn(icon: Icons.people_rounded, label: 'ROSA',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayersScreen())).then((_) => setState(() {}))),
            _NavBtn(icon: Icons.campaign_rounded, label: 'PROMO',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchPromoFormPage()))),
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
          Text(label, style: const TextStyle(
            color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
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
        Text(label, style: const TextStyle(
            color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1)),
        Text(value, style: const TextStyle(
            color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class FifaStats extends StatelessWidget {
  final int vel, tir, pas, dri, dif, fis;
  const FifaStats({super.key, required this.vel, required this.tir,
      required this.pas, required this.dri, required this.dif, required this.fis});

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
      Text(val, style: const TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.w900)),
      const SizedBox(width: 6),
      Text(lbl, style: const TextStyle(fontSize: 16, color: Colors.black, letterSpacing: 1)),
    ]),
  );
}
