import 'package:intl/intl.dart';

/// Formattazioni data/ora italiane condivise. Prima di questo file lo
/// stesso set ristretto di pattern `DateFormat` era ripetuto (con lievi
/// variazioni di stile) in player_stats_screen.dart, edit_match_screen.dart,
/// new_match_screen.dart, match_promo_form_page.dart, match_detail_screen.dart,
/// calendar_match_screen.dart e match_card.dart.
///
/// Contiene solo i pattern realmente duplicati (2+ punti di utilizzo);
/// i pattern usati una sola volta restano inline nel loro screen.

/// Es. "05/07" — player_stats_screen (grafici andamento).
String formatShortDate(DateTime date) =>
    DateFormat('dd/MM', 'it_IT').format(date);

/// Es. "5 lug 2025" — player_stats_screen (liste risultati recenti).
String formatDayMonthYear(DateTime date) =>
    DateFormat('d MMM yyyy', 'it_IT').format(date);

/// Es. "05 luglio 2025" — match_detail_screen (giornale/copertina AI).
String formatLongDate(DateTime date) =>
    DateFormat('dd MMMM yyyy', 'it_IT').format(date);

/// Es. "lug 25" — player_stats_screen (assi grafici mensili).
String formatMonthYearShort(DateTime date) =>
    DateFormat('MMM yy', 'it_IT').format(date);

/// Es. "Luglio 2025" — player_stats_screen (intestazioni sezione mensile).
String formatMonthYearFull(DateTime date) =>
    DateFormat('MMMM yyyy', 'it_IT').format(date);

/// Es. "lun 05 lug 2025 · 21:00" — edit_match_screen, new_match_screen,
/// match_promo_form_page (selezione data/ora partita).
String formatFullDateTime(DateTime date) =>
    DateFormat('EEE dd MMM yyyy · HH:mm', 'it_IT').format(date);

/// Es. "21:00" — match_detail_screen, calendar_match_screen, match_card.
String formatTime(DateTime date) => DateFormat('HH:mm', 'it_IT').format(date);
