// lib/pages/budget/budget_summary_page.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../models/budget_period.dart';
import '../../../models/budget_item.dart';
import '../../../models/budget_category.dart';

class MainBudgetPage extends StatelessWidget {
  final BudgetPeriod period;
  const MainBudgetPage({super.key, required this.period});

  @override
  Widget build(BuildContext context) {
    final catBox = Hive.box<BudgetCategory>('categories');
    final amtFmt = NumberFormat('#,##0', 'ko');

    /*──── 데이터 준비 ────*/
    final totalSpent = period.items.fold<int>(0, (s, i) => s + i.spentAmount);
    final sections = <PieChartSectionData>[];

    for (final item in period.items) {
      final spent = item.spentAmount;
      if (spent == 0) continue;                 // 0원은 차트에서 제외
      final cat   = catBox.get(item.categoryId);
      final color = Color(cat?.colorValue ?? 0xFFCCCCCC);
      final pct   = totalSpent == 0 ? 0.0 : spent / totalSpent * 100;
      sections.add(PieChartSectionData(
        value: spent.toDouble(),
        color: color,
        radius: 50,
        showTitle: false,
        badgeWidget: const SizedBox.shrink(),
      ));
    }
    /*──── 위젯 ────*/
    return Scaffold(
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemCount: period.items.length + 2,          // 도넛 + SizedBox + 항목들
        separatorBuilder: (_, __) => const SizedBox(height: 10), // ← 간격 조절
        itemBuilder: (ctx, index) {
          // 0 : 도넛 차트, 1 : SizedBox, 2~ : BudgetItem
          if (index == 0) {
            return sections.isEmpty
                ? const SizedBox.shrink()
                : SizedBox(
              height: 240,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 50,
                  sectionsSpace: 3,
                ),
              ),
            );
          }
          if (index == 1) return const SizedBox.shrink();

          final item   = period.items[index - 2];
          final cat    = catBox.get(item.categoryId);
          final spent  = item.spentAmount;
          final limit  = item.limitAmount;
          final remain = limit - spent;
          final pct    = totalSpent == 0
              ? '0'
              : (spent / totalSpent * 100).toStringAsFixed(1);

          return ListTile(
            contentPadding: EdgeInsets.zero,
            horizontalTitleGap: 0,
            leading: CircleAvatar(
              radius: 6,
              backgroundColor: Color(cat?.colorValue ?? 0xFFCCCCCC),
            ),
            title: Row(
              children: [
                Text(cat?.name ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$pct%',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${amtFmt.format(spent)}원',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('예산 ${amtFmt.format(remain)}원 남음',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey)),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
            onTap: () => {
              print("ㅎㅇ")
            },
          );
        },
      ),
    );

  }
}

