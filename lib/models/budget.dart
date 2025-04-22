import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 1)
class Budget extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name; // 예산 이름

  @HiveField(2)
  final int limitAmount; // 설정 금액

  @HiveField(3)
  final int usedAmount; // 현재 사용 금액

  @HiveField(4)
  final String icon; // 아이콘 이름 혹은 경로

  Budget({
    required this.id,
    required this.name,
    required this.limitAmount,
    required this.usedAmount,
    required this.icon,
  });
}
