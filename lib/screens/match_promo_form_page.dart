import 'package:calcetto_tracker/screens/match_promo_page.dart';
import 'package:calcetto_tracker/services/data_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MatchPromoFormPage extends StatefulWidget {
  const MatchPromoFormPage({super.key});

  @override
  State<MatchPromoFormPage> createState() => _MatchFormPageState();
}

class _MatchFormPageState extends State<MatchPromoFormPage> {
  final TextEditingController campoCtrl = TextEditingController();
  final TextEditingController prezzoCtrl = TextEditingController();
  final TextEditingController dataOraCtrl = TextEditingController();

  final Map<String, bool> selectedA = {};
  final Map<String, bool> selectedB = {};
  String? fieldLocation;
  DateTime? selectedDateTime;

  //List<String> squadraNera = [];
  //List<String> squadraBianca = [];

  @override
  Widget build(BuildContext context) {
    //recupero dati players
    final data = Provider.of<DataService>(context);
    final players = data.getAllPlayers();

    return Scaffold(
      appBar: AppBar(title: const Text("Promuovi nuova partita")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    })),
            const SizedBox(height: 16),
            SizedBox(
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
                    DropdownMenuItem(
                        value: 'Other', child: Text('Altro Campo')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      fieldLocation = val;
                    });
                  }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: prezzoCtrl,
              decoration: const InputDecoration(
                labelText: "Prezzo a persona (€)",
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 30),
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
                )),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
              ),
              onPressed: () {
                final formattedDate = DateFormat('dd/MM/yyyy HH:mm')
                    .format(selectedDateTime ?? DateTime.now());

                final teamAIds = selectedA.entries
                    .where((e) => e.value)
                    .map((e) => e.key)
                    .toList();
                final teamBIds = selectedB.entries
                    .where((e) => e.value)
                    .map((e) => e.key)
                    .toList();

                if (teamAIds.isEmpty || teamBIds.isEmpty) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MatchPromoPage(
                      dataOra: formattedDate,
                      campo: fieldLocation ?? 'other',
                      prezzo: prezzoCtrl.text,
                      teamBlack: teamAIds,
                      teamWhite: teamBIds,
                    ),
                  ),
                );
              },
              child: const Text("Genera schermata"),
            )
          ],
        ),
      ),
    );
  }
}
