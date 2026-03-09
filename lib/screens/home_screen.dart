import 'package:calcetto_tracker/screens/history_match.dart';
import 'package:calcetto_tracker/screens/stats_screen.dart';
import 'package:calcetto_tracker/screens/backup_screen.dart';
import 'package:flutter/material.dart';
import 'players_screen.dart';
import 'match_promo_form_page.dart';
import 'new_match_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Champions Calcetto Stats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistiche',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Storico partite',
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HistoryMatch()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.rss_feed),
            tooltip: 'Promuovi partita',
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MatchPromoFormPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Giocatori',
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PlayersScreen()));
            },
          ),
          // ✅ NUOVO: bottone Backup & Ripristino
          IconButton(
            icon: const Icon(Icons.backup_rounded),
            tooltip: 'Backup & Ripristino CSV',
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const BackupScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nuova partita',
            onPressed: () {
              Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const NewMatchScreen()))
                  .then((_) => setState(() {}));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                final maxHeight = constraints.maxHeight;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        "assets/images/backgroundStadium.png",
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(
                      width: maxWidth,
                      height: maxHeight,
                      child: Image.asset(
                        "assets/shields/GoldShield.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned(
                      top: maxHeight * -0.3,
                      child: Align(
                        child: Transform.scale(
                          scale: 0.25,
                          child: Image.asset(
                            "assets/icons/jack-removebg.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: maxHeight * 0.55,
                      child: Align(
                        child: FifaStats(
                          vel: 78,
                          tir: 61,
                          pas: 76,
                          dri: 56,
                          dif: 70,
                          fis: 77,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    spreadRadius: 2,
                    blurRadius: 8,
                  )
                ],
                image: const DecorationImage(
                  image: AssetImage("assets/images/backgroundcity.png"),
                  fit: BoxFit.cover,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "INFO GENERICHE",
                      style: TextStyle(
                        fontSize: 18,         // ✅ ridotto da 24
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StatRow(label: "Data di Nascita", value: "10 Agosto 1991"),
                    StatRow(label: "Ruolo", value: "Attaccante"),
                    StatRow(label: "Piede Preferito", value: "Sinistro"),
                    StatRow(label: "Nazionalità", value: "Italiana"),
                    StatRow(label: "Squadra Preferita", value: "Juventus"),
                    StatRow(label: "Numero di Maglia", value: "21"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── StatRow ───────────────────────────────────────────────────

class StatRow extends StatelessWidget {
  final String label;
  final String value;

  const StatRow({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5), // ✅ ridotto da 10
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),   // ✅ ridotto da 18
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ── FifaStats ─────────────────────────────────────────────────

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
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStat('$vel', 'VEL'),
            _buildStat('$tir', 'TIR'),
            _buildStat('$pas', 'PAS'),
          ],
        ),
        const SizedBox(width: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStat('$dri', 'DRI'),
            _buildStat('$dif', 'DIF'),
            _buildStat('$fis', 'FIS'),
          ],
        ),
      ],
    );
  }

  Widget _buildStat(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(value,
              style: const TextStyle(
                fontFamily: 'FUT',
                fontSize: 22,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                fontFamily: 'FUT',
                fontSize: 18,
                color: Colors.black,
                letterSpacing: 1,
              )),
        ],
      ),
    );
  }
}
