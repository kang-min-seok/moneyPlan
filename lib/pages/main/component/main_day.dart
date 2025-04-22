// lib/pages/main/main_day.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../../models/consumption.dart';

class MainDay extends StatelessWidget {
  const MainDay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dateFormatter = DateFormat('yyyy-MM-dd (E)', 'ko');
    final amtFormatter = NumberFormat('#,##0', 'ko');

    return ValueListenableBuilder<Box<Consumption>>(
      valueListenable: Hive.box<Consumption>('consumptions').listenable(),
      builder: (context, box, _) {
        final items = box.values.toList();
        items.sort((a, b) => b.date.compareTo(a.date));

        if (items.isEmpty) {
          return const Center(child: Text('등록된 소비 내역이 없습니다'));
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: items.length,
          itemBuilder: (context, idx) {
            final c = items[idx];

            // 날짜 라벨
            final dayLabel = dateFormatter.format(c.date);

            // 금액 포맷팅 (예: 1,200,500)
            final amt = amtFormatter.format(c.amount);
            final sign = c.type == '수입' ? '+' : '-';
            final amtText = '$sign$amt원';

            // 색상 (수입은 primary, 지출은 red)
            final amtColor = c.type == '수입'
                ? colors.primary
                : Colors.red;

            return ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              // 왼쪽에 날짜만 보여주고 싶다면 leading,
              // 아니면 subtitle 위에 header 형태로 따로 그룹핑 로직 필요
              leading: Text(
                dayLabel,
                style: theme.textTheme.bodySmall,
              ),
              title: Text(
                c.description,
                style: theme.textTheme.bodyMedium,
              ),
              subtitle: Text(
                '${c.category} • ${c.method}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colors.onBackground.withOpacity(0.6)),
              ),
              trailing: Text(
                amtText,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: amtColor, fontWeight: FontWeight.bold),
              ),
            );
          },
        );
      },
    );
  }
}
