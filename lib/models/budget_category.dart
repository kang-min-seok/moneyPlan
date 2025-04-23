import 'package:hive/hive.dart';

part 'budget_category.g.dart';

@HiveType(typeId: 2)
class BudgetCategory extends HiveObject {
  @HiveField(0)
  int id; // 고유 PK

  @HiveField(1)
  String name; // 사용자 지정 이름 (ex. '식비', '교통')

  @HiveField(2)
  String iconKey; // 아이콘 식별자

  @HiveField(3)
  int colorValue; // 💡 UI용 색상 (#198cff 등) → Color.value 저장

  BudgetCategory({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
  });
}