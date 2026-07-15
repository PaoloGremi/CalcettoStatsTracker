import 'package:calcetto_tracker/features/players/data/mappers/player_mapper.dart';
import 'package:calcetto_tracker/models/player_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = PlayerMapper();

  test('toEntity copies every field from the Hive model', () {
    final model = PlayerModel(
      id: 'p1',
      name: 'Mario',
      role: 'A',
      icon: 'star',
      imagePath: '/path.jpg',
      mvpCount: 2,
      hustleCount: 1,
      bestGoalCount: 3,
      totalGoals: 10,
    );

    final entity = mapper.toEntity(model);

    expect(entity.id, model.id);
    expect(entity.name, model.name);
    expect(entity.role, model.role);
    expect(entity.icon, model.icon);
    expect(entity.imagePath, model.imagePath);
    expect(entity.mvpCount, model.mvpCount);
    expect(entity.hustleCount, model.hustleCount);
    expect(entity.bestGoalCount, model.bestGoalCount);
    expect(entity.totalGoals, model.totalGoals);
  });

  test('toModel copies every field from the domain entity', () {
    final entity = mapper.toEntity(PlayerModel(
      id: 'p2',
      name: 'Luigi',
      role: 'D',
      icon: 'person',
      mvpCount: 5,
    ));

    final model = mapper.toModel(entity);

    expect(model.id, entity.id);
    expect(model.name, entity.name);
    expect(model.role, entity.role);
    expect(model.icon, entity.icon);
    expect(model.imagePath, entity.imagePath);
    expect(model.mvpCount, entity.mvpCount);
  });

  test('round-trip toEntity(toModel(x)) preserves all fields', () {
    final model = PlayerModel(
      id: 'p3',
      name: 'Peach',
      role: 'C',
      icon: 'crown',
      imagePath: null,
      mvpCount: 0,
      hustleCount: 4,
      bestGoalCount: 0,
      totalGoals: 7,
    );

    final roundTripped = mapper.toModel(mapper.toEntity(model));

    expect(roundTripped.id, model.id);
    expect(roundTripped.name, model.name);
    expect(roundTripped.role, model.role);
    expect(roundTripped.icon, model.icon);
    expect(roundTripped.imagePath, model.imagePath);
    expect(roundTripped.mvpCount, model.mvpCount);
    expect(roundTripped.hustleCount, model.hustleCount);
    expect(roundTripped.bestGoalCount, model.bestGoalCount);
    expect(roundTripped.totalGoals, model.totalGoals);
  });
}
