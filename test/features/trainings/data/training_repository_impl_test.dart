import 'dart:io';

import 'package:calcetto_tracker/core/error/failure.dart';
import 'package:calcetto_tracker/features/trainings/data/datasources/training_local_datasource.dart';
import 'package:calcetto_tracker/features/trainings/data/models/training_model.dart';
import 'package:calcetto_tracker/features/trainings/data/repositories/training_repository_impl.dart';
import 'package:calcetto_tracker/features/trainings/domain/entities/training.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

Training _t(String id, DateTime date) => Training(
      id: id,
      date: date,
      type: TrainingType.running,
      distanceKm: 5,
      runSeconds: 1500,
    );

void main() {
  late Directory tempDir;
  late Box<TrainingModel> box;
  late TrainingRepositoryImpl repository;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('training_repository_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TrainingModelAdapter());
    }
    box = await Hive.openBox<TrainingModel>('trainingsBox');
    repository = TrainingRepositoryImpl(
        localDataSource: TrainingLocalDataSource(box: box));
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  List<Training> all(result) =>
      result.fold((List<Training> v) => v, (_) => throw 'failure');

  test('empty box returns empty list', () async {
    expect(all(await repository.getAllTrainings()), isEmpty);
  });

  test('save then getAll returns it', () async {
    final result = await repository.saveTraining(_t('a', DateTime(2026, 10, 1)));

    expect(result.isSuccess, isTrue);
    final list = all(await repository.getAllTrainings());
    expect(list.single.id, 'a');
    expect(list.single.distanceKm, 5);
  });

  test('saving the same id updates instead of duplicating', () async {
    await repository.saveTraining(_t('a', DateTime(2026, 10, 1)));
    await repository
        .saveTraining(_t('a', DateTime(2026, 10, 1)).copyWith(distanceKm: 8));

    final list = all(await repository.getAllTrainings());
    expect(list, hasLength(1));
    expect(list.single.distanceKm, 8);
  });

  test('getAll is sorted newest first', () async {
    await repository.saveTraining(_t('old', DateTime(2026, 9, 1)));
    await repository.saveTraining(_t('new', DateTime(2026, 10, 1)));
    await repository.saveTraining(_t('mid', DateTime(2026, 9, 15)));

    expect(all(await repository.getAllTrainings()).map((t) => t.id),
        ['new', 'mid', 'old']);
  });

  test('delete removes it', () async {
    await repository.saveTraining(_t('a', DateTime(2026, 10, 1)));

    final result = await repository.deleteTraining('a');

    expect(result.isSuccess, isTrue);
    expect(all(await repository.getAllTrainings()), isEmpty);
  });

  test('closed box returns CacheFailure', () async {
    await box.close();

    final result = await repository.saveTraining(_t('a', DateTime(2026, 10, 1)));

    expect(result.fold((_) => null, (f) => f), isA<CacheFailure>());
  });
}
