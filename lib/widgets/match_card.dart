import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match_model.dart';
import '../data/hive_boxes.dart';
import '../screens/match_detail_screen.dart';
import '../services/data_service.dart';
import 'package:intl/intl.dart';


class MatchCard extends StatelessWidget {
  final MatchModel match;
  const MatchCard({required this.match, super.key});

  String _name(String id) {
    final p = HiveBoxes.playersBox.get(id);
    return p?.name ?? 'Sconosciuto';
  }

  @override
  Widget build(BuildContext context) {
    final playersA = match.teamA.map(_name).join(', ');
    final playersB = match.teamB.map(_name).join(', ');
    final roundedDate = DateTime(
      match.date.year,
      match.date.month,
      match.date.day,
      match.date.hour,
      match.date.minute,
    );
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(roundedDate);

//----------------------------------------------------------------------------------------------
return Card(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
  elevation: 6,
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

  child: ClipRRect(    // serve per applicare il borderRadius all'immagine
    borderRadius: BorderRadius.circular(20),
    child: Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/montanaso.jpg"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            // ignore: deprecated_member_use
            Colors.black.withOpacity(0.25),   // scurisce leggermente lo sfondo (opzionale)
            BlendMode.darken,
          ),
        ),
      ),

      child: ListTile(
        title: Text(
          '${match.scoreA} - ${match.scoreB}',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          '$formattedDate\nBianchi: $playersA\nColorati: $playersB',
          style: const TextStyle(color: Colors.white70),
        ),
        isThreeLine: true,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MatchDetailScreen(match: match)),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            final data = Provider.of<DataService>(context, listen: false);
            await data.deleteMatch(match.id);
            (context as Element).markNeedsBuild();
          },
        ),
      ),
    ),
  ),
);
//----------------------------------------------------------------------------------------------
/*
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),   // angoli arrotondati
      ),
      elevation: 6, // effetto rialzato
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      
      child: ListTile(
        title: Text('${match.scoreA} - ${match.scoreB}'),
        subtitle: Text('$formattedDate\nBianchi: $playersA\nColorati: $playersB'),
        isThreeLine: true,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MatchDetailScreen(match: match)),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            final data = Provider.of<DataService>(context, listen: false);
            await data.deleteMatch(match.id);
            (context as Element).markNeedsBuild();
          },
        ),
      ),
    );*/
  }
}
