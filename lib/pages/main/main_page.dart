import 'package:flutter/material.dart';

// 컴포넌트
import 'component/main_summary.dart';
import 'component/main_day.dart';
import 'component/main_week.dart';
// 페이지
import './add_consumption_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colors.background,
          elevation: 1,
          // 좌측 “4월” 영역
          title: Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Row(
              children: [
                InkWell(
                  onTap: () => print('월 드롭다운 터치됨'),
                  child: Row(
                    children: [
                      Text(
                        '4월',
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: colors.onBackground,
                          fontSize: 25,
                        ),
                      ),
                      Icon(
                        Icons.expand_more_rounded,
                        color: colors.onBackground,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => print('필터 버튼'),
                  icon: Icon(Icons.filter_list, color: colors.onBackground),
                ),
                IconButton(
                  onPressed: () => print('검색 버튼'),
                  icon: Icon(Icons.search, color: colors.onBackground),
                ),
              ],
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            labelPadding: const EdgeInsets.only(right: 24),
            indicatorColor: colors.primary,
            labelColor: colors.primary,
            unselectedLabelColor: colors.onBackground.withOpacity(0.6),
            labelStyle: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            tabs: const [
              Tab(text: '요약'),
              Tab(text: '일일'),
              Tab(text: '주간'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MainSummary(), // lib/main/component/main_summary.dart 에 정의된 위젯
            MainDay(),     // lib/main/component/main_day.dart 에 정의된 위젯
            MainWeek(),    // lib/main/component/main_week.dart 에 정의된 위젯
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AddConsumptionPage(),
              ),
            );
          },
          backgroundColor: colors.primary,
          child: const Icon(Icons.add),
        ),

      ),
    );
  }
}
