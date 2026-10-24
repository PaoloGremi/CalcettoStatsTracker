import 'package:flutter/foundation.dart';

import '../../domain/entities/training.dart';
import '../../domain/services/training_stats.dart';
import '../../domain/usecases/delete_training.dart';
import '../../domain/usecases/get_all_trainings.dart';
import '../../domain/usecases/save_training.dart';

/// Stato delle schermate allenamenti: lista, statistiche, loading/errore.
/// Conosce solo gli usecase, quindi si testa con mock.
class TrainingsController extends ChangeNotifier {
  TrainingsController({
    required GetAllTrainings getAllTrainings,
    required SaveTraining saveTraining,
    required DeleteTraining deleteTraining,
    DateTime Function()? clock,
  })  : _getAllTrainings = getAllTrainings,
        _saveTraining = saveTraining,
        _deleteTraining = deleteTraining,
        _clock = clock ?? DateTime.now;

  final GetAllTrainings _getAllTrainings;
  final SaveTraining _saveTraining;
  final DeleteTraining _deleteTraining;
  final DateTime Function() _clock;

  /// "Oggi" secondo l'orologio iniettato (per le etichette Oggi/Ieri).
  DateTime get today => _clock();

  List<Training> _trainings = const [];

  /// Dal più recente.
  List<Training> get trainings => _trainings;

  TrainingStats? _stats;
  TrainingStats get stats => _stats ??= TrainingStats(_trainings, today: _clock());

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _getAllTrainings();
    result.fold(
      (list) {
        _trainings = List.unmodifiable(list);
        _stats = null;
      },
      (failure) => _error = failure.message,
    );
    _isLoading = false;
    notifyListeners();
  }

  /// Null se salvato (e lista ricaricata), altrimenti il messaggio d'errore
  /// da mostrare nel modulo.
  Future<String?> save(Training t) async {
    final result = await _saveTraining(t);
    final failure = result.fold((_) => null, (f) => f);
    if (failure != null) return failure.message;
    await load();
    return null;
  }

  Future<bool> remove(String id) async {
    final result = await _deleteTraining(id);
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
