import 'package:hive/hive.dart';
import './budget_item.dart';


part 'budget_period.g.dart';

@HiveType(typeId: 0)
class BudgetPeriod extends HiveObject {
  /// 고유 ID (HiveObject.key 로도 접근 가능하지만 명시적으로 둠)
  @HiveField(0)
  int id;

  /// 예산 적용 시작 날짜
  @HiveField(1)
  DateTime startDate;
  /// 종료 날짜
  @HiveField(2)
  DateTime endDate;

  /// 이 기간에 편성된 예산 항목들
  /// HiveObject 를 중첩으로 저장하기 위해서는 HiveList 를 사용
  @HiveField(3)
  HiveList<BudgetItem> items;

  BudgetPeriod({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.items,
  });

  bool contains(DateTime date) =>
      !date.isBefore(startDate) && !date.isAfter(endDate);
}