import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // groupBy 사용 예시 (코드에는 직접 사용 안 함)
import 'package:flutter/scheduler.dart'; // SchedulerBinding import 추가

import '../../models/transaction.dart';
import '../../models/budget_category.dart';
import '../../componenets/icon_map.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  CalendarPageState createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> {
  late final Box<Transaction> _txBox;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 날짜별 수입·지출 합계 맵은 더 이상 상태 변수로 관리하지 않고 builder 안에서 계산합니다.

  @override
  void initState() {
    super.initState();
    _txBox = Hive.box<Transaction>('transactions');
    _selectedDay = _focusedDay;
    // _computeDailyTotals() 제거
  }

  // ValueListenableBuilder 안으로 이동
  Map<DateTime, Map<String, int>> _computeDailyTotals(Box<Transaction> box) {
    final all = box.values.toList();
    final dailyTotals = <DateTime, Map<String, int>>{};

    for (var tx in all) {
      // 시간 정보를 제거하고 날짜만 남김
      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);

      // 해당 날짜의 맵이 없으면 생성
      dailyTotals.putIfAbsent(day, () => {'income': 0, 'expense': 0});

      // 수입 또는 지출에 따라 금액 추가
      if (tx.type == 'income') {
        dailyTotals[day]!['income'] = dailyTotals[day]!['income']! + tx.amount;
      } else {
        dailyTotals[day]!['expense'] =
            dailyTotals[day]!['expense']! + tx.amount;
      }
    }
    return dailyTotals;
  }

  List<Transaction> _transactionsForDay(DateTime day) {
    // 날짜 선택 시 하단 리스트 업데이트를 위해 시간 정보 제거
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _txBox.values.where((tx) {
      // 거래 날짜가 선택된 날짜의 시작과 끝 사이에 있는지 확인
      return tx.date
              .isAfter(startOfDay.subtract(const Duration(microseconds: 1))) &&
          tx.date.isBefore(endOfDay);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // 최신 거래부터 정렬
  }

  @override
  Widget build(BuildContext context) {
    final amtFmt = NumberFormat('#,##0', 'ko');
    final catBox = Hive.box<BudgetCategory>('categories');
    final currentLocale = Localizations.localeOf(context).languageCode;
    return Scaffold(


      body: SafeArea(
          child: Column(
            children: [
              // ValueListenableBuilder로 감싸서 Hive 데이터 변경 시 캘린더 재생성
              ValueListenableBuilder(
                valueListenable: _txBox.listenable(),
                builder: (context, Box<Transaction> box, child) {
                  // 데이터 변경 시 날짜별 합계 다시 계산
                  final dailyTotals = _computeDailyTotals(box);

                  // 계산된 합계를 사용하여 CalendarBuilders 정의
                  return TableCalendar(
                    locale: currentLocale,
                    rowHeight: 64,
                    daysOfWeekHeight: 22,
                    firstDay: DateTime.utc(2000, 1, 1),
                    // UTC 사용 권장
                    lastDay: DateTime.utc(2100, 12, 31),
                    // UTC 사용 권장
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                    onDaySelected: (selected, focused) {
                      // 날짜 선택 시 상태 업데이트
                      // SchedulerBinding.instance.addPostFrameCallback를 사용하면
                      // onDaySelected 완료 후 UI 업데이트를 보장할 수 있습니다.
                      if (!isSameDay(_selectedDay, selected)) {
                        setState(() {
                          _selectedDay = selected;
                          _focusedDay = focused; // 보통 selectedDay와 동일하게 설정
                        });
                      } else {
                        // 이미 선택된 날짜를 다시 탭했을 경우 선택 해제
                        setState(() {
                          _selectedDay = null;
                        });
                      }
                    },
                    // calendarStyle: const CalendarStyle(
                    //   markersMaxCount: 0, // 마커 대신 빌더 사용
                    //   todayDecoration: BoxDecoration(
                    //     // 오늘 날짜 기본 스타일 유지 또는 커스텀
                    //     color: Colors.transparent,
                    //     // todayBuilder 사용 안 하면 기본 파란색 원이 생김
                    //     shape: BoxShape.circle,
                    //   ),
                    //   // defaultTextStyle, weekendTextStyle 등 필요 시 추가
                    // ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false, // '2주', '월' 선택 버튼 숨김
                      titleCentered: true,
                      titleTextStyle: const TextStyle(
                          fontSize: 17.0, fontWeight: FontWeight.bold),
                    ),
                    // 요일 헤더 (월, 화, 수...) 스타일 변경 예시
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      weekendStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                    calendarBuilders: CalendarBuilders(
                      // 기본 날짜 셀 빌더
                      defaultBuilder: (context, day, focusedDay) {
                        // 해당 날짜의 합계 데이터 가져오기 (없으면 기본값 0)
                        final totals =
                            dailyTotals[DateTime(day.year, day.month, day.day)] ??
                                {'income': 0, 'expense': 0};
                        final income = totals['income']!;
                        final expense = totals['expense']!;

                        // 선택된 날짜이거나 오늘 날짜인 경우는 해당 빌더에서 처리하지 않고
                        // selectedBuilder 또는 todayBuilder에게 맡깁니다.
                        if (isSameDay(day, _selectedDay)) {
                          return null; // selectedBuilder 사용
                        }
                        if (isSameDay(day, _focusedDay) &&
                            isSameDay(day, DateTime.now())) {
                          // focusedDay가 오늘 날짜이고 선택되지 않았다면 todayBuilder 사용 (아래 todayBuilder를 활성화하면)
                          return null; // todayBuilder 사용 (만약 todayBuilder를 구현했다면)
                        }

                        return Container(
                          // Container로 감싸서 패딩/마진 및 정렬 적용
                          margin: const EdgeInsets.all(3.0),
                          // 셀 내부 마진
                          padding: const EdgeInsets.fromLTRB(1, 5, 1, 1),
                          // 셀 내부 패딩
                          alignment: Alignment.topCenter,
                          // 날짜 숫자를 위에 정렬
                          decoration: BoxDecoration(
                            // 필요 시 배경색 등 추가
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            // 컨텐츠 크기만큼만 공간 차지
                            crossAxisAlignment: CrossAxisAlignment.center,
                            // 가로 중앙 정렬
                            children: [
                              // 날짜 숫자
                              Text('${day.day}',
                                  style: const TextStyle(
                                    fontSize: 14, // 날짜 숫자 크기 조정
                                    fontWeight: FontWeight.bold,
                                    // 색상 조정 (주말 등)
                                    // color: day.weekday == DateTime.saturday ? Colors.blue :
                                    //        day.weekday == DateTime.sunday ? Colors.red : Colors.black,
                                  )),
                              const SizedBox(height: 2), // 날짜와 합계 사이 간격

                              // 수입 표시
                              if (income > 0)
                                Text(
                                  '+${amtFmt.format(income)}',
                                  style: const TextStyle(
                                      fontSize: 9, // 수입/지출 금액 글자 크기
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold // 약간 두껍게
                                  ),
                                  overflow: TextOverflow.ellipsis, // 너무 길면 ... 처리
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                ),

                              // 지출 표시
                              if (expense > 0)
                                Text(
                                  '-${amtFmt.format(expense)}',
                                  style: const TextStyle(
                                      fontSize: 9, // 수입/지출 금액 글자 크기
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold // 약간 두껍게
                                  ),
                                  overflow: TextOverflow.ellipsis, // 너무 길면 ... 처리
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                ),
                              // 공간이 부족할 경우 더 많은 정보를 표시하기 어렵습니다.
                              // 디자인에 따라 수입/지출 중 하나만 표시하거나 아이콘 등으로 대체할 수도 있습니다.
                            ],
                          ),
                        );
                      },

                      // 오늘 날짜 셀 빌더 (기본 todayDecoration 대신 커스텀)
                      // todayBuilder를 활성화하면 defaultBuilder에서 isSameDay(day, DateTime.now()) 일 때 null 반환 필요
                      todayBuilder: (context, day, focusedDay) {
                        final totals =
                            dailyTotals[DateTime(day.year, day.month, day.day)] ??
                                {'income': 0, 'expense': 0};
                        final income = totals['income']!;
                        final expense = totals['expense']!;

                        if (isSameDay(day, _selectedDay)) {
                          return null; // 선택된 날짜면 selectedBuilder 사용
                        }

                        return Container(
                          margin: const EdgeInsets.all(3.0),
                          padding: const EdgeInsets.fromLTRB(1, 5, 1, 1),
                          alignment: Alignment.topCenter,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            color: Colors.blue.withOpacity(0.2), // 오늘 날짜 배경색
                            shape: BoxShape.rectangle, // 원형 배경
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 날짜 숫자
                              Text('${day.day}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue // 오늘 날짜 숫자 색상
                                  )),
                              const SizedBox(height: 2),
                              // 수입 표시
                              if (income > 0)
                                Text(
                                  '+${amtFmt.format(income)}',
                                  style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                ),
                              // 지출 표시
                              if (expense > 0)
                                Text(
                                  '-${amtFmt.format(expense)}',
                                  style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        );
                      },

                      // 선택된 날짜 셀 빌더
                      selectedBuilder: (context, day, focusedDay) {
                        final totals =
                            dailyTotals[DateTime(day.year, day.month, day.day)] ??
                                {'income': 0, 'expense': 0};
                        final income = totals['income']!;
                        final expense = totals['expense']!;

                        return Container(
                          margin: const EdgeInsets.all(3.0),
                          padding: const EdgeInsets.fromLTRB(1, 5, 1, 1),
                          alignment: Alignment.topCenter,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            color: Theme.of(context)
                                .colorScheme.primary, // 선택된 날짜 배경색
                            shape: BoxShape.rectangle, // 원형 배경// 테두리
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 날짜 숫자
                              Text('${day.day}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white, // 선택된 날짜 숫자 색상
                                  )),
                              const SizedBox(height: 2),
                              // 수입 표시
                              if (income > 0)
                                Text(
                                  '+${amtFmt.format(income)}',
                                  style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                  // 선택 시 흰색 등 변경
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                ),
                              // 지출 표시
                              if (expense > 0)
                                Text(
                                  '-${amtFmt.format(expense)}',
                                  style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold),
                                  // 선택 시 흰색 등 변경
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        );
                      },

                      // outsideBuilder, disabledBuilder 등 필요 시 추가
                      // outsideBuilder를 사용하면 이전/다음 달 날짜도 표시 가능합니다.
                    ),
                  );
                },
              ),


              // 선택된 날짜의 상세 리스트 (ValueListenableBuilder는 이미 적용되어 있음)
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: _txBox.listenable(),
                  builder: (_, Box<Transaction> box, __) {
                    // _selectedDay가 null일 경우 _focusedDay를 기본값으로 사용
                    final day = _selectedDay ??
                        DateTime(DateTime.now().year, DateTime.now().month,
                            DateTime.now().day);
                    final list =
                    _transactionsForDay(day); // _transactionsForDay 수정됨
                    if (list.isEmpty) {
                      return Center(child: Text('등록된 거래가 없습니다.'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(),
                      itemBuilder: (_, idx) {
                        final tx = list[idx];
                        final isIncome = tx.type == 'income';
                        // 카테고리 정보가 없을 수 있으므로 null 체크 강화
                        final cat = catBox.get(tx.categoryId);
                        final iconColor = isIncome
                            ? Colors.blue // 수입 아이콘 색상
                            : Color(
                            cat?.colorValue ?? 0xFF888888); // 지출 카테고리 색상 또는 기본값
                        final iconData = isIncome
                            ? Icons.add_rounded // 수입 아이콘
                            : iconMap[cat?.iconKey] ??
                            Icons.help_outline; // 지출 카테고리 아이콘 또는 기본 아이콘

                        return ListTile(
                          leading: CircleAvatar(
                              backgroundColor: iconColor,
                              child: Icon(iconData, color: Colors.white, size: 20)),
                          // 아이콘 크기 조정
                          title: Text(tx.memo.isNotEmpty
                              ? tx.memo
                              : (isIncome ? '수입' : cat?.name ?? '기타 지출')),
                          // 메모 없으면 기본값 표시
                          subtitle: isIncome ? null : Text(cat?.name ?? '—'),
                          // 지출일 때만 카테고리 표시
                          trailing: Text(
                            '${isIncome ? '+' : '-'}${amtFmt.format(tx.amount)}원',
                            style: TextStyle(
                                color: isIncome ? Colors.blue : Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
      )
    );
  }
}
