// lib/components/top_summary.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../models/consumption.dart';

/// 주어진 [range] 에 해당하는 수입·지출·합계를 계산해서
/// 가로로 3컬럼으로 보여주는 위젯입니다.
class TopSummary extends StatelessWidget {
  /// 집계할 날짜 범위
  final DateTimeRange range;

  const TopSummary({Key? key, required this.range}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(fontWeight: FontWeight.bold);
    final valueStyle = Theme.of(context)
        .textTheme
        .bodyLarge
        ?.copyWith(fontWeight: FontWeight.bold);

    final nf = NumberFormat('#,##0', 'ko');

    return ValueListenableBuilder<Box<Consumption>>(
      valueListenable: Hive.box<Consumption>('consumptions').listenable(),
      builder: (context, box, _) {
        final all = box.values.where((c) =>
        !c.date.isBefore(range.start) && !c.date.isAfter(range.end));

        final income = all
            .where((c) => c.type == '수입')
            .fold<int>(0, (sum, c) => sum + (c.amount ?? 0));

        final expense = all
            .where((c) => c.type != '수입')
            .fold<int>(0, (sum, c) => sum + (c.amount ?? 0));

        final net     = income - expense;
        final netSign = net >= 0 ? '+' : '-';
        final netAbs  = nf.format(net.abs());

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 수입
              Column(
                children: [
                  Text('수입', style: labelStyle),
                  const SizedBox(height: 4),
                  Text('+${nf.format(income)}원',
                      style: valueStyle?.copyWith(color: colors.primary)),
                ],
              ),
              // 지출
              Column(
                children: [
                  Text('지출', style: labelStyle),
                  const SizedBox(height: 4),
                  Text('-${nf.format(expense)}원',
                      style: valueStyle?.copyWith(color: Colors.red)),
                ],
              ),
              // 합계
              Column(
                children: [
                  Text('합계', style: labelStyle),
                  const SizedBox(height: 4),
                  Text('$netSign$netAbs원',
                      style: valueStyle?.copyWith(color: colors.onBackground)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
