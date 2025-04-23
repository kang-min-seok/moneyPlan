import 'package:hive/hive.dart';
import './budget_category.dart';

part 'transaction.g.dart';

@HiveType(typeId: 3)
class Transaction extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  DateTime date;

  /// 소비(-) / 수익(+) 구분
  @HiveField(2)
  String type;

  @HiveField(3)
  int amount; // 음수 금액은 사용하지 않고 type 으로만 구분

  @HiveField(4)
  int categoryId;   // 수익일 때는 아무 값이나 가능

  @HiveField(5)
  String memo;

  /// 어느 BudgetPeriod 에 속하는지 (수익이면 null 가능)
  @HiveField(6)
  int? periodId;

  @HiveField(7)
  int budgetItemId;

  Transaction({
    required this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.memo,
    this.periodId,
    required this.budgetItemId,
  });
}