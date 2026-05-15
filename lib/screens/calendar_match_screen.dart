import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/match_model.dart';
import '../models/field_model.dart';
import '../data/hive_boxes.dart';
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

  List<int> get _availableYears {
    if (widget.matches.isEmpty) return [DateTime.now().year];
    return widget.matches.map((m) => m.date.year).toSet().toList()..sort();
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

// ─── Griglia mensile ──────────────────────────────────────────────────────────

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
    final startOffset = (firstDay.weekday - 1) % 7;
    final monthName =
        DateFormat('MMMM', 'it_IT').format(firstDay).toUpperCase();

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
                  color:
                      hasAnyMatch ? AppTheme.accentGold : AppTheme.textMuted,
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

          // Intestazioni giorni settimana
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
                matches: dayMatches,
                onTap: hasMatch ? () => onDayTap(dayMatches!) : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Cella giorno ─────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final int day;
  final List<MatchModel>? matches;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.matches,
    this.onTap,
  });

  bool get _hasMatch => matches != null && matches!.isNotEmpty;
  bool get _isSingle => _hasMatch && matches!.length == 1;

  Color _resultColor(MatchModel m) {
    if (m.scoreA > m.scoreB) return AppTheme.accentGreen;
    if (m.scoreB > m.scoreA) return AppTheme.accentRed;
    return AppTheme.accentGold;
  }

  @override
  Widget build(BuildContext context) {
    // ── Nessuna partita ───────────────────────────────────────────────────────
    if (!_hasMatch) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border.withOpacity(0.2)),
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    }

    // ── Più partite nello stesso giorno ───────────────────────────────────────
    if (!_isSingle) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.accentGold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppTheme.accentGold.withOpacity(0.5), width: 1.5),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '$day',
                style: const TextStyle(
                  color: AppTheme.accentGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
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
                    '${matches!.length}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Partita singola: sfondo campo + overlay info ───────────────────────────
    final match = matches!.first;
    final accent = _resultColor(match);

    // fieldLocation è l'id del campo — recuperiamo FieldModel da Hive
    final FieldModel? field = HiveBoxes.fieldsBox.get(match.fieldLocation);
    final String? imagePath = field?.imagePath;
    final String fieldName = field?.name ?? match.fieldLocation;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Sfondo: foto del campo o fallback con icona ─────────────────
            if (imagePath != null && imagePath.isNotEmpty)
              Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _FieldFallback(accent: accent),
              )
            else
              _FieldFallback(accent: accent),

            // ── Gradiente scuro per leggibilità ────────────────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.72),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bordo colorato in base al risultato ─────────────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: accent.withOpacity(0.75), width: 1.5),
                ),
              ),
            ),

            // ── Numero giorno (angolo alto-sinistra) ────────────────────────
            Positioned(
              top: 3,
              left: 5,
              child: Text(
                '$day',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
            ),

            // ── Score al centro ─────────────────────────────────────────────
            Center(
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

            // ── Orario e nome campo in basso ────────────────────────────────
            Positioned(
              bottom: 3,
              left: 3,
              right: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(match.date),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                  Text(
                    fieldName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 6,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fallback quando il campo non ha immagine salvata
class _FieldFallback extends StatelessWidget {
  final Color accent;
  const _FieldFallback({required this.accent});

  @override
  Widget build(BuildContext context) => Container(
        color: AppTheme.surfaceAlt,
        child: Icon(
          Icons.sports_soccer,
          color: accent.withOpacity(0.35),
          size: 20,
        ),
      );
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
                  border:
                      Border.all(color: _resultColor(m).withOpacity(0.4)),
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
