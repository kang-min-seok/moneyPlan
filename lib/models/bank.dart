import 'package:hive/hive.dart';

part 'bank.g.dart';

@HiveType(typeId: 4)
class Bank extends HiveObject {
  @HiveField(0)
  int id;         // PK

  @HiveField(1)
  String name;    // 은행 이름 (ex. '우리은행')

  @HiveField(2)
  String imagePath; // 로고 이미지의 asset 경로
  Bank({
    required this.id,
    required this.name,
    required this.imagePath,
  });
}