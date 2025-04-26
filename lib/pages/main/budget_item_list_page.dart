import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../componenets/daily_transaction_list.dart';
import '../../models/budget_category.dart';
import '../../models/budget_period.dart';
import '../../models/budget_item.dart';
import '../../models/transaction.dart';

class BudgetItemDetailPage extends StatelessWidget {
  const BudgetItemDetailPage({
    super.key,
    required this.period,
    required this.item,
  });

  final BudgetPeriod period;
  final BudgetItem item;

  @override
  Widget build(BuildContext context) {
    final txBox = Hive.box<Transaction>('transactions');
    final catBox = Hive.box<BudgetCategory>('categories'); // ← 추가
    final cat = catBox.get(item.categoryId);

    /*─ 거래 필터 : 선택 기간(날짜) & 선택 항목(지출) ─*/
    final ascending = txBox.values
        .where(
          (t) =>
              // 1) 지출만
              t.type == 'expense' &&
              // 2) 이 BudgetItem의 id와 일치
              t.budgetItemId == item.id &&
              // 3) 날짜가 현재 period 범위에 속하는지
              period.contains(t.date),
        )
        .sortedBy<num>((t) => t.date.millisecondsSinceEpoch);

    /*─ 잔액(남은 예산) 계산 ─*/
    final remainByTx = <int, int>{};
    int acc = 0; // 누적 지출
    for (final tx in ascending) {
      acc += tx.amount;
      remainByTx[tx.id] = item.limitAmount - acc;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(cat?.name ?? '소비 내역',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          /* 상단 한눈 요약 */
          _budgetProgress(context),
          Divider(color: Theme.of(context).dividerColor, height: 1),

          /* 일별 리스트 */
          Expanded(
            child: DailyTransactionList(
              transactions: ascending,
              remainByTxId: remainByTx,
            ),
          ),
        ],
      ),
    );
  }

  Widget _budgetProgress(BuildContext context) {
    final limit = item.limitAmount.toDouble();
    final spent = item.spentAmount.toDouble();
    final theme = Theme.of(context);
    final amtFmt = NumberFormat('#,##0', 'ko');

    final isOver = spent > limit;
    final usedRatio =
        limit == 0 ? 1.0 : ((spent / limit).clamp(0.0, 1.0) as num).toDouble();

    final overRatio = isOver
        ? (((spent - limit) / limit).clamp(0.0, 1.0) as num).toDouble()
        : 0.0; // 0 ~ 1 (초과분)

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /* 금액 텍스트 */
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('한도  ${amtFmt.format(limit)}원',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('사용  ${amtFmt.format(spent)}원',
                  style: TextStyle(
                      color: isOver
                          ? Colors.redAccent
                          : theme.colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 10),

          /* 진행 바 */
          SizedBox(
            height: 12,
            child: Stack(
              children: [
                // ── 배경
                Container(
                  decoration: BoxDecoration(
                    color: isOver
                        ? theme.colorScheme.primary
                        : theme.dividerColor, // 한도 초과 시 primary 로
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),

                // ── 사용분(파랑)
                FractionallySizedBox(
                  widthFactor: usedRatio,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),

                // ── 초과분(빨강)
                if (isOver)
                  FractionallySizedBox(
                    alignment: Alignment.centerRight,
                    widthFactor: overRatio,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
