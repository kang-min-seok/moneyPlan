import 'package:hive/hive.dart';

part 'consumption.g.dart';

@HiveType(typeId: 0)
class Consumption extends HiveObject {

  @HiveField(0)
  final int id;

  @HiveField(1)
  final String type; // 지출 혹은 수입

  @HiveField(2)
  final String category; // 어떤 예산인지

  @HiveField(3)
  final String description; // 소비 내용

  @HiveField(4)
  final String method; // 소비수단

  @HiveField(5)
  final DateTime date; // 거래 날짜

  @HiveField(6)
  final DateTime addDate; // 추가한 날짜

  @HiveField(7)
  final int? amount; // 추가한 날짜

  Consumption({
    required this.id,
    required this.type,
    required this.category,
    required this.description,
    required this.method,
    required this.date,
    required this.addDate,
    required this.amount,
  });
}
