import 'package:get_it/get_it.dart';

import '../../features/players/data/datasources/player_local_datasource.dart';
import '../../features/players/data/repositories/player_repository_impl.dart';
import '../../features/players/domain/repositories/player_repository.dart';
import '../../features/players/domain/usecases/add_player.dart';
import '../../features/players/domain/usecases/delete_player.dart';
import '../../features/players/domain/usecases/get_all_players.dart';
import '../../features/players/domain/usecases/update_player.dart';
import '../../features/players/presentation/controllers/players_controller.dart';
import '../../services/data_service.dart';

/// Service locator per repository/usecase/servizi che devono essere
/// facilmente sostituibili nei test (es. con fake/mock).
///
/// Coesiste con [Provider]: Provider resta responsabile dello stato
/// UI reattivo (rebuild su `notifyListeners()`), get_it si occupa solo
/// del cablaggio delle dipendenze verso i layer data/domain.
final GetIt getIt = GetIt.instance;

/// Registra le dipendenze condivise. Va chiamata una sola volta, prima
/// di `runApp`, dopo l'inizializzazione di Hive.
void setupServiceLocator() {
  if (getIt.isRegistered<DataService>()) return;

  getIt.registerLazySingleton<DataService>(() => DataService());

  // ── Feature: Players ─────────────────────────────────────────
  // Factory (non singleton): ogni schermata Players ottiene la propria
  // catena di dipendenze, coerente col fatto che PlayersController è
  // stato di pagina, non stato condiviso a livello app come DataService.
  getIt.registerFactory<PlayerLocalDataSource>(() => PlayerLocalDataSource());
  getIt.registerFactory<PlayerRepository>(() => PlayerRepositoryImpl(
        localDataSource: getIt<PlayerLocalDataSource>(),
        dataService: getIt<DataService>(),
      ));
  getIt.registerFactory<GetAllPlayers>(
      () => GetAllPlayers(getIt<PlayerRepository>()));
  getIt.registerFactory<AddPlayer>(() => AddPlayer(getIt<PlayerRepository>()));
  getIt.registerFactory<UpdatePlayer>(
      () => UpdatePlayer(getIt<PlayerRepository>()));
  getIt.registerFactory<DeletePlayer>(
      () => DeletePlayer(getIt<PlayerRepository>()));
  getIt.registerFactory<PlayersController>(() => PlayersController(
        getAllPlayers: getIt<GetAllPlayers>(),
        addPlayer: getIt<AddPlayer>(),
        updatePlayer: getIt<UpdatePlayer>(),
        deletePlayer: getIt<DeletePlayer>(),
      ));
}
