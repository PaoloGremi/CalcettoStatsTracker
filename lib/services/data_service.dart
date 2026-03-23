import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/player.dart';
import '../models/match_model.dart';
import '../models/field_model.dart';
import '../data/hive_boxes.dart';

class DataService extends ChangeNotifier {
  final _uuid = const Uuid();

  // ── Players ───────────────────────────────────────────────────

  List<Player> getAllPlayers() => HiveBoxes.playersBox.values.toList();

  Future<Player> addPlayer(String name, String icon,
      {required String role, String? imagePath}) async {
    final player = Player(
      id: _uuid.v4(),
      name: name,
      role: role,
      icon: icon,
      imagePath: imagePath,
    );
    await HiveBoxes.playersBox.put(player.id, player);
    notifyListeners();
    return player;
  }

  Future<void> updatePlayer(Player player) async {
    await HiveBoxes.playersBox.put(player.id, player);
    notifyListeners();
  }

  Future<void> deletePlayer(String id) async {
    await HiveBoxes.playersBox.delete(id);
    for (final match in HiveBoxes.matchesBox.values) {
      match.teamA.remove(id);
      match.teamB.remove(id);
      match.votes.remove(id);
      match.goals.remove(id); // ✅ rimuovi anche i gol
      await match.save();
    }
    notifyListeners();
  }

  // ── Matches ───────────────────────────────────────────────────

  List<MatchModel> getAllMatches() {
    final list = HiveBoxes.matchesBox.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<MatchModel> addMatch(MatchModel match) async {
    await HiveBoxes.matchesBox.put(match.id, match);
    await _updateAwardCounters(match, delta: 1);
    notifyListeners();
    return match;
  }

  Future<void> updateMatch(MatchModel match) async {
    final existing = HiveBoxes.matchesBox.get(match.id);
    if (existing != null) {
      await _updateAwardCounters(existing, delta: -1);
    }
    await HiveBoxes.matchesBox.put(match.id, match);
    await _updateAwardCounters(match, delta: 1);
    notifyListeners();
  }

  Future<void> deleteMatch(String id) async {
    final match = HiveBoxes.matchesBox.get(id);
    if (match != null) {
      await _updateAwardCounters(match, delta: -1);
    }
    await HiveBoxes.matchesBox.delete(id);
    notifyListeners();
  }

  /// Aggiunge o sottrae (+1 / -1) i contatori ai giocatori coinvolti.
  Future<void> _updateAwardCounters(MatchModel match, {required int delta}) async {
    // MVP
    if (match.mvp.isNotEmpty) {
      final mvpPlayer = _findPlayerById(match.mvp);
      if (mvpPlayer != null) {
        mvpPlayer.mvpCount = (mvpPlayer.mvpCount + delta).clamp(0, 9999);
        await HiveBoxes.playersBox.put(mvpPlayer.id, mvpPlayer);
      }
    }

    // Combattivo
    if (match.hustlePlayer.isNotEmpty) {
      final hustlePlayer = _findPlayerById(match.hustlePlayer);
      if (hustlePlayer != null) {
        hustlePlayer.hustleCount = (hustlePlayer.hustleCount + delta).clamp(0, 9999);
        await HiveBoxes.playersBox.put(hustlePlayer.id, hustlePlayer);
      }
    }

    // Best Goal
    if (match.bestGoalPlayer.isNotEmpty) {
      final bestGoalPlayer = _findPlayerById(match.bestGoalPlayer);
      if (bestGoalPlayer != null) {
        bestGoalPlayer.bestGoalCount = (bestGoalPlayer.bestGoalCount + delta).clamp(0, 9999);
        await HiveBoxes.playersBox.put(bestGoalPlayer.id, bestGoalPlayer);
      }
    }

    // ✅ Gol: aggiorna totalGoals per ogni giocatore presente nella mappa goals
    for (final entry in match.goals.entries) {
      final player = _findPlayerById(entry.key);
      if (player != null) {
        player.totalGoals = (player.totalGoals + entry.value * delta).clamp(0, 99999);
        await HiveBoxes.playersBox.put(player.id, player);
      }
    }
  }

  Player? _findPlayerById(String playerId) {
    return HiveBoxes.playersBox.get(playerId);
  }

  // ── Fields ────────────────────────────────────────────────────

  List<FieldModel> getAllFields() {
    final list = HiveBoxes.fieldsBox.values.toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Future<FieldModel> addField(String name, String address, {String? imagePath}) async {
    final field = FieldModel(
      id: _uuid.v4(),
      name: name,
      address: address,
      imagePath: imagePath,
    );
    await HiveBoxes.fieldsBox.put(field.id, field);
    notifyListeners();
    return field;
  }

  Future<void> updateField(FieldModel field) async {
    await HiveBoxes.fieldsBox.put(field.id, field);
    notifyListeners();
  }

  Future<void> deleteField(String id) async {
    await HiveBoxes.fieldsBox.delete(id);
    notifyListeners();
  }
}
