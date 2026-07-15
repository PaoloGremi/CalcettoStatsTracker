import '../../data/hive_boxes.dart';

/// Risolve il nome di un giocatore dato il suo id, leggendo direttamente
/// da Hive. Prima di questo helper la stessa risoluzione (con lo stesso
/// fallback "mostra l'id se il giocatore non esiste più") era duplicata
/// in ai_coach_page.dart, home_screen.dart, match_detail_screen.dart
/// (4 volte) e match_card.dart.
///
/// Ritorna una stringa vuota se [id] è vuoto (nessun giocatore assegnato).
/// Se il giocatore non esiste più (es. cancellato) ritorna [fallback],
/// che di default è [id] stesso — così un riferimento a un giocatore
/// cancellato resta comunque leggibile invece di sparire silenziosamente.
String resolvePlayerName(String id, {String? fallback}) {
  if (id.isEmpty) return '';
  return HiveBoxes.playersBox.get(id)?.name ?? (fallback ?? id);
}
