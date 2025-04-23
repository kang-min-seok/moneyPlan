// lib/pages/budget/budget_page.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/budget_period.dart';
import '../../models/budget_item.dart';
import '../../models/budget_category.dart';

import 'package:money_plan/pages/budget/budget_add_page.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy.MM.dd');
    final amtFmt = NumberFormat('#,##0', 'ko');

    final periodBox = Hive.box<BudgetPeriod>('budgetPeriods');
    final itemBox   = Hive.box<BudgetItem>('budgetItems');
    final catBox    = Hive.box<BudgetCategory>('categories');
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
          backgroundColor: colors.background,
          elevation: 0,
          title: const Text('예산 목록')
      ),
      body: ValueListenableBuilder(
        valueListenable: periodBox.listenable(),
        builder: (_, Box<BudgetPeriod> box, __) {
          if (box.isEmpty) {
            return const Center(child: Text('등록된 예산이 없습니다'));
          }

          // 최신 기간이 위로 오도록 정렬
          final periods = box.values.toList()
            ..sort((a, b) => b.startDate.compareTo(a.startDate));

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: periods.length,
            itemBuilder: (_, idx) {
              final p = periods[idx];

              // 총액 계산
              int totalLimit = 0;
              int totalSpent = 0;
              for (final it in p.items) {
                totalLimit += it.limitAmount;
                totalSpent += it.spentAmount;
              }

              return Card(
                elevation: 2,
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text('${df.format(p.startDate)} ~ ${df.format(p.endDate)}'),
                  subtitle: Text(
                    '한도 ${amtFmt.format(totalLimit)}원  ·  '
                        '사용 ${amtFmt.format(totalSpent)}원  ·  '
                        '잔액 ${amtFmt.format(totalLimit - totalSpent)}원',
                  ),
                  children: p.items.map((it) {
                    final cat = catBox.get(it.categoryId);
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: Color(cat?.colorValue ?? 0xFFCCCCCC),
                        radius: 12,
                      ),
                      title: Text(cat?.name ?? '카테고리?'),
                      trailing: Text(
                        '${amtFmt.format(it.spentAmount)} / ${amtFmt.format(it.limitAmount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.primary,
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BudgeAddPage()),
        ),
      ),
    );
  }
}
