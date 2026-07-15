import '../../../../models/player_model.dart';
import '../../domain/entities/player.dart';

/// Converte tra [PlayerModel] (persistenza Hive) e [Player] (entity di
/// dominio, immutabile e senza dipendenze da Hive).
class PlayerMapper {
  const PlayerMapper();

  Player toEntity(PlayerModel model) {
    return Player(
      id: model.id,
      name: model.name,
      role: model.role,
      icon: model.icon,
      imagePath: model.imagePath,
      mvpCount: model.mvpCount,
      hustleCount: model.hustleCount,
      bestGoalCount: model.bestGoalCount,
      totalGoals: model.totalGoals,
    );
  }

  PlayerModel toModel(Player entity) {
    return PlayerModel(
      id: entity.id,
      name: entity.name,
      role: entity.role,
      icon: entity.icon,
      imagePath: entity.imagePath,
      mvpCount: entity.mvpCount,
      hustleCount: entity.hustleCount,
      bestGoalCount: entity.bestGoalCount,
      totalGoals: entity.totalGoals,
    );
  }
}
