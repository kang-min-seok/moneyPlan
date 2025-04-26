// lib/pages/main/top_tabs/main_day_page.dart
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../../componenets/daily_transaction_list.dart';
import '../../../models/budget_period.dart';
import '../../../models/transaction.dart';
import '../../../models/budget_category.dart';

class MainDayPage extends StatelessWidget {
  final BudgetPeriod? period; // 선택한 예산 기간

  const MainDayPage({super.key, required this.period});

  @override
  Widget build(BuildContext context) {
    if (period == null) {
      return const Center(child: Text('선택된 예산 기간이 없습니다'));
    }

    final txBox = Hive.box<Transaction>('transactions');
    final amtFmt = NumberFormat('#,##0', 'ko');
    final theme = Theme.of(context);

    return ValueListenableBuilder(
      valueListenable: txBox.listenable(),
      builder: (_, Box<Transaction> box, __) {
        /*─ ① 기간 필터 / 오름차순 ─*/
        final ascending = box.values
            .where((t) => period!.contains(t.date))
            .sortedBy<num>((t) => t.date.millisecondsSinceEpoch);

        if (ascending.isEmpty) {
          return const Center(child: Text('등록된 소비 내역이 없습니다'));
        }

        /*─ ② 잔액 계산 (지출 전용) ─*/
        final remain = <int, int>{};
        final spent = <int, int>{};
        for (final tx in ascending) {
          if (tx.type == 'expense' && tx.budgetItemId != null) {
            final bid = tx.budgetItemId!;
            spent.update(bid, (v) => v + tx.amount, ifAbsent: () => tx.amount);
            final limit = period!.items
                    .firstWhereOrNull((it) => it.id == bid)
                    ?.limitAmount ??
                0;
            remain[tx.id] = limit - (spent[bid] ?? 0);
          } else {
            // 수입이거나 budgetItemId 가 없으면 잔액 계산 안 함
            remain[tx.id] = 0;
          }
        }

        /*─ ③ 상단 요약 ─*/
        final totalInc = ascending
            .where((t) => t.type == 'income')
            .fold<int>(0, (s, t) => s + t.amount);
        final totalExp = ascending
            .where((t) => t.type == 'expense')
            .fold<int>(0, (s, t) => s + t.amount);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _cell(
                      '수입', amtFmt.format(totalInc), theme.colorScheme.primary),
                  _cell('지출', amtFmt.format(totalExp), Colors.redAccent),
                  _cell('합계', amtFmt.format(totalInc - totalExp),
                      theme.colorScheme.onBackground),
                ],
              ),
            ),
            Divider(height: 1, color: theme.dividerColor),

            /*─ ④ 재사용 위젯 ─*/
            Expanded(
              child: DailyTransactionList(
                transactions: ascending,
                remainByTxId: remain,
              ),
            ),
          ],
        );
      },
    );
  }

  /*──── 작은 헬퍼 ────*/
  Widget _cell(String label, String value, Color color) => Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      );
}
