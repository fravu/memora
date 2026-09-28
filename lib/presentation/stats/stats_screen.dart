import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/gamification/gamification_summary.dart';
import '../../application/gamification/xp_calculator.dart';
import '../../domain/entities/stats_snapshot.dart';
import '../providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(gamificationSummaryProvider);
    final historyAsync = ref.watch(statsHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: summaryAsync.when(
        data: (summary) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummaryCards(context, summary),
            const SizedBox(height: 24),
            Text('Letzte 7 Tage', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: historyAsync.when(
                data: (history) => _buildChart(history),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Fehler: $error')),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Fehler: $error')),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, GamificationSummary summary) {
    final xpIntoLevel = XpCalculator.xpIntoCurrentLevel(summary.xp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_fire_department, color: Colors.orange, size: 32),
            const SizedBox(width: 8),
            Text(
              '${summary.currentStreak} Tage Streak',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Level ${summary.level}', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: xpIntoLevel / 100),
        const SizedBox(height: 4),
        Text('$xpIntoLevel / 100 XP im aktuellen Level'),
        const SizedBox(height: 16),
        Text(
          '${summary.totalReviewed} Karten gelernt · '
          '${(summary.accuracy * 100).round()}% Erfolgsquote',
        ),
      ],
    );
  }

  Widget _buildChart(List<StatsSnapshot> history) {
    final last7 = history.length > 7 ? history.sublist(history.length - 7) : history;

    if (last7.isEmpty) {
      return const Center(child: Text('Noch keine Lern-Session absolviert.'));
    }

    final maxY = last7
        .map((s) => s.cardsReviewed)
        .fold<int>(1, (max, value) => value > max ? value : max)
        .toDouble();

    return BarChart(
      BarChartData(
        maxY: maxY * 1.2,
        barGroups: [
          for (var i = 0; i < last7.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: last7[i].cardsReviewed.toDouble(),
                  color: Colors.teal,
                ),
              ],
            ),
        ],
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= last7.length) return const SizedBox.shrink();
                final date = last7[index].date;
                return Text('${date.day}.${date.month}.');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }
}
