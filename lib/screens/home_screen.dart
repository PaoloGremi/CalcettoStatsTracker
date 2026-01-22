import 'package:calcetto_tracker/screens/history_match.dart';
import 'package:calcetto_tracker/screens/stats_screen.dart';
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HistoryMatch()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.rss_feed),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MatchPromoFormPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PlayersScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
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
                    // 🔥 Immagine di sfondo
                    Positioned.fill(
                      child: Image.asset(
                        "assets/images/backgroundStadium.png",
                        fit: BoxFit
                            .cover, // Puoi usare contain o fill a seconda dell’effetto
                      ),
                    ),
                    // Scudo grande
                    SizedBox(
                      width: maxWidth, // 90% della larghezza disponibile
                      height: maxHeight, // 95% dell'altezza disponibile
                      child: Image.asset(
                        "assets/shields/GoldShield.png",
                        fit: BoxFit.contain,
                      ),
                    ),

                    // Avatar posizionato nella parte superiore dello scudo
                    Positioned(
                      top: maxHeight *
                          -0.3, // leggermente sotto il bordo superiore dello scudo

                      child: Align(
                        //alignment: Alignment(0.5, -1), // <-- più negativo = più in alto
                        child: Transform.scale(
                          scale:
                              0.25, // <-- riduci proporzionalmente (1.0 = 100%)
                          child: Image.asset(
                            "assets/icons/jack-removebg.png",
                            //width: 138, // doppio del raggio per coprire tutto il cerchio
                            //height: 138,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                        top: maxHeight *
                            0.55, // leggermente sotto il bordo superiore dello scudo
                        child: Align(
                            child: FifaStats(
                                pac: 89,
                                sho: 74,
                                pas: 78,
                                dri: 81,
                                def: 71,
                                phy: 73))),
                  ],
                );
              },
            ),
          ),
          // Metà inferiore – statistiche
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    spreadRadius: 2,
                    blurRadius: 8,
                  )
                ],
                image: const DecorationImage(
                  image: AssetImage(
                      "assets/images/backgroundcity.png"), // <-- tua immagine
                  fit:
                      BoxFit.cover, // COPRE tutta l’area mantenendo proporzioni
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "INFO GENERICHE",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // consigliato con background scuro
                    ),
                  ),
                  const SizedBox(height: 10),
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
        ],
      ),
    );
  }
}

/// RIGA STATS
class StatRow extends StatelessWidget {
  final String label;
  final String value;

  const StatRow({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 18)),
          Text(value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class FifaStats extends StatelessWidget {
  final int pac;
  final int sho;
  final int pas;
  final int dri;
  final int def;
  final int phy;

  const FifaStats({
    Key? key,
    required this.pac,
    required this.sho,
    required this.pas,
    required this.dri,
    required this.def,
    required this.phy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // COLONNA SINISTRA
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStat("$pac", "PAC"),
            _buildStat("$sho", "SHO"),
            _buildStat("$pas", "PAS"),
          ],
        ),

        const SizedBox(width: 24),

        // COLONNA DESTRA
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStat("$dri", "DRI"),
            _buildStat("$def", "DEF"),
            _buildStat("$phy", "PHY"),
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
          Text(
            value,
            style: const TextStyle(
              fontFamily: "FUT", // opzionale se hai font custom
              fontSize: 22,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: "FUT",
              fontSize: 18,
              color: Colors.black,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
