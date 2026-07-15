import 'failure.dart';

/// Esito di un'operazione che può fallire, senza eccezioni non gestite
/// che attraversano i layer. Alternativa minimale a `Either<Failure, T>`,
/// scritta a mano per non introdurre una dipendenza esterna solo per questo.
sealed class Result<T> {
  const Result();

  factory Result.success(T value) = Success<T>;
  factory Result.failure(Failure failure) = ResultFailure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is ResultFailure<T>;

  /// Applica [onSuccess] o [onFailure] a seconda dell'esito, ritornando
  /// un valore comune di tipo [R].
  R fold<R>(
      R Function(T value) onSuccess, R Function(Failure failure) onFailure) {
    final self = this;
    return switch (self) {
      Success<T>() => onSuccess(self.value),
      ResultFailure<T>() => onFailure(self.failure),
    };
  }
}

class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.failure);

  final Failure failure;
}
