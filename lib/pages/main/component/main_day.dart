import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../../models/consumption.dart';
import './top_summary.dart';

class MainDay extends StatelessWidget {
  final DateTimeRange range;

  const MainDay({Key? key, required this.range}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('M월 d일 (E)', 'ko');
    final amtFmt  = NumberFormat('#,##0', 'ko');
    final box     = Hive.box<Consumption>('consumptions');
    final colors = Theme.of(context).colorScheme;
    final themes = Theme.of(context);
    return Column(
      children: [
        // 상단 요약
        TopSummary(range: range),
        // 일별 목록
        Expanded(
          child: ValueListenableBuilder<Box<Consumption>>(
            valueListenable: box.listenable(),
            builder: (context, box, _) {
              // 범위 내 데이터 추출
              final items = box.values
                  .where((c) => !c.date.isBefore(range.start) && !c.date.isAfter(range.end))
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));

              if (items.isEmpty) {
                return const Center(child: Text('등록된 소비 내역이 없습니다'));
              }

              // 날짜별 그룹핑
              final Map<DateTime, List<Consumption>> groups = {};
              for (var c in items) {
                final day = DateTime(c.date.year, c.date.month, c.date.day);
                groups.putIfAbsent(day, () => []).add(c);
              }

              // 일자 리스트 정렬
              final days = groups.keys.toList()
                ..sort((a, b) => b.compareTo(a));

              return ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final day = days[index];
                  final list = groups[day]!;
                  // 일별 합계
                  final income = list
                      .where((c) => c.type == '수입')
                      .fold<int>(0, (sum, c) => sum + (c.amount ?? 0));
                  final expense = list
                      .where((c) => c.type != '수입')
                      .fold<int>(0, (sum, c) => sum + (c.amount ?? 0));

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Divider(height: 1, color: themes.dividerColor,),
                      // 그룹 헤더
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 19),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateFmt.format(day),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Row(
                              children: [
                                Text(
                                  '+${amtFmt.format(income)}원',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 4),
                                // ─── 분리선 ───
                                SizedBox(
                                  height: 16,
                                  child: VerticalDivider(
                                    thickness: 1,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground
                                        .withOpacity(0.4),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Divider(
                                  color: colors.surface,
                                  height: 10,
                                  thickness: 5,
                                ),
                                const SizedBox(width: 4,),
                                Text(
                                  '-${amtFmt.format(expense)}원',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: themes.dividerColor,),
                      // 일별 항목
                      ...list.map((c) {
                        final amtText =
                            '${c.type == '수입' ? '+' : '-'}${amtFmt.format(c.amount ?? 0)}원';
                        final amtColor = c.type == '수입'
                            ? Theme.of(context).colorScheme.primary
                            : Colors.red;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Icon(
                            // 간단한 아이콘 매핑
                            c.type == '수입' ? Icons.attach_money : Icons.money_off,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          title: Text(c.description, style: Theme.of(context).textTheme.bodyMedium),
                          subtitle: Text(
                            '${c.category} • ${c.method}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6)),
                          ),
                          trailing: Text(
                            amtText,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: amtColor, fontWeight: FontWeight.bold),
                          ),
                          onLongPress: () {
                            // 수정/삭제 로직
                          },
                        );
                      }),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
