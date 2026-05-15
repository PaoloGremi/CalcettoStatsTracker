import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../widgets/match_card.dart';
import 'package:provider/provider.dart';
import 'calendar_match_screen.dart';

class HistoryMatch extends StatefulWidget {
  const HistoryMatch({super.key});

  @override
  State<HistoryMatch> createState() => _HistoryMatchState();
}

class _HistoryMatchState extends State<HistoryMatch> {
  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataService>(context);
    final matches = data.getAllMatches();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History Match'),
        actions: [
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Vista Calendario',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CalendarMatchScreen(matches: matches),
                ),
              );
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
