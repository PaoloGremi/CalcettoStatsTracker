/// Ritorna `true` se [name] contiene [query], ignorando maiuscole, spazi
/// ai bordi e accenti (così "nicolo" trova "Nicolò"). Una query vuota
/// corrisponde a tutti i giocatori.
///
/// Usata dalle barre di ricerca di Rosa e Statistiche, così il criterio di
/// ricerca è lo stesso in entrambe le schermate.
bool matchesPlayerQuery(String name, String query) {
  final q = _normalize(query.trim());
  if (q.isEmpty) return true;
  return _normalize(name).contains(q);
}

const _accents = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ä': 'a',
  'ã': 'a',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'ö': 'o',
  'õ': 'o',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ñ': 'n',
  'ç': 'c',
};

String _normalize(String s) {
  final lower = s.toLowerCase();
  final buf = StringBuffer();
  for (final ch in lower.split('')) {
    buf.write(_accents[ch] ?? ch);
  }
  return buf.toString();
}
