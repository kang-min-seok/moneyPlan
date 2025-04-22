import 'package:flutter/material.dart';
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
import './pages/temp1/temp_page1.dart';
import './pages/setting/setting_page.dart';

import 'models/budget.dart';
import 'models/consumption.dart';

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
  Hive.registerAdapter(ConsumptionAdapter());
  Hive.registerAdapter(BudgetAdapter());

  // 박스 열기
  await Hive.openBox<Consumption>('consumptions');
  await Hive.openBox<Budget>('budgets');

  runApp(MyApp(themeMode: themeMode));
  //runApp(const MyApp());
}


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
        return const CalendarPage();
      case 2:
        return const TempPage1();
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
    icon: Icon(Icons.calendar_month_outlined),
    activeIcon: Icon(Icons.calendar_month_rounded),
    label: '캘린더',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.pie_chart_outline),
    activeIcon: Icon(Icons.pie_chart_rounded),
    label: '예산',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.settings_outlined),
    activeIcon: Icon(Icons.settings),
    label: '설정',
  ),
];
