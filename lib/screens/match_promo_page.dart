import 'package:calcetto_tracker/data/hive_boxes.dart';
import 'package:calcetto_tracker/data/player_icons.dart';
import 'package:flutter/material.dart';

class MatchPromoPage extends StatelessWidget {
  final String dataOra;
  final String campo;
  final String prezzo;
  final List<String> teamBlack;
  final List<String> teamWhite;
  
  

  const MatchPromoPage({
    super.key,
    required this.dataOra,
    required this.campo,
    required this.prezzo,
    required this.teamBlack,
    required this.teamWhite,
  });

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
  @override
  Widget build(BuildContext context) {

//-----------------
/*
final teamBPlayers = teamBlack
        .map((id) => HiveBoxes.playersBox.get(id)?.name ?? 'Sconosciuto')
        .toList();
    final teamWPlayers = teamWhite
        .map((id) => HiveBoxes.playersBox.get(id)?.name ?? 'Sconosciuto')
        .toList();

*/
//--------------------


    return Scaffold(
      appBar: AppBar(
      ),
      body: Column(
        children: [
          _header(),
          Expanded(
            child: Row(
              children: [
                Expanded(
                    child: _teamColumn(
                  title: "Maglia Colorata",
                  bgColor: Colors.black,
                  textColor: Colors.white,
                  players: teamBlack,
                )),
                Expanded(
                    child: _teamColumn(
                  title: "Maglia Bianca",
                  bgColor: Colors.grey.shade200,
                  textColor: Colors.black,
                  players: teamWhite,
                )),
              ],
            ),
          ),
          //_infoSection(),
        ],
      ),
    );
  }



  Widget _header() {
    return Container(
      decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(getBackgroundForLocation(campo)),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                // ignore: deprecated_member_use
                Colors.black.withOpacity(
                    0.25), // scurisce leggermente lo sfondo (opzionale)
                BlendMode.darken,
              ),
            ),
          ),
      padding: const EdgeInsets.fromLTRB(16, 25, 16, 20),
      //color: const Color.fromARGB(159, 51, 255, 102),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(dataOra,
                style:
                const TextStyle(fontSize: 18/*, fontWeight: FontWeight.w600*/)),
          ]),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.sports_soccer, size: 32),
              const SizedBox(width: 10),
              const Text("5 vs 5",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text(campo,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          Text("$prezzo € a persona", style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

Widget _teamColumn({
  required String title,
  required Color bgColor,
  required Color textColor,
  required List<String> players,   // QUI arrivano gli ID !
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    color: bgColor,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 20),

        // LISTA SCORRIBILE
        Expanded(
          child: ListView(
            children: [
              ...players.map((id) {
                final player = HiveBoxes.playersBox.get(id);

                final nome = player?.name ?? "Sconosciuto";
                final icona = player?.icon ?? "person";
                final ruolo = player?.role ?? "N/D";

                return _buildPlayerTile(nome, icona, ruolo);
              }).toList(),
            ],
          ),
        ),
      ],
    ),
  );
}
/*
  Widget _infoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey.shade800,
      child: Column(
        children: [
          _infoRow("Campo", campo),
          const SizedBox(height: 10),
          _infoRow("Tipologia", "Indoor"),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
  */

  Widget _buildPlayerTile(
      String name, String icon, String role) {
    final iconData = getPlayerIcon(icon);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: iconData.isAsset
            ? CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage(iconData.assetPath!),
              )
            : CircleAvatar(
                radius: 18,
                child: Icon(iconData.iconData, size: 24),
              ),
        title: Text('$name - $role',
        style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}
