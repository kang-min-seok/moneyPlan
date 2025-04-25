import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:money_plan/theme/theme_provider.dart';
import 'package:money_plan/theme/theme_custom.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:intl/date_symbol_data_local.dart';

import './pages/main/main_page.dart';
import './pages/calendar/calendar_page.dart';
import './pages/setting/setting_page.dart';
import './pages/budget/budget_page.dart';

import 'models/bank.dart';
import 'models/budget_period.dart';
import 'models/budget_item.dart';
import 'models/budget_category.dart';
import 'models/transaction.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ko');

  final prefs = await SharedPreferences.getInstance();
  ThemeMode themeMode = ThemeMode.system;
  final String? savedThemeMode = prefs.getString('themeMode');

  if (savedThemeMode == null) {
    themeMode = ThemeMode.system;
  } else if (savedThemeMode == "light") {
    themeMode = ThemeMode.light;
  } else if (savedThemeMode == "dark") {
    themeMode = ThemeMode.dark;
  } else if (savedThemeMode == "system") {
    themeMode = ThemeMode.system;
  }

  await Hive.initFlutter();

  // 어댑터 등록
  Hive
    ..registerAdapter(BudgetPeriodAdapter())   // typeId: 0
    ..registerAdapter(BudgetItemAdapter())     // typeId: 1
    ..registerAdapter(BudgetCategoryAdapter()) // typeId: 2
    ..registerAdapter(TransactionAdapter())    // typeId: 3
    ..registerAdapter(BankAdapter());          // typeId: 4
  // 박스 열기
  final catBox = await Hive.openBox<BudgetCategory>('categories');
  final bankBox = await Hive.openBox<Bank>('banks');

  // ─── 기본 카테고리 주입 ───
  if (catBox.isEmpty) {
    final defaults = _defaultCategories();
    for (final c in defaults) {
      final key = await catBox.add(c);
      c.id = key;
      await c.save();
    }
  }

  // ─── 기본 은행 목록 주입 ───
  if (bankBox.isEmpty) {
    final defaults = _defaultBanks();
    for (final b in defaults) {
      final key = await bankBox.add(b);
      b.id = key;
      await b.save();
    }
  }

  // ─ 처음 실행 시 기본 카테고리 주입 ─
  if (catBox.isEmpty) {
    final defaults = _defaultCategories();
    // addAll → key 자동 생성, 모델 id 필드도 함께 맞춰 줌
    for (final c in defaults) {
      final key = await catBox.add(c);
      c.id = key;
      await c.save();
    }
  }
  await Hive.openBox<BudgetItem>('budgetItems');
  await Hive.openBox<BudgetPeriod>('budgetPeriods');
  await Hive.openBox<Transaction>('transactions');

  runApp(MyApp(themeMode: themeMode));
  //runApp(const MyApp());
}

List<BudgetCategory> _defaultCategories() => [
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

List<Bank> _defaultBanks() => [
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

class MyApp extends StatefulWidget {
  final themeMode;

  const MyApp({
    Key? key,
    required this.themeMode,
  }) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // bool? isOnboardingComplete;

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,  // 내비게이션 바 투명화
    ));
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => ThemeProvider(initThemeMode: widget.themeMode)),
        ],
        builder: (context, _) {
          return MaterialApp(
            title: '헬미',
            themeMode: Provider.of<ThemeProvider>(context).themeMode,
            theme: ThemeCustom.lightTheme,
            darkTheme: ThemeCustom.darkTheme,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ko', '')],
            debugShowCheckedModeBanner: false,
            home: const BottomNavigation()
          );
        });
  }
}

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({Key? key}) : super(key: key);

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _selectedIndex = 0;
  final BottomNavigationBarType _bottomNavType = BottomNavigationBarType.fixed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getPageWidget(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: _bottomNavType,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: _bottomBarItems),
    );
  }

  Widget _getPageWidget(int index) {
    switch (index) {
      case 0:
        return const MainPage();
      case 1:
        return const BudgetPage();
      case 2:
        return const CalendarPage();
      case 3:
        return const SettingPage();
      default:
        return const MainPage();
    }
  }
}

const _bottomBarItems = [
  BottomNavigationBarItem(
    icon: Icon(Icons.home_outlined),
    activeIcon: Icon(Icons.home_rounded),
    label: '홈',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.pie_chart_outline),
    activeIcon: Icon(Icons.pie_chart_rounded),
    label: '예산',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.calendar_month_outlined),
    activeIcon: Icon(Icons.calendar_month_rounded),
    label: '캘린더',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.settings_outlined),
    activeIcon: Icon(Icons.settings),
    label: '설정',
  ),
];
