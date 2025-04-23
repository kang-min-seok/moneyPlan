// lib/pages/main/main_page.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:money_plan/pages/main/top_tabs/main_budget_page.dart';

// 컴포넌트
import 'top_tabs/main_day_page.dart';
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


  static BudgetPeriod? _cachedPeriod;
  static BudgetItem?   _cachedItem;

  late TabController _tabController;

  BudgetPeriod? _currentPeriod;
  BudgetItem?   _currentItem;


  final _periodBox = Hive.box<BudgetPeriod>('budgetPeriods');
  final _catBox    = Hive.box<BudgetCategory>('categories');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 1) 캐시가 있으면 그대로 사용
    _currentPeriod = _cachedPeriod;
    _currentItem   = _cachedItem;

    // 2) 앱 최초 진입일 때만 오늘 날짜로 탐색
    if (_currentPeriod == null) {
      final today = DateTime.now();
      for (final p in _periodBox.values) {
        if (p.contains(today)) {
          _currentPeriod = p;
          _currentItem   = p.items.isNotEmpty ? p.items.first : null;
          break;
        }
      }
      // 3) 결과를 캐시
      _cachedPeriod = _currentPeriod;
      _cachedItem   = _currentItem;
    }
  }

  /// 예산 항목 선택 BottomSheet
  Future<void> _pickBudgetPeriod() async {
    if (_periodBox.isEmpty) return;
    final periods = _periodBox.values.toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    final chosen = await showModalBottomSheet<BudgetPeriod>(
      context: context,
      builder: (ctx) => ListView(
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
        _cachedPeriod  = _currentPeriod;   // ← 캐시 업데이트
        _cachedItem    = _currentItem;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final themes  = Theme.of(context);

    final df = DateFormat('MM.dd');
    final headerText = (_currentPeriod != null)
        ? '${df.format(_currentPeriod!.startDate)}'
        ' ~ ${df.format(_currentPeriod!.endDate)}'
        : '예산 선택';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: InkWell(
          onTap: _pickBudgetPeriod,
          child: Row(
            children: [
              Text(
                headerText,
                style: themes.textTheme.displayLarge
                    ?.copyWith(color: colors.onSurface, fontSize: 20),
              ),
              Icon(Icons.expand_more_rounded, color: colors.onSurface),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelPadding: const EdgeInsets.only(right: 25),
          dividerColor: themes.dividerColor,
          indicatorColor: colors.primary,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurface.withOpacity(0.6),
          labelStyle: themes.textTheme.displayMedium
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
          MainBudgetPage(period: _currentPeriod!),
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
