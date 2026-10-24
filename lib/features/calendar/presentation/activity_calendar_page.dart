import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/util/date_formatters.dart';
import '../../../models/field_model.dart';
import '../../../models/match_model.dart';
import '../../../screens/match_detail_screen.dart';
import '../../../theme/app_theme.dart';
import '../../trainings/domain/entities/training.dart';
import '../../trainings/presentation/controllers/trainings_controller.dart';
import '../../trainings/presentation/pages/training_form_page.dart';
import '../../trainings/presentation/widgets/training_list_tile.dart';
import '../domain/activity_calendar.dart';

/// Calendario di partite e allenamenti, nello stile del calendario partite
/// (anno scelto in alto, 12 mesi da scorrere in verticale): una partita mostra la foto del campo e il risultato, un
/// allenamento la tinta e l'icona del suo tipo, più voci nello stesso giorno
/// un riquadro oro col numero. In basso, fisse, le voci del giorno scelto.
class ActivityCalendarPage extends StatefulWidget {
  const ActivityCalendarPage({
    super.key,
    required this.matches,
    required this.trainings,
    this.playerId,
    this.fieldLookup,
  });

  /// Tutte le partite; con [playerId] restano solo quelle giocate da lui.
  final List<MatchModel> matches;

  /// Lo stesso controller della home: dà allenamenti e "oggi", e il modulo
  /// di modifica salva tramite lui.
  final TrainingsController trainings;
  final String? playerId;

  /// Campo dal suo id (nome e foto). Null → si mostra l'id, senza foto.
  final FieldModel? Function(String fieldId)? fieldLookup;

  @override
  State<ActivityCalendarPage> createState() => _ActivityCalendarPageState();
}

class _ActivityCalendarPageState extends State<ActivityCalendarPage> {
  late int _year;
  late DateTime _selected;
  final _scrollController = ScrollController();

  /// Chiave del mese da portare in vista dopo il prossimo frame.
  final _scrollTargetKey = GlobalKey();
  int? _scrollTargetMonth;

