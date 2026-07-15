/// Categoria di errore applicativo, indipendente da UI e da dettagli tecnici
/// (Hive, http, filesystem). Usata da repository/usecase per comunicare
/// fallimenti al layer di presentazione in modo tipizzato.
sealed class Failure {
  const Failure(this.message);

  final String message;
}

/// Errore di lettura/scrittura sullo storage locale (Hive, filesystem).
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Errore di comunicazione con un servizio esterno (es. OpenAI).
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Input non valido fornito dall'utente o dal chiamante.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
