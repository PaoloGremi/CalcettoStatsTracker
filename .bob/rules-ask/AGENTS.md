# Project Documentation Context (Non-Obvious Only)

- **`lib/screens/` and `lib/services/DataService` are NOT deprecated** — they are the active code for matches, fields, stats, backup, AI coach, etc. Only the Players feature has been migrated to `lib/features/players/`.
- **`DataService` is both a `ChangeNotifier` (Provider) and a get_it singleton** — the same instance is surfaced through both DI systems simultaneously.
- **`Player` (domain entity) ≠ `PlayerModel` (Hive model)** — `PlayerMapper` converts between them. Stats fields (`mvpCount`, etc.) live on `PlayerModel`/`Player` directly, not in a separate stats object.
- **`HiveBoxes.*Box` are mutable statics** — tests overwrite them directly to inject test boxes. This is the intended injection point for data-layer tests, not constructor injection of the box.
- **No routing framework** — navigation is done with `Navigator.push`/`pushReplacement` and a single named route `/home`.
- **App is Italian** — all UI strings, comments, and Dart doc comments are in Italian. Test descriptions (the string passed to `test()`/`group()`) are in English.