  DateTime get _today {
    final now = widget.trainings.today;
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _goToToday();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _goToToday() {
    final today = _today;
    _year = today.year;
    _selected = today;
    _scrollToMonth(today.month);
  }

  /// Anno scelto dal menu: in quello attuale si va a oggi, negli altri al
  /// primo gennaio (in cima).
  void _selectYear(int year) {
    if (year == _today.year) {
      _goToToday();
    } else {
      _year = year;
      _selected = DateTime(year);
      _scrollToMonth(1);
    }
  }

  /// Dopo il prossimo frame porta in vista l'intestazione di [month].
  void _scrollToMonth(int month) {
    _scrollTargetMonth = month;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _scrollTargetKey.currentContext;
      if (ctx != null && ctx.mounted) Scrollable.ensureVisible(ctx);
    });
  }

  /// Anni con almeno un'attività, più quello attuale.
  List<int> _years(ActivityCalendar cal) =>
      ({...cal.years, _today.year}.toList()..sort());

  FieldModel? _field(MatchModel m) => widget.fieldLookup?.call(m.fieldLocation);

  Future<void> _openMatch(MatchModel m) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => MatchDetailScreen(match: m)));

  Future<void> _openTraining(Training t) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<TrainingsController>.value(
            value: widget.trainings,
            child: TrainingFormPage(initial: t),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.trainings,
      builder: (context, _) {
        final cal = ActivityCalendar(
          matches: widget.matches,
          trainings: widget.trainings.trainings,
          playerId: widget.playerId,
        );
        final entries = cal.entriesOn(_selected);
        return Scaffold(
          backgroundColor: AppTheme.bg,
          appBar: AppBar(
            backgroundColor: AppTheme.bg,
            title: FifaLabel('Calendario',
                color: AppTheme.textPrimary, fontSize: 13),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppTheme.border),
            ),
            actions: [
              TextButton(
                onPressed: () => setState(_goToToday),
                child: FifaLabel('Oggi',
                    color: AppTheme.textSecondary, fontSize: 12),
              ),
              PopupMenuButton<int>(
                tooltip: 'Scegli anno',
                initialValue: _year,
                onSelected: (y) => setState(() => _selectYear(y)),
                itemBuilder: (_) => [
                  for (final y in _years(cal))
                    PopupMenuItem(value: y, child: Text('$y')),
                ],
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, right: 16),
                  child: Row(
                    children: [
                      FifaLabel('$_year',
                          color: AppTheme.accentGold, fontSize: 14),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down,
                          color: AppTheme.accentGold, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Mesi in alto da scorrere, pannello del giorno fisso in basso.
          body: LayoutBuilder(
            builder: (context, constraints) => Column(
              children: [
                Expanded(
                  // Column (non ListView.builder) così tutti i 12 mesi sono
                  // costruiti e quello cercato ha un context per
                  // Scrollable.ensureVisible.
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      children: [
                        for (var month = 1; month <= 12; month++)
                          _MonthSection(
                            key: month == _scrollTargetMonth
                                ? _scrollTargetKey
                                : ValueKey('month_$_year-$month'),
                            month: DateTime(_year, month),
                            today: _today,
                            selected: _selected,
                            calendar: cal,
                            fieldLookup: _field,
                            onSelect: (d) => setState(() => _selected = d),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: (constraints.maxHeight * 0.34).clamp(140.0, 300.0),
                  child: _DayPanel(
                    day: _selected,
                    children: [
                      for (final e in entries)
                        switch (e) {
                          MatchEntry(:final match) => _MatchRow(
                              match: match,
                              fieldName:
                                  _field(match)?.name ?? match.fieldLocation,
                              onTap: () => _openMatch(match),
                            ),
                          TrainingEntry(:final training) => _TrainingRow(
                              training: training,
                              onTap: () => _openTraining(training),
                            ),
                        },
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Colori risultato (come nel calendario partite) ──────────────────────────

Color _resultColor(MatchModel m) {
  if (m.scoreA > m.scoreB) return AppTheme.accentGreen;
  if (m.scoreB > m.scoreA) return AppTheme.accentRed;
  return AppTheme.accentGold;
}

String _resultLabel(MatchModel m) {
  if (m.scoreA > m.scoreB) return 'Vittoria Bianchi';
  if (m.scoreB > m.scoreA) return 'Vittoria Colorati';
  return 'Pareggio';
}

String _summary(({int matches, int trainings}) c) {
  final parts = [
    if (c.matches > 0) '${c.matches} ${c.matches == 1 ? 'partita' : 'partite'}',
    if (c.trainings > 0)
      '${c.trainings} ${c.trainings == 1 ? 'allenamento' : 'allenamenti'}',
  ];
  return parts.join(' · ');
}

// ─── Mese: intestazione + griglia ────────────────────────────────────────────

class _MonthSection extends StatelessWidget {
  const _MonthSection({
    super.key,
    required this.month,
    required this.today,
    required this.selected,
    required this.calendar,
    required this.fieldLookup,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime today;
  final DateTime selected;
  final ActivityCalendar calendar;
  final FieldModel? Function(MatchModel) fieldLookup;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final counts = calendar.monthCounts(month.year, month.month);
    final hasAny = counts.matches + counts.trainings > 0;
    final name = DateFormat('MMMM', 'it_IT').format(month).toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: TextStyle(
                  color: hasAny ? AppTheme.accentGold : AppTheme.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                ),
              ),
              if (hasAny) ...[
                const SizedBox(width: 8),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: AppTheme.accentGold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _summary(counts),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          _MonthGrid(
            month: month,
            today: today,
            selected: selected,
            calendar: calendar,
            fieldLookup: fieldLookup,
            onSelect: onSelect,
          ),
        ],
      ),
    );
  }
}

// ─── Griglia mensile ─────────────────────────────────────────────────────────

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.today,
    required this.selected,
    required this.calendar,
    required this.fieldLookup,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime today;
  final DateTime selected;
  final ActivityCalendar calendar;
  final FieldModel? Function(MatchModel) fieldLookup;
  final ValueChanged<DateTime> onSelect;

  static const _weekdays = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final leading = month.weekday - 1; // settimana da lunedì
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final weeks = ((leading + daysInMonth) / 7).ceil();
    return Column(
      children: [
        Row(
          children: [
            for (final w in _weekdays)
              Expanded(
                child: Center(
                  child: Text(w,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      )),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppTheme.border.withValues(alpha: 0.0),
              AppTheme.border.withValues(alpha: 0.6),
              AppTheme.border.withValues(alpha: 0.0),
            ]),
          ),
        ),
        const SizedBox(height: 4),
        for (var w = 0; w < weeks; w++)
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _cell(w * 7 + i - leading + 1, daysInMonth),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _cell(int dayNumber, int daysInMonth) {
    if (dayNumber < 1 || dayNumber > daysInMonth) return const SizedBox();
    final day = DateTime(month.year, month.month, dayNumber);
    return _DayCell(
      key: ValueKey('day_${day.year}-${_two(day.month)}-${_two(day.day)}'),
      day: dayNumber,
      entries: calendar.entriesOn(day),
      isToday: day == today,
      isSelected: day == selected,
      fieldLookup: fieldLookup,
      onTap: () => onSelect(day),
    );
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}

// ─── Cella giorno ────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  const _DayCell({
    super.key,
    required this.day,
    required this.entries,
    required this.isToday,
    required this.isSelected,
    required this.fieldLookup,
    required this.onTap,
  });

  final int day;
  final List<CalendarEntry> entries;
  final bool isToday;
  final bool isSelected;
  final FieldModel? Function(MatchModel) fieldLookup;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget content = switch (entries) {
      [] => _EmptyDay(day: day, isToday: isToday),
      [MatchEntry(:final match)] =>
        _MatchDay(day: day, match: match, field: fieldLookup(match)),
      [TrainingEntry(:final training)] =>
        _TrainingDay(day: day, training: training),
      _ => _MultiDay(day: day, entries: entries),
    };
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          content,
          if (isSelected)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.textPrimary, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.day, required this.isToday});

  final int day;
  final bool isToday;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday
                ? AppTheme.accentGold.withValues(alpha: 0.6)
                : AppTheme.border.withValues(alpha: 0.2),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: TextStyle(
            color: isToday ? AppTheme.accentGold : AppTheme.textMuted,
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w400,
          ),
        ),
      );
}

/// Partita singola: foto del campo velata, bordo e risultato colorati.
class _MatchDay extends StatelessWidget {
  const _MatchDay({required this.day, required this.match, this.field});

  final int day;
  final MatchModel match;
  final FieldModel? field;

  @override
  Widget build(BuildContext context) {
    final accent = _resultColor(match);
    final imagePath = field?.imagePath;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imagePath != null && imagePath.isNotEmpty)
            Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _FieldFallback(accent: accent),
            )
          else
            _FieldFallback(accent: accent),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.52),
                  Colors.black.withValues(alpha: 0.78),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: accent.withValues(alpha: 0.75), width: 1.5),
            ),
          ),
          _CornerDay(day: day, color: Colors.white),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${match.scoreA}-${match.scoreB}',
                style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(color: Colors.black, blurRadius: 8),
                    Shadow(color: Colors.black, blurRadius: 2),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 3,
            left: 2,
            right: 2,
            child: Text(
              formatTime(match.date),
              maxLines: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 7,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldFallback extends StatelessWidget {
  const _FieldFallback({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        color: AppTheme.surfaceAlt,
        child: Icon(Icons.sports_soccer,
            color: accent.withValues(alpha: 0.35), size: 20),
      );
}

/// Allenamento singolo: tinta e icona del tipo.
class _TrainingDay extends StatelessWidget {
  const _TrainingDay({required this.day, required this.training});

  final int day;
  final Training training;

  @override
  Widget build(BuildContext context) {
    final color = trainingTypeColor(training.type);
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _CornerDay(day: day, color: color),
          Center(
            child: FractionallySizedBox(
              widthFactor: 0.45,
              heightFactor: 0.45,
              child: FittedBox(
                child: Icon(trainingTypeIcon(training.type), color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Più voci nello stesso giorno: riquadro oro col numero e i puntini dei tipi.
class _MultiDay extends StatelessWidget {
  const _MultiDay({required this.day, required this.entries});

  final int day;
  final List<CalendarEntry> entries;

  @override
  Widget build(BuildContext context) {
    final gold = AppTheme.accentGold;
    final hasMatch = entries.any((e) => e is MatchEntry);
    final hasTraining = entries.any((e) => e is TrainingEntry);
    return Container(
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: gold.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Text('$day',
                style: TextStyle(
                    color: gold, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
          Positioned(
            top: 2,
            right: 3,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: gold, shape: BoxShape.circle),
              child: Text(
                '${entries.length}',
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 8,
                    fontWeight: FontWeight.w900),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasMatch) _Dot(AppTheme.accentGreen),
                if (hasMatch && hasTraining) const SizedBox(width: 3),
                if (hasTraining) _Dot(AppTheme.accentBlue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerDay extends StatelessWidget {
  const _CornerDay({required this.day, required this.color});

  final int day;
  final Color color;

  @override
  Widget build(BuildContext context) => Positioned(
        top: 3,
        left: 5,
        child: Text(
          '$day',
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
        ),
      );
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

// ─── Pannello del giorno, fisso in basso ─────────────────────────────────────

class _DayPanel extends StatelessWidget {
  const _DayPanel({required this.day, required this.children});

  final DateTime day;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: FifaLabel(formatDayMonthYear(day).toUpperCase(),
                color: AppTheme.textSecondary, fontSize: 11),
          ),
          Expanded(
            child: children.isEmpty
                ? Center(
                    child: Text('Nessuna attività in questo giorno',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textMuted)),
                  )
                : ListView(
                    padding: EdgeInsets.fromLTRB(
                        20, 0, 20, 8 + MediaQuery.paddingOf(context).bottom),
                    children: children,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Voci del giorno (come il foglio "più partite") ──────────────────────────

class _MatchRow extends StatelessWidget {
  const _MatchRow({
    required this.match,
    required this.fieldName,
    required this.onTap,
  });

  final MatchModel match;
  final String fieldName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _resultColor(match);
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          '${match.scoreA} : ${match.scoreB}',
          style: TextStyle(
              color: color, fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
      title: Text(
        _resultLabel(match),
        style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        [formatTime(match.date), if (fieldName.isNotEmpty) fieldName]
            .join(' · '),
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
      ),
      trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
    );
  }
}

class _TrainingRow extends StatelessWidget {
  const _TrainingRow({required this.training, required this.onTap});

  final Training training;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = trainingTypeColor(training.type);
    final details = trainingDetails(training);
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 54,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Icon(trainingTypeIcon(training.type), color: color, size: 20),
      ),
      title: Text(
        training.type.label,
        style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700),
      ),
      subtitle: details.isEmpty
          ? null
          : Text(details,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
    );
  }
}
