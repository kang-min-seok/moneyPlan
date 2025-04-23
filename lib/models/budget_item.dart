import 'package:hive/hive.dart';
import './transaction.dart';
import './budget_category.dart';

part 'budget_item.g.dart';

@HiveType(typeId: 1)
class BudgetItem extends HiveObject {
  @HiveField(0)
  int id;

  /// 카테고리(=예산 구분)
  @HiveField(1)
  int categoryId;

  /// 예산 한도(원)
  @HiveField(2)
  int limitAmount;

  /// 아이콘 식별자: 예) 'mdiFood', 'cupertinoCar'
  @HiveField(3)
  String iconKey;

  /// 현재까지 사용한 금액(원)
  ///   - 새 지출(Transaction) 추가/삭제 시 업데이트
  @HiveField(4)
  int spentAmount;

  /// 이 예산으로 분류된 지출(Transaction)들의 참조
  ///   - HiveList 로 저장하면 lazy-load, 삭제 자동 반영
  @HiveField(5)
  HiveList<Transaction> expenseTxs;

  BudgetItem({
    required this.id,
    required this.categoryId,
    required this.limitAmount,
    required this.iconKey,
    this.spentAmount = 0,
    HiveList<Transaction>? expenseTxs,
  }) : expenseTxs = expenseTxs ?? HiveList(Hive.box<Transaction>('transactions'));

  /// 잔액 계산기
  int get remaining => limitAmount - spentAmount;
}

