import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';
import 'match_detail_screen.dart';

class CalendarMatchScreen extends StatefulWidget {
  final List<MatchModel> matches;
  const CalendarMatchScreen({required this.matches, super.key});

  @override
  State<CalendarMatchScreen> createState() => _CalendarMatchScreenState();
}

class _CalendarMatchScreenState extends State<CalendarMatchScreen> {
  late int _selectedYear;
  late Map<String, List<MatchModel>> _matchesByDay;

  @override
  void initState() {
    super.initState();
    // Default: anno dell'ultima partita, oppure anno corrente
    _selectedYear = widget.matches.isNotEmpty
        ? widget.matches
            .map((m) => m.date.year)
            .reduce((a, b) => a > b ? a : b)
        : DateTime.now().year;
    _buildIndex();
  }

  void _buildIndex() {
    _matchesByDay = {};
    for (final m in widget.matches) {
      final key = _dayKey(m.date);
      _matchesByDay.putIfAbsent(key, () => []).add(m);
    }
  }

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Anni disponibili tra le partite (per il selettore)
  List<int> get _availableYears {
    if (widget.matches.isEmpty) return [DateTime.now().year];
    final years = widget.matches.map((m) => m.date.year).toSet().toList()
      ..sort();
    return years;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: const FifaLabel('Calendario Partite',
            color: AppTheme.textPrimary, fontSize: 13),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
        actions: [
          // Selettore anno
          PopupMenuButton<int>(
            initialValue: _selectedYear,
            onSelected: (y) => setState(() => _selectedYear = y),
            itemBuilder: (_) => _availableYears
                .map((y) => PopupMenuItem(value: y, child: Text('$y')))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FifaLabel('$_selectedYear',
                      color: AppTheme.accentGold, fontSize: 14),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down,
                      color: AppTheme.accentGold, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: 12,
        itemBuilder: (_, monthIndex) {
          final month = monthIndex + 1;
          return _MonthGrid(
            year: _selectedYear,
            month: month,
            matchesByDay: _matchesByDay,
            onDayTap: (matches) => _openMatchOrList(context, matches),
          );
        },
      ),
    );
  }

  void _openMatchOrList(BuildContext context, List<MatchModel> matches) {
    if (matches.length == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MatchDetailScreen(match: matches.first),
        ),
      );
    } else {
      // Più partite nello stesso giorno → mostra un bottom sheet di scelta
      showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _MultiMatchSheet(matches: matches),
      );
    }
  }
}

// ─── Griglia mensile ─────────────────────────────────────────────────────────

class _MonthGrid extends StatelessWidget {
  final int year;
  final int month;
  final Map<String, List<MatchModel>> matchesByDay;
  final void Function(List<MatchModel>) onDayTap;

  const _MonthGrid({
    required this.year,
    required this.month,
    required this.matchesByDay,
    required this.onDayTap,
  });

  String _dayKey(int y, int m, int d) =>
      '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    // 0=Mon … 6=Sun (ISO), ma in Flutter DateTime.weekday: 1=Mon, 7=Sun
    final startOffset = (firstDay.weekday - 1) % 7; // 0 = lunedì

    final monthName =
        DateFormat('MMMM', 'it_IT').format(firstDay).toUpperCase();

    // Controlla se il mese ha almeno una partita
    bool hasAnyMatch = false;
    for (int d = 1; d <= daysInMonth; d++) {
      if (matchesByDay.containsKey(_dayKey(year, month, d))) {
        hasAnyMatch = true;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intestazione mese
          Row(
            children: [
              FifaLabel(monthName,
                  color: hasAnyMatch
                      ? AppTheme.accentGold
                      : AppTheme.textMuted,
                  fontSize: 11),
              const SizedBox(width: 8),
              if (hasAnyMatch)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentGold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Giorni della settimana
          Row(
            children: ['L', 'M', 'M', 'G', 'V', 'S', 'D']
                .map((lbl) => Expanded(
                      child: Center(
                        child: Text(lbl,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),

          // Griglia giorni
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (_, i) {
              if (i < startOffset) return const SizedBox.shrink();
              final day = i - startOffset + 1;
              final key = _dayKey(year, month, day);
              final dayMatches = matchesByDay[key];
              final hasMatch = dayMatches != null && dayMatches.isNotEmpty;

              return _DayCell(
                day: day,
                hasMatch: hasMatch,
                matchCount: dayMatches?.length ?? 0,
                onTap: hasMatch ? () => onDayTap(dayMatches!) : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Cella giorno ────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final int day;
  final bool hasMatch;
  final int matchCount;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.hasMatch,
    required this.matchCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = DateTime.now().day == day &&
        DateTime.now().month ==
            (ModalRoute.of(context)?.settings.arguments as int? ?? -1);

    final Color bg = hasMatch
        ? AppTheme.accentGreen.withOpacity(0.15)
        : Colors.transparent;
    final Color border = hasMatch
        ? AppTheme.accentGreen.withOpacity(0.5)
        : AppTheme.border.withOpacity(0.3);
    final Color textColor =
        hasMatch ? AppTheme.accentGreen : AppTheme.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: hasMatch ? 1.5 : 1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight:
                    hasMatch ? FontWeight.w800 : FontWeight.w400,
              ),
            ),
            // Badge contatore se più partite nello stesso giorno
            if (matchCount > 1)
              Positioned(
                top: 2,
                right: 3,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppTheme.accentGold,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$matchCount',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            // Pallino partita in basso
            if (hasMatch)
              Positioned(
                bottom: 3,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppTheme.accentGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom sheet selezione partita (più partite stesso giorno) ───────────────

class _MultiMatchSheet extends StatelessWidget {
  final List<MatchModel> matches;
  const _MultiMatchSheet({required this.matches});

  String _resultLabel(MatchModel m) {
    if (m.scoreA > m.scoreB) return 'Vittoria Bianchi';
    if (m.scoreB > m.scoreA) return 'Vittoria Colorati';
    return 'Pareggio';
  }

  Color _resultColor(MatchModel m) {
    if (m.scoreA > m.scoreB) return AppTheme.accentGreen;
    if (m.scoreB > m.scoreA) return AppTheme.accentRed;
    return AppTheme.accentGold;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          FifaLabel('${matches.length} PARTITE QUESTO GIORNO',
              color: AppTheme.textSecondary, fontSize: 11),
          const SizedBox(height: 12),
          ...matches.map(
            (m) => ListTile(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MatchDetailScreen(match: m),
                  ),
                );
              },
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _resultColor(m).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _resultColor(m).withOpacity(0.4)),
                ),
                child: Text(
                  '${m.scoreA} : ${m.scoreB}',
                  style: TextStyle(
                    color: _resultColor(m),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              title: Text(
                _resultLabel(m),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                DateFormat('HH:mm', 'it_IT').format(m.date),
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
