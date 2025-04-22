// lib/pages/main/main_page.dart
import 'package:flutter/material.dart';

// 컴포넌트
import 'component/main_summary.dart';
import 'component/main_day.dart';
import 'component/main_week.dart';
import 'component/bottom_sheet_date.dart';
// 페이지
import './add_consumption_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // 기본: 이번 달 1일 ~ 말일
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate   = DateTime(now.year, now.month + 1, 0);
  }

  Future<void> _showModalBottomSheet(BuildContext context, String filter) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => const BottomSheetDate(),
    );
    if (result != null) {
      _applyFilters(result);
    }
  }

  void _applyFilters(Map<String, dynamic> filterResult) {
    setState(() {
      // startDate/endDate만 덮어쓰기
      if (filterResult.containsKey('startDate')) {
        _startDate = filterResult['startDate'] as DateTime?;
      }
      if (filterResult.containsKey('endDate')) {
        _endDate = filterResult['endDate'] as DateTime?;
      }
      // 나머지 필터는 무시
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme  = Theme.of(context).textTheme;

    // 상단 타이틀: "4월" 같은 월 표시. 범위가 설정돼 있으면 "MM.dd–MM.dd" 로도 만들 수 있어요.
    final titleText = _startDate != null
        ? '${_startDate!.month}월'
        : '날짜 설정';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        titleSpacing: 26,
        title: InkWell(
          onTap: () => _showModalBottomSheet(context, '날짜'),
          child: Row(
            children: [
              Text(
                titleText,
                style: theme.displayLarge
                    ?.copyWith(color: colors.onBackground, fontSize: 25),
              ),
              Icon(Icons.expand_more_rounded, color: colors.onBackground),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.filter_list, color: colors.onBackground),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.search, color: colors.onBackground),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelPadding: EdgeInsets.only(right: 25),
          dividerColor: colors.surface,
          indicatorColor: colors.primary,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onBackground.withOpacity(0.6),
          labelStyle: theme.displayMedium
              ?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
          tabs: const [
            Tab(text: '요약'),
            Tab(text: '일일'),
            Tab(text: '주간'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Container(
            color: colors.background,
            child: const MainSummary(),
          ),
          Container(
            color: colors.background,
            child: MainDay(
              range: DateTimeRange(start: _startDate!, end: _endDate!),
            ),
          ),
          Container(
            color: colors.background,
            child: const MainWeek(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.primary,
        child: const Icon(Icons.add),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddConsumptionPage()),
        ),
      ),
    );
  }
}
