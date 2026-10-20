import 'package:calcetto_tracker/models/match_model.dart';
import 'package:calcetto_tracker/services/match_chronicle.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('it_IT', null);
  });

  MatchModel buildMatch() => MatchModel(
        id: 'm1',
        date: DateTime(2026, 10, 14, 21, 0),
        teamA: ['p1', 'p2'],
        teamB: ['p3', 'p4'],
        scoreA: 5,
        scoreB: 3,
        votes: {'p1': 8.5, 'p2': 6.0, 'p3': 7.0},
        comments: {'p1': 'Ovunque in campo', 'p3': 'Muro difensivo'},
        fieldLocation: 'f1',
        mvp: 'p1',
        hustlePlayer: 'p3',
        bestGoalPlayer: 'p2',
        goals: {'p1': 3, 'p2': 1, 'p3': 2},
      );

  const players = {
    'p1': ChroniclePlayer(
        name: 'Marco', role: 'ATT', careerGoals: 40, careerMvp: 7),
    'p2': ChroniclePlayer(name: 'Luca', role: 'CEN'),
    'p3': ChroniclePlayer(name: 'Giulia', role: 'DIF'),
    'p4': ChroniclePlayer(name: 'Anna', role: 'POR'),
  };

  group('buildChroniclePrompt', () {
    test('includes match data, field and every player with all their info',
        () {
      final prompt = buildChroniclePrompt(buildMatch(),
          players: players, fieldName: 'Centro Sportivo Rossi');

      expect(prompt, contains('Bianchi 5 – 3 Colorati'));
      expect(prompt, contains('Vittoria Bianchi'));
      expect(prompt, contains('Campo: Centro Sportivo Rossi'));
      expect(prompt, contains('14 ottobre 2026 · 21:00'));
      expect(prompt, contains('Gol attribuiti ai singoli: Bianchi 4, Colorati 2'));

      expect(
          prompt,
          contains('id:"p1" nome:"Marco" ruolo:"ATT" [MVP] voto:8.5 gol:3 '
              'commento_originale:"Ovunque in campo" '
              'carriera:{gol_totali:40, mvp_totali:7}'));
      expect(prompt, contains('id:"p2" nome:"Luca" ruolo:"CEN" [BEST GOAL]'));
      expect(prompt, contains('id:"p3" nome:"Giulia" ruolo:"DIF" [COMBATTIVO]'));
      expect(prompt, contains('id:"p4" nome:"Anna" ruolo:"POR" voto:N/D gol:0'));
    });

    test('puts each player under the right team', () {
      final prompt = buildChroniclePrompt(buildMatch(),
          players: players, fieldName: '');
      final bianchi = prompt.indexOf('SQUADRA BIANCHI:');
      final colorati = prompt.indexOf('SQUADRA COLORATI:');

      expect(prompt.indexOf('id:"p1"'), inInclusiveRange(bianchi, colorati));
      expect(prompt.indexOf('id:"p2"'), inInclusiveRange(bianchi, colorati));
      expect(prompt.indexOf('id:"p3"'), greaterThan(colorati));
      expect(prompt.indexOf('id:"p4"'), greaterThan(colorati));
    });

    test('marks a missing field and falls back to the id for unknown players',
        () {
      final prompt = buildChroniclePrompt(buildMatch(),
          players: const {}, fieldName: '');

      expect(prompt, contains('Campo: non indicato'));
      expect(prompt, contains('id:"p4" nome:"p4" voto:N/D'));
    });

    test('contains the anti-hallucination rules and asks for JSON', () {
      final prompt = buildChroniclePrompt(buildMatch(),
          players: players, fieldName: '');

      expect(prompt, contains('Usa SOLO i fatti presenti nei dati'));
      expect(prompt, contains('JSON'));
    });
  });

  group('parseChronicleResponse', () {
    const nameById = {'p1': 'Marco', 'p2': 'Luca'};

    test('parses a valid response and uppercases the headline', () {
      final result = parseChronicleResponse(
        '{"headline":"Marco show","subheadline":"Sub","articleBody":"Body",'
        '"pagelle":{"p1":"Immenso","p2":"Ordinato"}}',
        nameById: nameById,
      );

      expect(result.headline, 'MARCO SHOW');
      expect(result.subheadline, 'Sub');
      expect(result.articleBody, 'Body');
      expect(result.pagelle, {'p1': 'Immenso', 'p2': 'Ordinato'});
    });

    test('strips markdown code fences', () {
      final result = parseChronicleResponse(
        '```json\n{"headline":"Titolo"}\n```',
        nameById: nameById,
      );

      expect(result.headline, 'TITOLO');
      expect(result.pagelle, isEmpty);
    });

    test('maps pagelle keyed by player name back to the id', () {
      final result = parseChronicleResponse(
        '{"headline":"T","pagelle":{"marco":"Immenso","Sconosciuto":"x",'
        '"p2":""}}',
        nameById: nameById,
      );

      expect(result.pagelle, {'p1': 'Immenso'});
    });

    test('throws FormatException on truncated JSON', () {
      expect(
        () => parseChronicleResponse('{"headline":"T","articleBody":"Una',
            nameById: nameById),
        throwsFormatException,
      );
    });

    test('throws FormatException when the headline is missing', () {
      expect(
        () => parseChronicleResponse('{"articleBody":"x"}', nameById: nameById),
        throwsFormatException,
      );
    });

    test('throws FormatException when the JSON is not an object', () {
      expect(
        () => parseChronicleResponse('["a"]', nameById: nameById),
        throwsFormatException,
      );
    });
  });
}
