import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:collection/collection.dart';

import '../models/transaction.dart';
import '../models/budget_category.dart';
import '../models/budget_item.dart';
import '../pages/main/transaction_edit_page.dart';
import './icon_map.dart';

/// ──────────────────────────────────────────────────────────────
/// • [transactions] : **기간·카테고리 등 이미 필터링된** 전체 거래 리스트
///                    (Newest LAST! → 내부에서 자동으로 날짜별 그룹핑)
/// • [remainByTxId] : 지출(tx.id) → 남은 예산 금액  (없으면 0)
/// • 기타 UI 옵션은 필요 시 파라미터로 추가해 확장
/// ──────────────────────────────────────────────────────────────
class DailyTransactionList extends StatelessWidget {
  const DailyTransactionList({
    super.key,
    required this.transactions,
    required this.remainByTxId,
  });

  final List<Transaction> transactions;
  final Map<int, int> remainByTxId;

  /*──────────────── BottomSheet ────────────────*/
  void _showTxOptions(BuildContext context, Transaction tx) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('수정하기'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TransactionEditPage(tx: tx),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: Colors.redAccent,
              ),
              title: Text(
                '삭제하기',
                style: TextStyle(
                  color: Colors.redAccent,
                ),
              ),
              onTap: () async {
                final txBox = Hive.box<Transaction>('transactions');
                final itemBox = Hive.box<BudgetItem>('budgetItems');

                // 1) 연결된 예산 spentAmount 복원
                if (tx.type == 'expense') {
                  final item = itemBox.get(tx.budgetItemId);
                  if (item != null) {
                    item.spentAmount =
                        (item.spentAmount - tx.amount).clamp(0, 1 << 31);
                    await item.save();
                  }
                }

                // 2) 트랜잭션 삭제
                await txBox.delete(tx.key);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catBox = Hive.box<BudgetCategory>('categories');
    final dateFmt = DateFormat('M월 d일 (E)', 'ko');
    final amtFmt = NumberFormat('#,##0', 'ko');
    final theme = Theme.of(context);

    /*── 날짜별 그룹핑 (최근 → 오래된 순서) ─*/
    final groups = <DateTime, List<Transaction>>{};
    for (final t in transactions.reversed) {
      // 가장 최신이 위
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      groups.putIfAbsent(day, () => []).add(t);
    }
    final days = groups.keys.toList();

    return ListView.builder(
      itemCount: days.length,
      itemBuilder: (_, idx) {
        final day = days[idx];
        final list = groups[day]!;

        final dayInc = list
            .where((t) => t.type == 'income')
            .fold<int>(0, (s, t) => s + t.amount);
        final dayExp = list
            .where((t) => t.type == 'expense')
            .fold<int>(0, (s, t) => s + t.amount);

        return Column(
          children: [
            /*─ 날짜 헤더 ─*/
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dateFmt.format(day),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                      '+${amtFmt.format(dayInc)}  |  -${amtFmt.format(dayExp)}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Divider(height: 1, color: theme.dividerColor),

            /*─ 거래 카드 ─*/
            ...list.map((tx) {
              final isIncome = tx.type == 'income';
              final cat = catBox.get(tx.categoryId);

              final iconColor = isIncome
                  ? theme.colorScheme.primary
                  : Color(cat?.colorValue ?? 0xFFCCCCCC);
              final iconData = isIncome ?  Icons.add_rounded : iconMap[cat?.iconKey] ?? Icons.help_outline_outlined;

              return ListTile(
                contentPadding: isIncome ?
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6,) :
                const EdgeInsets.symmetric(horizontal: 8, vertical: 0,),
                leading: CircleAvatar(
                  backgroundColor: iconColor,
                  child: Icon(iconData, color: Colors.white),
                ),
                title: Text(tx.memo,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: isIncome
                    ? null
                    : Text(
                        '${cat?.name ?? '—'}${tx.path != '모름' ? ' | ${tx.path}' : ''}',
                      ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'}${amtFmt.format(tx.amount)}원',
                      style: TextStyle(
                          color: isIncome
                              ? theme.colorScheme.primary
                              : Colors.redAccent,
                          fontSize: 17,
                          fontWeight: FontWeight.bold),
                    ),
                    if (!isIncome)
                      Text(
                        '남은 예산: ${amtFmt.format(remainByTxId[tx.id] ?? 0)}원',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline),
                      ),
                  ],
                ),
                onLongPress: () => _showTxOptions(context, tx),
              );
            }),
            Divider(height: 1, color: theme.dividerColor),
          ],
        );
      },
    );
  }
}
