part of '../player_stats_screen.dart';

/// Sezione standard di una tab: titolo, contenuto, spaziatura finale.
List<Widget> _section(String title, Color accent, Widget child) => [
      FifaSectionHeader(title, accent: accent),
      child,
      const SizedBox(height: 24),
    ];

/// Valore con segno a una cifra decimale; evita "-0.0" e "+0.0".
String formatSignedDelta(double v) {
  final s = v.toStringAsFixed(1);
  if (s == '0.0' || s == '-0.0') return '0.0';
  return v > 0 ? '+$s' : s;
}

/// Mostrato da una tab quando tutte le sue sezioni sono nascoste per
/// mancanza di dati.
class _EmptyTab extends StatelessWidget {
  const _EmptyTab();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: FifaLabel(
            'Dati insufficienti per questa categoria',
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
      );
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String? emoji;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (emoji != null) ...[
                Text(emoji!, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 1),
              ],
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: emoji != null ? 18 : 22,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              FifaLabel(label,
                  color: color.withValues(alpha: 0.6), fontSize: 8),
            ],
          ),
        ),
      );
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int total;
  const _LegendRow({
    required this.color,
    required this.label,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total * 100).round() : 0;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '$count ($pct%)',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final Widget child;
  const _ChartCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        height: 200,
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: child,
      );
}

class _ResultAvgBadge extends StatelessWidget {
  final String label;
  final double avg;
  final Color color;
  final int count;

  const _ResultAvgBadge({
    required this.label,
    required this.avg,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            avg > 0 ? avg.toStringAsFixed(1) : '—',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          FifaLabel(label, color: color.withValues(alpha: 0.7), fontSize: 8),
          const SizedBox(height: 1),
          FifaLabel('($count partite)', color: AppTheme.textMuted, fontSize: 8),
        ],
      );
}

class _ConsistStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ConsistStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        ],
      );
}
