import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../data/hive_boxes.dart';
import '../models/match_model.dart';
import '../models/player.dart';

class CsvService {
  final _uuid = const Uuid();
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────

  Future<Directory> get _exportDir async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/exports');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String _toCsv(List<List<dynamic>> rows) =>
      const ListToCsvConverter(
        fieldDelimiter: ',',
        textDelimiter: '"',
        textEndDelimiter: '"',
        eol: '\n',
      ).convert(rows);

  List<List<dynamic>> _fromCsv(String raw) {
    // Normalizza i fine riga (Windows \r\n → \n, vecchio Mac \r → \n)
    final normalized = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    return const CsvToListConverter(
      fieldDelimiter: ',',
      textDelimiter: '"',
      textEndDelimiter: '"',
      eol: '\n',
      shouldParseNumbers: false, // legge tutto come stringa, evitiamo cast errati
    ).convert(normalized);
  }

  Future<File> _writeFile(String filename, String content) async {
    final dir = await _exportDir;
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content, flush: true);
    return file;
  }

  // ─────────────────────────────────────────────────────────────
  // HELPER — cerca un Player per UUID (campo id), non per chiave Hive.
  // Necessario perché Player estende HiveObject e la chiave Hive
  // è un indice numerico autogenerato, non l'UUID del campo id.
  // ─────────────────────────────────────────────────────────────

  Player? _playerById(String id) =>
      HiveBoxes.playersBox.values.where((p) => p.id == id).firstOrNull;

  // ─────────────────────────────────────────────────────────────
  // EXPORT — GIOCATORI
  // ─────────────────────────────────────────────────────────────

  Future<File> exportPlayers() async {
    final players = HiveBoxes.playersBox.values.toList();
    final rows = <List<dynamic>>[
      ['id', 'name', 'role', 'icon', 'imagePath'],
      ...players.map((p) => [
            p.id,
            p.name,
            p.role,
            p.icon,
            p.imagePath ?? '',
          ]),
    ];
    return _writeFile('players.csv', _toCsv(rows));
  }

  // ─────────────────────────────────────────────────────────────
  // EXPORT — PARTITE
  // ─────────────────────────────────────────────────────────────

  Future<File> exportMatches() async {
    final matches = HiveBoxes.matchesBox.values.toList();
    final rows = <List<dynamic>>[
      ['id', 'date', 'fieldLocation', 'scoreA', 'scoreB', 'teamA', 'teamB', 'mvp', 'hustlePlayer', 'bestGoalPlayer'],
      ...matches.map((m) => [
            m.id,
            _dateFormat.format(m.date),
            m.fieldLocation,
            m.scoreA,
            m.scoreB,
            m.teamA.join('|'),   // lista ID separati da pipe
            m.teamB.join('|'),
            m.mvp,
            m.hustlePlayer,
            m.bestGoalPlayer,
          ]),
    ];
    return _writeFile('matches.csv', _toCsv(rows));
  }

  // ─────────────────────────────────────────────────────────────
  // EXPORT — VOTI E COMMENTI
  // ─────────────────────────────────────────────────────────────

  Future<File> exportVotes() async {
    final matches = HiveBoxes.matchesBox.values.toList();
    final rows = <List<dynamic>>[
      ['matchId', 'matchDate', 'playerId', 'playerName', 'vote', 'comment'],
    ];

    for (final m in matches) {
      final allPlayerIds = {...m.teamA, ...m.teamB};
      for (final pid in allPlayerIds) {
        // FIX: usa _playerById per cercare per UUID, non per chiave Hive
        final player = _playerById(pid);
        final playerName = player?.name ?? 'Sconosciuto';
        final vote = m.votes[pid] ?? '';
        final comment = m.comments[pid] ?? '';
        rows.add([
          m.id,
          _dateFormat.format(m.date),
          pid,
          playerName,
          vote,
          comment,
        ]);
      }
    }
    return _writeFile('votes_comments.csv', _toCsv(rows));
  }

  // ─────────────────────────────────────────────────────────────
  // EXPORT — STATISTICHE AGGREGATE
  // ─────────────────────────────────────────────────────────────

  Future<File> exportStats() async {
    final players = HiveBoxes.playersBox.values.toList();
    final matches = HiveBoxes.matchesBox.values.toList();

    players.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final rows = <List<dynamic>>[
      ['playerId', 'playerName', 'role', 'gamesPlayed', 'votesReceived', 'avgVote', 'bestVote', 'worstVote'],
    ];

    for (final player in players) {
      int gamesPlayed = 0;
      double totalVotes = 0;
      int votesCount = 0;
      double bestVote = 0;
      double worstVote = 10;

      for (final match in matches) {
        if (match.teamA.contains(player.id) || match.teamB.contains(player.id)) {
          gamesPlayed++;
          if (match.votes.containsKey(player.id)) {
            final v = match.votes[player.id]!;
            totalVotes += v;
            votesCount++;
            if (v > bestVote) bestVote = v;
            if (v < worstVote) worstVote = v;
          }
        }
      }

      final avgVote = votesCount > 0 ? totalVotes / votesCount : 0.0;

      rows.add([
        player.id,
        player.name,
        player.role,
        gamesPlayed,
        votesCount,
        avgVote.toStringAsFixed(2),
        votesCount > 0 ? bestVote.toStringAsFixed(1) : '',
        votesCount > 0 ? worstVote.toStringAsFixed(1) : '',
      ]);
    }

    return _writeFile('stats.csv', _toCsv(rows));
  }

  // ─────────────────────────────────────────────────────────────
  // EXPORT COMPLETO — tutti e 4 i file + condivisione
  // ─────────────────────────────────────────────────────────────

  Future<void> exportAll() async {
    final playersFile = await exportPlayers();
    final matchesFile = await exportMatches();
    final votesFile = await exportVotes();
    final statsFile = await exportStats();

    await Share.shareXFiles(
      [
        XFile(playersFile.path),
        XFile(matchesFile.path),
        XFile(votesFile.path),
        XFile(statsFile.path),
      ],
      subject: 'Calcetto Tracker — Backup dati ${DateFormat('dd-MM-yyyy').format(DateTime.now())}',
    );
  }

  // ─────────────────────────────────────────────────────────────
  // IMPORT — GIOCATORI
  // ─────────────────────────────────────────────────────────────

  Future<ImportResult> importPlayers() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      dialogTitle: 'Seleziona players.csv',
    );
    if (result == null || result.files.single.path == null) {
      return ImportResult.cancelled();
    }

    final raw = await File(result.files.single.path!).readAsString();
    final rows = _fromCsv(raw);
    if (rows.length < 2) return ImportResult.error('File vuoto o non valido');

    int imported = 0;
    int skipped = 0;

    // Riga 0 = header, salta
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 4) { skipped++; continue; }

      try {
        final id = row[0].toString().trim();
        final name = row[1].toString().trim();
        final role = row[2].toString().trim();
        final icon = row[3].toString().trim();
        final imagePath = row.length > 4 ? row[4].toString().trim() : '';

        if (name.isEmpty) { skipped++; continue; }

        // FIX: cerca per UUID nel campo id, non con get() che usa la chiave Hive
        // numerica autogenerata. HiveObject non usa l'id come chiave Hive.
        final existing = _playerById(id);

        if (existing != null) {
          // Aggiorna in-place usando save() che conosce la chiave Hive reale
          existing.id = id;
          existing.name = name;
          existing.role = role;
          existing.icon = icon.isEmpty ? 'person' : icon;
          existing.imagePath = imagePath.isEmpty ? null : imagePath;
          // I contatori (mvpCount, hustleCount, bestGoalCount) vengono preservati
          await existing.save();
        } else {
          // Nuovo giocatore: add() lascia a Hive la gestione della chiave numerica
          final player = Player(
            id: id,
            name: name,
            role: role,
            icon: icon.isEmpty ? 'person' : icon,
            imagePath: imagePath.isEmpty ? null : imagePath,
            mvpCount: 0,
            hustleCount: 0,
            bestGoalCount: 0,
          );
          await HiveBoxes.playersBox.add(player);
        }
        imported++;
      } catch (_) {
        skipped++;
      }
    }

    return ImportResult.success(imported: imported, skipped: skipped);
  }

  // ─────────────────────────────────────────────────────────────
  // IMPORT — PARTITE
  // ─────────────────────────────────────────────────────────────

  Future<ImportResult> importMatches() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      dialogTitle: 'Seleziona matches.csv',
    );
    if (result == null || result.files.single.path == null) {
      return ImportResult.cancelled();
    }

    final raw = await File(result.files.single.path!).readAsString();
    final rows = _fromCsv(raw);
    if (rows.length < 2) return ImportResult.error('File vuoto o non valido');

    int imported = 0;
    int skipped = 0;

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 7) { skipped++; continue; }

      try {
        final id = row[0].toString().trim();
        final dateStr = row[1].toString().trim();
        final fieldLocation = row[2].toString().trim();
        final scoreA = int.tryParse(row[3].toString()) ?? 0;
        final scoreB = int.tryParse(row[4].toString()) ?? 0;
        final teamA = row[5].toString().split('|').where((s) => s.isNotEmpty).toList();
        final teamB = row[6].toString().split('|').where((s) => s.isNotEmpty).toList();
        final mvp = row.length > 7 ? row[7].toString().trim() : '';
        final hustlePlayer = row.length > 8 ? row[8].toString().trim() : '';
        final bestGoalPlayer = row.length > 9 ? row[9].toString().trim() : '';

        DateTime date;
        try {
          date = _dateFormat.parse(dateStr);
        } catch (_) {
          date = DateTime.now();
        }

        final match = MatchModel(
          id: id.isEmpty ? _uuid.v4() : id,
          date: date,
          teamA: teamA,
          teamB: teamB,
          scoreA: scoreA,
          scoreB: scoreB,
          fieldLocation: fieldLocation.isEmpty ? 'Other' : fieldLocation,
          mvp: mvp,
          hustlePlayer: hustlePlayer,
          bestGoalPlayer: bestGoalPlayer,
        );

        // Importa voti dal box già esistente se la partita c'era
        final existing = HiveBoxes.matchesBox.get(match.id);
        if (existing != null) {
          match.votes = existing.votes;
          match.comments = existing.comments;
        }

        await HiveBoxes.matchesBox.put(match.id, match);
        imported++;
      } catch (_) {
        skipped++;
      }
    }

    // ✅ Ricalcola mvpCount e hustleCount per tutti i giocatori
    // partendo dai match appena importati (fonte di verità)
    await _recalculateAwardCounters();

    return ImportResult.success(imported: imported, skipped: skipped);
  }

  // ─────────────────────────────────────────────────────────────
  // IMPORT — VOTI E COMMENTI
  // ─────────────────────────────────────────────────────────────

  Future<ImportResult> importVotes() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      dialogTitle: 'Seleziona votes_comments.csv',
    );
    if (result == null || result.files.single.path == null) {
      return ImportResult.cancelled();
    }

    final raw = await File(result.files.single.path!).readAsString();
    final rows = _fromCsv(raw);
    if (rows.length < 2) return ImportResult.error('File vuoto o non valido');

    int imported = 0;
    int skipped = 0;

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 5) { skipped++; continue; }

      try {
        final matchId = row[0].toString().trim();
        final playerId = row[2].toString().trim();
        final voteStr = row[4].toString().trim();
        final comment = row.length > 5 ? row[5].toString().trim() : '';

        final match = HiveBoxes.matchesBox.get(matchId);
        if (match == null) { skipped++; continue; }

        final vote = double.tryParse(voteStr);
        if (vote != null) match.votes[playerId] = vote;
        if (comment.isNotEmpty) match.comments[playerId] = comment;

        await match.save();
        imported++;
      } catch (_) {
        skipped++;
      }
    }

    return ImportResult.success(imported: imported, skipped: skipped);
  }

  // ─────────────────────────────────────────────────────────────
  // RICALCOLO CONTATORI AWARD
  // Conta MVP e Combattivo da zero leggendo tutti i match in Hive.
  // Chiamato dopo ogni import matches per garantire coerenza.
  // ─────────────────────────────────────────────────────────────

  Future<void> _recalculateAwardCounters() async {
    // Azzera tutti i contatori usando save() per rispettare la chiave Hive
    for (final player in HiveBoxes.playersBox.values) {
      player.mvpCount = 0;
      player.hustleCount = 0;
      player.bestGoalCount = 0;
      await player.save();
    }

    // FIX: usa _playerById per cercare per UUID, non get() con chiave Hive
    for (final match in HiveBoxes.matchesBox.values) {
      if (match.mvp.isNotEmpty) {
        final p = _playerById(match.mvp);
        if (p != null) {
          p.mvpCount = (p.mvpCount + 1).clamp(0, 9999);
          await p.save();
        }
      }
      if (match.hustlePlayer.isNotEmpty) {
        final p = _playerById(match.hustlePlayer);
        if (p != null) {
          p.hustleCount = (p.hustleCount + 1).clamp(0, 9999);
          await p.save();
        }
      }
      if (match.bestGoalPlayer.isNotEmpty) {
        final p = _playerById(match.bestGoalPlayer);
        if (p != null) {
          p.bestGoalCount = (p.bestGoalCount + 1).clamp(0, 9999);
          await p.save();
        }
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Risultato operazione import
// ─────────────────────────────────────────────────────────────

class ImportResult {
  final bool success;
  final bool cancelled;
  final String? errorMessage;
  final int imported;
  final int skipped;

  const ImportResult._({
    required this.success,
    required this.cancelled,
    this.errorMessage,
    this.imported = 0,
    this.skipped = 0,
  });

  factory ImportResult.success({required int imported, required int skipped}) =>
      ImportResult._(success: true, cancelled: false, imported: imported, skipped: skipped);

  factory ImportResult.cancelled() =>
      ImportResult._(success: false, cancelled: true);

  factory ImportResult.error(String message) =>
      ImportResult._(success: false, cancelled: false, errorMessage: message);
}
