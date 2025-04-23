// lib/pages/main/main_page.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// 컴포넌트
import 'top_tabs/main_summary_page.dart';
import 'top_tabs/main_day_page.dart';
import 'top_tabs/main_week_page.dart';
// 페이지
import './transaction_add_page.dart';
// 모델
import '../../models/budget_period.dart';
import '../../models/budget_item.dart';
import '../../models/budget_category.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  BudgetPeriod? _currentPeriod;
  BudgetItem?   _currentItem;

  final _periodBox = Hive.box<BudgetPeriod>('budgetPeriods');
  final _catBox    = Hive.box<BudgetCategory>('categories');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final today = DateTime.now();
    for (final p in _periodBox.values) {
      if (!today.isBefore(p.startDate) && !today.isAfter(p.endDate)) {
        _currentPeriod = p;
        if (p.items.isNotEmpty) _currentItem = p.items.first;
        break;
      }
    }
  }

  /// 예산 항목 선택 BottomSheet
  Future<void> _pickBudgetPeriod() async {
    if (_periodBox.isEmpty) return;

    final periods = _periodBox.values.toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));   // 최근이 위

    final chosen = await showModalBottomSheet<BudgetPeriod>(
      context: context,
      builder: (ctx) => ListView(
        children: periods.map((p) {
          // 기간 텍스트
          final range = '${DateFormat('yyyy.MM.dd').format(p.startDate)}'
              ' ~ ${DateFormat('yyyy.MM.dd').format(p.endDate)}';

          // 기간 총 한도/사용액 요약
          int limit = 0, spent = 0;
          for (final it in p.items) {
            limit += it.limitAmount;
            spent += it.spentAmount;
          }

          return ListTile(
            title   : Text(range),
            subtitle: Text(
              '한도 ${NumberFormat('#,##0', 'ko').format(limit)}원  '
                  '사용 ${NumberFormat('#,##0', 'ko').format(spent)}원',
            ),
            onTap: () => Navigator.pop(ctx, p),
          );
        }).toList(),
      ),
    );

    if (chosen != null) {
      setState(() {
        _currentPeriod = chosen;
        _currentItem   = chosen.items.isNotEmpty ? chosen.items.first : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme  = Theme.of(context).textTheme;

    final df = DateFormat('MM.dd');
    final headerText = (_currentPeriod != null)
        ? '${df.format(_currentPeriod!.startDate)}'
        ' ~ ${df.format(_currentPeriod!.endDate)}'
        : '예산 선택';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        titleSpacing: 26,
        title: InkWell(
          onTap: _pickBudgetPeriod,
          child: Row(
            children: [
              Text(
                headerText,
                style: theme.displayLarge
                    ?.copyWith(color: colors.onBackground, fontSize: 20),
              ),
              Icon(Icons.expand_more_rounded, color: colors.onBackground),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelPadding: const EdgeInsets.only(right: 25),
          dividerColor: colors.surface,
          indicatorColor: colors.primary,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onBackground.withOpacity(0.6),
          labelStyle: theme.displayMedium
              ?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
          tabs: const [
            Tab(text: '일일'),
            Tab(text: '예산'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MainDayPage(period: _currentPeriod, key: ValueKey(_currentPeriod?.id)),
          MainWeekPage(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.primary,
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TransactionAddPage()),
        ),
      ),
    );
  }
}
