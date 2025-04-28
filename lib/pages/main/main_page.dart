// lib/pages/main/main_page.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:money_plan/pages/main/top_tabs/main_budget_page.dart';

// 컴포넌트
import '../../componenets/bottom_sheet/bottom_sheet_pick_budget_period.dart';
import '../budget/budget_edit_page.dart';
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
  static BudgetItem? _cachedItem;

  late TabController _tabController;

  BudgetPeriod? _currentPeriod;
  BudgetItem? _currentItem;

  final _periodBox = Hive.box<BudgetPeriod>('budgetPeriods');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 1) 캐시가 있으면 그대로 사용
    _currentPeriod = _cachedPeriod;
    _currentItem = _cachedItem;

    // 2) 앱 최초 진입일 때만 오늘 날짜로 탐색
    if (_currentPeriod == null) {
      final today = DateTime.now();
      for (final p in _periodBox.values) {
        if (p.contains(today)) {
          _currentPeriod = p;
          _currentItem = p.items.isNotEmpty ? p.items.first : null;
          break;
        }
      }
      // 3) 결과를 캐시
      _cachedPeriod = _currentPeriod;
      _cachedItem = _currentItem;
    }
  }

  /// 예산 항목 선택 BottomSheet
  Future<void> _pickBudgetPeriod() async {
    final chosen = await showBudgetPeriodPicker(context);
    if (chosen != null) {
      setState(() {
        _currentPeriod = chosen;
        _currentItem = chosen.items.isNotEmpty ? chosen.items.first : null;
        _cachedPeriod = _currentPeriod;
        _cachedItem = _currentItem;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final themes = Theme.of(context);

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
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.edit_rounded),
          //   tooltip: '예산 편집',
          //   color: _currentPeriod == null
          //       ? Theme.of(context).disabledColor
          //       : Theme.of(context).iconTheme.color,
          //   onPressed: _currentPeriod == null
          //       ? null
          //       : () async {
          //           // 1) 편집 페이지로 이동 (await 로 돌아올 때까지 대기)
          //           await Navigator.push(
          //             context,
          //             MaterialPageRoute(
          //               builder: (_) => BudgetEditPage(period: _currentPeriod!),
          //             ),
          //           );
          //           // 2) 돌아왔을 때 Hive에서 같은 id의 객체를 다시 조회
          //           final reloaded = _periodBox.get(_currentPeriod!.id);
          //           setState(() {
          //             _currentPeriod = reloaded;
          //             // _currentPeriod.items 가 바뀌었을 수 있으니 첫 번째 아이템도 업데이트
          //             _currentItem =
          //                 (reloaded != null && reloaded.items.isNotEmpty)
          //                     ? reloaded.items.first
          //                     : null;
          //             // 캐시도 덮어쓰기
          //             _cachedPeriod = _currentPeriod;
          //             _cachedItem = _currentItem;
          //           });
          //         },
          // ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            color: colors.onSurface,
            tooltip: '새 지출/수입 추가',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransactionAddPage()),
            ),
          ),
        ],
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
      body: (_currentPeriod == null)
          ? const Center(child: Text('예산을 먼저 선택하세요'))
          : TabBarView(
              controller: _tabController,
              children: [
                MainDayPage(
                    period: _currentPeriod, key: ValueKey(_currentPeriod?.id)),
                MainBudgetPage(period: _currentPeriod!),
              ],
            ),
    );
  }
}
