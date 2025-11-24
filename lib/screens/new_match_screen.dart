import 'package:calcetto_tracker/screens/vote_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/match_model.dart';
import '../services/data_service.dart';
import 'package:uuid/uuid.dart';

class NewMatchScreen extends StatefulWidget {
  const NewMatchScreen({super.key});

  @override
  State<NewMatchScreen> createState() => _NewMatchScreenState();
}

class _NewMatchScreenState extends State<NewMatchScreen> {
  final Map<String, bool> selectedA = {};
  final Map<String, bool> selectedB = {};
  int scoreA = 0;
  int scoreB = 0;
  String? fieldLocation;
  DateTime? selectedDateTime;

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataService>(context);
    final players = data.getAllPlayers();

    return Scaffold(
      appBar: AppBar(title: const Text('Nuova Partita')),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          const Text('Squadra Bianca',
              style: TextStyle(fontWeight: FontWeight.bold)),
          ...players.map((p) => CheckboxListTile(
                title: Text(p.name),
                value: selectedA[p.id] ?? false,
                onChanged: (v) {
                  setState(() {
                    selectedA[p.id] = v!;
                    if (v && (selectedB[p.id] ?? false))
                      selectedB[p.id] = false;
                  });
                },
              )),
          const SizedBox(height: 10),
          const Text('Squadra Colorata',
              style: TextStyle(fontWeight: FontWeight.bold)),
          ...players.map((p) => CheckboxListTile(
                title: Text(p.name),
                value: selectedB[p.id] ?? false,
                onChanged: (v) {
                  setState(() {
                    selectedB[p.id] = v!;
                    if (v && (selectedA[p.id] ?? false))
                      selectedA[p.id] = false;
                  });
                },
              )
              ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            width: 100,
            child: DropdownButtonFormField<String>(
                initialValue: fieldLocation,
                decoration: const InputDecoration(labelText: 'Location'),
                items: const [
                  DropdownMenuItem(
                      value: 'SanFrancesco',
                      child: Text('San Francesco - Lodi')),
                  DropdownMenuItem(
                      value: 'Montanaso',
                      child: Text('Campo Sportivo - Montanaso')),
                  DropdownMenuItem(
                      value: 'Faustina', child: Text('Faustina - Lodi')),
                  DropdownMenuItem(
                      value: 'Pergola',
                      child: Text('La Pergola - San Martino in Strada')),
                  DropdownMenuItem(value: 'Other', child: Text('Altro Campo')),
                ],
                onChanged: (val) {
                  setState(() {
                    fieldLocation = val;
                  });
                }),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('Data e Ora'),
                  SizedBox(
                      width: 150,
                      child: ElevatedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            selectedDateTime != null
                                ? DateFormat('dd/MM/yyyy HH:mm')
                                    .format(selectedDateTime!)
                                : 'Seleziona data e ora',
                          ),
                          onPressed: () async {
                            // 1️⃣ Seleziona la data
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );

                            if (pickedDate == null) return;

                            // 2️⃣ Seleziona l’ora
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );

                            if (pickedTime == null) return;

                            // 3️⃣ Combina data e ora in un solo DateTime
                            final combined = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );

                            // 4️⃣ Aggiorna lo stato
                            setState(() {
                              selectedDateTime = combined;
                            });
                          }))
                ],
              ),
              Column(children: [
                const Text('Punteggio Bianchi'),
                SizedBox(
                  width: 60,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (v) => scoreA = int.tryParse(v) ?? 0,
                    decoration: const InputDecoration(hintText: '0'),
                  ),
                ),
              ]),
              Column(children: [
                const Text('Punteggio Colorati'),
                SizedBox(
                  width: 60,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (v) => scoreB = int.tryParse(v) ?? 0,
                    decoration: const InputDecoration(hintText: '0'),
                  ),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final teamAIds = selectedA.entries
                  .where((e) => e.value)
                  .map((e) => e.key)
                  .toList();
              final teamBIds = selectedB.entries
                  .where((e) => e.value)
                  .map((e) => e.key)
                  .toList();

              if (teamAIds.isEmpty || teamBIds.isEmpty) return;

              final match = MatchModel(
                id: const Uuid().v4(),
                date: selectedDateTime ?? DateTime.now(),
                teamA: teamAIds,
                teamB: teamBIds,
                scoreA: scoreA,
                scoreB: scoreB,
                fieldLocation: fieldLocation ?? 'other',
              );

              await data.addMatch(match);

              // Apri la pagina dei voti subito dopo
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => VoteScreen(match: match)),
              ).then((_) => Navigator.pop(context)); // torna alla home dopo
            },
            child: const Text('Salva Partita e Vota Giocatori'),
          ),
        ],
      ),
    );
  }
}
