// lib/pages/budget/budget_page.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/budget_period.dart';
import '../../models/budget_item.dart';
import '../../models/budget_category.dart';
import '../../models/transaction.dart';
import '../main/budget_item_list_page.dart';
import 'budget_add_page.dart';

/*──────────────────────────────────────── BudgetPage ───────────────────────────────*/
class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final boxP = Hive.box<BudgetPeriod>('budgetPeriods');
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: const Text('예산목록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            color: colors.onSurface,
            tooltip: '예산 편성',
            onPressed: () =>
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BudgeAddPage())
                ),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: boxP.listenable(),
        builder: (_, Box<BudgetPeriod> pBox, __) {
          if (pBox.isEmpty) {
            return const Center(child: Text('등록된 예산이 없습니다'));
          }
          final periods = pBox.values.toList()
            ..sort((a, b) => b.startDate.compareTo(a.startDate));

          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: periods.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, idx) => _BudgetPeriodCard(period: periods[idx]),
          );
        },
      ),
    );
  }
}

/*─────────────────────────────── 1 장의 접히는 카드 ───────────────────────────────*/
class _BudgetPeriodCard extends StatefulWidget {
  const _BudgetPeriodCard({required this.period});

  final BudgetPeriod period;

  @override
  State<_BudgetPeriodCard> createState() => _BudgetPeriodCardState();
}

class _BudgetPeriodCardState extends State<_BudgetPeriodCard>
    with SingleTickerProviderStateMixin {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme
        .of(context)
        .colorScheme;
    final catBox = Hive.box<BudgetCategory>('categories');
    final df = DateFormat('yyyy.MM.dd');
    final amtFmt = NumberFormat('#,##0', 'ko');

    /* ─ 총 한도·사용·남은 금액 & 파이 섹션 계산 ─ */
    /* ─ 총 한도·사용·남은 금액 & 파이 섹션 계산 ─ */
    int limit = 0, spent = 0;

    // ⬇⬇ 1) 정렬된 사본 준비
    final List<BudgetItem> sortedItems = [...widget.period.items]
      ..sort((a, b) => b.spentAmount.compareTo(a.spentAmount));

    final sections = <PieChartSectionData>[];
    for (final it in sortedItems) {            // ⬅ 파이차트도 같은 순서 사용
      limit += it.limitAmount;
      spent += it.spentAmount;
      if (it.spentAmount > 0) {
        final cat = catBox.get(it.categoryId);
        sections.add(PieChartSectionData(
          value : it.spentAmount.toDouble(),
          color : Color(cat?.colorValue ?? 0xFFCCCCCC),
          radius: 15,
          showTitle: false,
        ));
      }
    }

    final remain = limit - spent;

    /* ─ 카드 header (항상 보임) ─ */
    Widget header = InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _open = !_open),
      onLongPress: () => _showPeriodOptions(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${df.format(widget.period.startDate)} ~ '
                        '${df.format(widget.period.endDate)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),

                Icon(_open
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded),
              ],
            ),
            const SizedBox(height: 15),
            /* 날짜 & 숫자 블록 */
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kv('한도', amtFmt.format(limit)),
                      _kv('사용', amtFmt.format(spent)),
                      _kv('잔액', amtFmt.format(remain.abs()),
                          valueColor: remain < 0 ? Colors.redAccent : null),
                    ],
                  ),
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: sections.isEmpty
                        ? const SizedBox()
                        : PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 22,
                        sectionsSpace: 1.5,
                      ),
                    ),
                  ),
                ]
            ),
            /* 미니 파이차트 */

          ],
        ),
      ),
    );

    /* ─ 펼쳐졌을 때 나오는 BudgetItem 리스트 ─ */
    Widget items = Column(
      children: sortedItems.map((it) {
        final cat = catBox.get(it.categoryId);
        final spentI = it.spentAmount;
        final remainI = it.limitAmount - spentI;
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 12,
            backgroundColor: Color(cat?.colorValue ?? 0xFFCCCCCC),
          ),
          title: Text(cat?.name ?? '—',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15

              )
          ),
          trailing: Text(
            '${amtFmt.format(spentI)} / ${amtFmt.format(it.limitAmount)}',
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
            ),
          ),
          subtitle: Text(
            '잔액 ${amtFmt.format(remainI)}원',
            style: TextStyle(
                color: remainI < 0
                    ? Colors.redAccent
                    : Theme
                    .of(context)
                    .colorScheme
                    .outline),
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BudgetItemDetailPage(
                period: widget.period,
                item  : it,
              ),
            ),
          ),
        );
      }).toList(),
    );

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          header,
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: items,
            crossFadeState:
            _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  /* BudgetPeriod 수정/삭제 BottomSheet */
  void _showPeriodOptions(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title : const Text('예산 수정하기'),
              onTap : () {
                Navigator.pop(ctx);
                // TODO: 기간 편집 화면으로 이동
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title : const Text('예산 삭제하기',
                  style: TextStyle(color: Colors.redAccent)),
              onTap : () async {
                final boxP   = Hive.box<BudgetPeriod>('budgetPeriods');
                final boxI   = Hive.box<BudgetItem>('budgetItems');
                final boxTx  = Hive.box<Transaction>('transactions');

                /* 1) 연결된 BudgetItem · Transaction 정리 */
                for (final it in widget.period.items) {
                  // 해당 아이템에 달린 거래 모두 삭제
                  for (final tx in it.expenseTxs)      {
                    await boxTx.delete(tx.key);
                  }
                  await boxI.delete(it.key);            // 아이템 삭제
                }

                /* 2) BudgetPeriod 삭제 */
                await boxP.delete(widget.period.key);

                if (mounted) Navigator.pop(ctx);        // BottomSheet 닫기
                // 부모 ListView 는 ValueListenableBuilder 로 자동 새로고침
              },
            ),
          ],
        ),
      ),
    );
  }

  /* key-value 한 줄 */
  Widget _kv(String k, String v, {Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 38, child: Text(k)),
            Text(
              v,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: valueColor),
            ),
          ],
        ),
      );
}