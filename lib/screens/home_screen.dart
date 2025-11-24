import 'package:calcetto_tracker/screens/stats_screen.dart';
import 'package:flutter/material.dart';
import '../services/data_service.dart';
import 'players_screen.dart';
import 'match_promo_form_page.dart';
import 'new_match_screen.dart';
import '../widgets/match_card.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataService>(context);
    final matches = data.getAllMatches();

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
            icon: const Icon(Icons.rss_feed),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MatchPromoFormPage()));
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
      body: matches.isEmpty
          ? const Center(child: Text('Nessuna partita registrata'))
          : ListView.builder(
              itemCount: matches.length,
              itemBuilder: (_, i) => MatchCard(match: matches[i]),
            ),
    );
  }
}
