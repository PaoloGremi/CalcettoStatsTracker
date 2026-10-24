import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/util/date_formatters.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/services/training_stats.dart';
import '../training_format.dart';

/// Andamento del passo, un punto per corsa. Il passo è disegnato col segno
/// meno così un passo più veloce (meno secondi) sta più in alto.
class PaceChartCard extends StatelessWidget {
  const PaceChartCard({super.key, required this.points});

  final List<PacePoint> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 14, 16, 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text('Passo medio (min/km)',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700)),
          ),
          if (points.length < 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Text('Servono almeno 2 corse per vedere l\'andamento',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            )
          else ...[
            SizedBox(height: 180, child: _chart()),
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatShortDate(points.first.date),
                      style:
                          TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                  Text(formatShortDate(points.last.date),
                      style:
                          TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chart() {
    final ys = points.map((p) => -p.secondsPerKm);
    final minY = ys.reduce((a, b) => a < b ? a : b) - 10;
    final maxY = ys.reduce((a, b) => a > b ? a : b) + 10;
    final color = AppTheme.accentBlue;
    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppTheme.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Text(formatPace(-value),
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10));
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${formatShortDate(points[s.x.toInt()].date)}\n'
                  '${formatPace(-s.y)}/km',
                  const TextStyle(color: Colors.white, fontSize: 11),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), -points[i].secondsPerKm),
            ],
            isCurved: true,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
                show: true, color: color.withValues(alpha: 0.12)),
          ),
        ],
      ),
    );
  }
}
