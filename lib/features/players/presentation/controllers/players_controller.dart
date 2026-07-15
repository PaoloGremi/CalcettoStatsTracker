import 'package:flutter/foundation.dart';

import '../../domain/entities/player.dart';
import '../../domain/usecases/add_player.dart';
import '../../domain/usecases/delete_player.dart';
import '../../domain/usecases/get_all_players.dart';
import '../../domain/usecases/update_player.dart';

/// Stato e orchestrazione della schermata Giocatori: carica la lista,
/// espone lo stato di loading/errore, e delega le mutazioni agli usecase.
/// Non conosce Hive né `DataService` — solo la sua interfaccia verso il
/// dominio (i 4 usecase), quindi è testabile con fake/mock.
class PlayersController extends ChangeNotifier {
  PlayersController({
    required GetAllPlayers getAllPlayers,
    required AddPlayer addPlayer,
    required UpdatePlayer updatePlayer,
    required DeletePlayer deletePlayer,
  })  : _getAllPlayers = getAllPlayers,
        _addPlayer = addPlayer,
        _updatePlayer = updatePlayer,
        _deletePlayer = deletePlayer;

  final GetAllPlayers _getAllPlayers;
  final AddPlayer _addPlayer;
  final UpdatePlayer _updatePlayer;
  final DeletePlayer _deletePlayer;

  List<Player> _players = const [];
  List<Player> get players => _players;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _getAllPlayers();
    result.fold(
      (players) {
        _players = List.of(players)
          ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      },
      (failure) => _error = failure.message,
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> add({
    required String name,
    required String icon,
    required String role,
    String? imagePath,
  }) async {
    final result = await _addPlayer(
        name: name, icon: icon, role: role, imagePath: imagePath);
    final failure = result.fold((_) => null, (f) => f);
    if (failure != null) {
      _error = failure.message;
      notifyListeners();
      return false;
    }
    await load();
    return true;
  }

  Future<bool> update(Player player) async {
    final result = await _updatePlayer(player);
    final failure = result.fold((_) => null, (f) => f);
    if (failure != null) {
      _error = failure.message;
      notifyListeners();
      return false;
    }
    await load();
    return true;
  }

  Future<bool> remove(String id) async {
    final result = await _deletePlayer(id);
    final failure = result.fold((_) => null, (f) => f);
    if (failure != null) {
      _error = failure.message;
      notifyListeners();
      return false;
    }
    await load();
    return true;
  }
}
