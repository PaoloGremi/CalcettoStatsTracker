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

  String getBackgroundForLocation(String? location) {
    const map = {
      'SanFrancesco': 'assets/images/campoSanFrancescoColorato.jpg',
      'Montanaso': 'assets/images/montanaso.jpg',
      'Faustina': 'assets/images/faustina.png',
      'Pergola': 'assets/images/laPergola.jpg',
      'Other': 'assets/images/sfondoPalloneGenerico.png',
    };

    // fallback se null o valore non presente
    return map[location] ?? 'assets/images/sfondoPalloneGenerico.png';
  }


String getDescriptionForLocation(String? location) {
    const map = {
      'SanFrancesco': 'San Fracesco - Via Serravalle, 4, 26900 Lodi LO ',
      'Montanaso': 'McDonalds Stadium - Via G. Garibaldi, 26836 Montanaso Lombardo LO',
      'Faustina': 'Faustina sport arena - Piazzale degli Sport, 26900 Lodi LO',
      'Pergola': 'La Pergola - Via per Ca de Bolli, 11, 26817 San Martino in Strada LO',
      'Other': 'campo sportivo',
    };

    // fallback se null o valore non presente
    return map[location] ?? '';
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
      child: ClipRRect(
        // serve per applicare il borderRadius all'immagine
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(getBackgroundForLocation(match.fieldLocation)),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                // ignore: deprecated_member_use
                Colors.black.withOpacity(
                    0.25), // scurisce leggermente lo sfondo (opzionale)
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
              '$formattedDate\nBianchi: $playersA\nColorati: $playersB\n📍 ${getDescriptionForLocation(match.fieldLocation)}',
              style: const TextStyle(color: Colors.white70),
            ),
            isThreeLine: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => MatchDetailScreen(match: match)),
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
