import '../models/bank.dart';
import '../models/budget_category.dart';

List<BudgetCategory> defaultCategories() => [
  BudgetCategory(id: 0, name: '적금',     iconKey: 'savings',           colorValue: 0xFF00695C),
  BudgetCategory(id: 0, name: '식비',     iconKey: 'restaurant',        colorValue: 0xFFEF6C00),
  BudgetCategory(id: 0, name: '통신',     iconKey: 'cell_tower',        colorValue: 0xFF5C6BC0),
  BudgetCategory(id: 0, name: '교통',     iconKey: 'directions_bus',    colorValue: 0xFF00838F),
  BudgetCategory(id: 0, name: '생활',     iconKey: 'shopping_cart',     colorValue: 0xFF8D6E63),
  BudgetCategory(id: 0, name: '청약',     iconKey: 'account_balance',   colorValue: 0xFF455A64),
  BudgetCategory(id: 0, name: '경조/선물', iconKey: 'redeem',            colorValue: 0xFFAD1457),
  BudgetCategory(id: 0, name: '비상금',   iconKey: 'emergency',         colorValue: 0xFFD84315),
  BudgetCategory(id: 0, name: '고정',     iconKey: 'schedule',          colorValue: 0xFF6A1B9A),
  BudgetCategory(id: 0, name: '기타',     iconKey: 'category',          colorValue: 0xFF9E9E9E),
];

List<Bank> defaultBanks() => [
  Bank(id: 0, name: '우리은행',   imagePath: 'assets/img/WOORI.png',),
  Bank(id: 0, name: '국민은행',   imagePath: 'assets/img/KB.png',  ),
  Bank(id: 0, name: '신한은행',   imagePath: 'assets/img/SINHAN.png',),
  Bank(id: 0, name: '하나은행',   imagePath: 'assets/img/HANA.png', ),
  Bank(id: 0, name: '케이뱅크',   imagePath: 'assets/img/KBANK.png',),
  Bank(id: 0, name: '카카오뱅크', imagePath: 'assets/img/KAKAO.png',),
  Bank(id: 0, name: '기업은행',   imagePath: 'assets/img/IBK.png',  ),
  Bank(id: 0, name: '농협',       imagePath: 'assets/img/NONGHYB.png',),
  Bank(id: 0, name: 'SC제일은행', imagePath: 'assets/img/SC.png',   ),
  Bank(id: 0, name: '우체국',     imagePath: 'assets/img/UCHEGUK.png',),
  Bank(id: 0, name: '현금',       imagePath: 'assets/img/cash.png',),
];