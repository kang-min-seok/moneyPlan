import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../models/budget_period.dart';

/// 호출 예)
/// final picked = await showBudgetPeriodPicker(context);
Future<BudgetPeriod?> showBudgetPeriodPicker(BuildContext context) {
  return showModalBottomSheet<BudgetPeriod>(
    context: context,
    builder: (ctx) {
      final box = Hive.box<BudgetPeriod>('budgetPeriods');
      final periods = box.values.toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
      if (periods.isEmpty) {
        return const SizedBox(
          height: 180,                       // 시트 높이 조금만 확보
          child: Center(child: Text('예산 목록이 없습니다')),
        );
      }
      return ListView(
        children: periods.map((p) {
          final range =
              '${DateFormat('yyyy.MM.dd').format(p.startDate)}'
              ' ~ ${DateFormat('yyyy.MM.dd').format(p.endDate)}';
          int limit = 0, spent = 0;
          for (final it in p.items) {
            limit += it.limitAmount;
            spent += it.spentAmount;
          }
          return ListTile(
            title: Text(range),
            subtitle: Text(
              '한도 ${NumberFormat('#,##0','ko').format(limit)}원  '
                  '사용 ${NumberFormat('#,##0','ko').format(spent)}원',
            ),
            onTap: () => Navigator.pop(ctx, p),
          );
        }).toList(),
      );
    },
  );
}
