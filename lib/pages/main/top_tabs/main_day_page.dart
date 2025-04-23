// lib/pages/main/top_tabs/main_day_page.dart
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../../models/budget_period.dart';
import '../../../models/transaction.dart';
import '../../../models/budget_category.dart';

class MainDayPage extends StatelessWidget {
  final BudgetPeriod? period;            // 선택한 예산 기간

  const MainDayPage({super.key, required this.period});

  @override
  Widget build(BuildContext context) {
    if (period == null) {
      return const Center(child: Text('선택된 예산 기간이 없습니다'));
    }

    final txBox   = Hive.box<Transaction>('transactions');
    final catBox  = Hive.box<BudgetCategory>('categories');
    final dateFmt = DateFormat('M월 d일 (E)', 'ko');
    final amtFmt  = NumberFormat('#,##0', 'ko');
    final theme   = Theme.of(context);
    final colors = Theme.of(context).colorScheme;
    return ValueListenableBuilder(
      valueListenable: txBox.listenable(),
      builder: (_, Box<Transaction> box, __) {
        /*──────────────── ① 기간으로 필터 & 오름차순 정렬 ­───────────────*/
        final ascending = box.values
            .where((t) => t.periodId == period!.id)
            .sortedBy<num>((t) => t.date.millisecondsSinceEpoch);

        if (ascending.isEmpty) {
          return const Center(child: Text('등록된 소비 내역이 없습니다'));
        }

        /*──────────────── ② 거래별 잔액 계산 ­───────────────*/
        final remainMap = <int, int>{};          // txId → remain
        final spentAcc  = <int, int>{};          // budgetItemId → 누적지출

        for (final tx in ascending) {
          if (tx.type == 'expense') {
            // ❶ 누적 지출 갱신
            spentAcc.update(tx.budgetItemId, (v) => v + tx.amount,
                ifAbsent: () => tx.amount);

            // ❷ 한도 찾기 (period.items 에 없으면 remain = 0)
            final item = period!.items
                .firstWhereOrNull((it) => it.id == tx.budgetItemId);
            final limit = item?.limitAmount ?? 0;
            final remain = limit - (spentAcc[tx.budgetItemId] ?? 0);
            remainMap[tx.id] = remain;
          } else {
            // 수입은 잔액 계산 대상 아님
            remainMap[tx.id] = 0;
          }
        }

        /*──────────────── ③ 화면에 표시할 리스트 = 내림차순 ­───────────────*/
        final txs = ascending.reversed.toList();

        // 전체 합계
        final totalIncome  = txs.where((t) => t.type == 'income')
            .fold<int>(0, (s, t) => s + t.amount);
        final totalExpense = txs.where((t) => t.type == 'expense')
            .fold<int>(0, (s, t) => s + t.amount);

        // 날짜별 그룹핑
        final groups = <DateTime, List<Transaction>>{};
        for (final t in txs) {
          final day = DateTime(t.date.year, t.date.month, t.date.day);
          groups.putIfAbsent(day, () => []).add(t);
        }
        final days = groups.keys.toList()..sort((b, a) => a.compareTo(b));

        return Column(
          children: [
            /*──── 상단 요약 ────*/
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _cell('수입',  amtFmt.format(totalIncome),  theme.colorScheme.primary),
                  _cell('지출', amtFmt.format(totalExpense), Colors.redAccent),
                  _cell('합계', amtFmt.format(totalIncome - totalExpense),
                      theme.colorScheme.onBackground),
                ],
              ),
            ),
            Divider(
                height: 1,
                color: colors.surface,
            ),

            /*──── 일별 리스트 ────*/
            Expanded(
              child: ListView.builder(
                itemCount: days.length,
                itemBuilder: (_, idx) {
                  final day  = days[idx];
                  final list = groups[day]!;

                  final dayIncome  = list.where((t) => t.type == 'income')
                      .fold<int>(0, (s, t) => s + t.amount);
                  final dayExpense = list.where((t) => t.type == 'expense')
                      .fold<int>(0, (s, t) => s + t.amount);

                  return Column(
                    children: [
                      /*── 날짜 헤더 ──*/
                      Container(
                        color: theme.colorScheme.background,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dateFmt.format(day),
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)
                            ),
                            Text('+${amtFmt.format(dayIncome)}  |  '
                                '-${amtFmt.format(dayExpense)}',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: colors.surface,
                      ),

                      /*── 거래 카드 ──*/
                      ...list.map((tx) {
                        final isIncome = tx.type == 'income';
                        final cat = catBox.get(tx.categoryId);

                        // 색상·아이콘 결정
                        final iconColor = isIncome
                            ? theme.colorScheme.primary
                            : Color(cat?.colorValue ?? 0xFFCCCCCC);
                        final iconData  = isIncome ? Icons.add : Icons.receipt_long;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: iconColor,
                            child: Icon(iconData, color: Colors.white),
                          ),
                          title: Text(
                            tx.memo,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          // ── 수입일 땐 카테고리 숨김
                          subtitle: isIncome ? null : Text(cat?.name ?? '—'),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${isIncome ? '+' : '-'}${amtFmt.format(tx.amount)}원',
                                style: TextStyle(
                                    color: isIncome ? theme.colorScheme.primary : Colors.redAccent,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold),
                              ),
                              // ── 지출일 때만 잔액 표시
                              if (!isIncome)
                                Text(
                                  '남은 예산: ${amtFmt.format(remainMap[tx.id] ?? 0)}원',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: theme.colorScheme.outline),
                                ),
                            ],
                          ),
                        );
                      }),
                      Divider(
                        height: 1,
                        color: colors.surface,
                      ),
                    ],
                  );
                },
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
      Text(label,
          style:
          const TextStyle( fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 16)),
    ],
  );
}
