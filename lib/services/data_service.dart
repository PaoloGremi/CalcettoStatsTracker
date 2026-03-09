import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/player.dart';
import '../models/match_model.dart';
import '../data/hive_boxes.dart';

class DataService extends ChangeNotifier {
  final _uuid = const Uuid();

  // Players
  List<Player> getAllPlayers() => HiveBoxes.playersBox.values.toList();

  Future<Player> addPlayer(
    String name,
    String icon, {
    required String role,
    String? imagePath, // ✅ nuovo parametro opzionale
  }) async {
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
    // Rimuovi giocatore dalle partite
    for (final match in HiveBoxes.matchesBox.values) {
      match.teamA.remove(id);
      match.teamB.remove(id);
      match.votes.remove(id);
      await match.save();
    }
    notifyListeners();
  }

  // Matches
  List<MatchModel> getAllMatches() {
    final list = HiveBoxes.matchesBox.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<MatchModel> addMatch(MatchModel match) async {
    await HiveBoxes.matchesBox.put(match.id, match);
    notifyListeners();
    return match;
  }

  Future<void> updateMatch(MatchModel match) async {
    await HiveBoxes.matchesBox.put(match.id, match);
    notifyListeners();
  }

  Future<void> deleteMatch(String id) async {
    await HiveBoxes.matchesBox.delete(id);
    notifyListeners();
  }
}
