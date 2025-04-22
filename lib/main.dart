import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:money_plan/theme/theme_provider.dart';
import 'package:money_plan/theme/theme_custom.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './pages/main/main_page.dart';
import './pages/calendar/calendar_page.dart';
import './pages/temp1/temp_page1.dart';
import './pages/temp2/temp_page2.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    // _checkOnboarding();
  }

  // void _checkOnboarding() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     isOnboardingComplete = prefs.getBool('onboarding_complete') ?? false;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // if (isOnboardingComplete == null) {
    //   return const MaterialApp(
    //     home: Scaffold(
    //       body: Center(child: CircularProgressIndicator()), // 초기화 중 로딩 인디케이터
    //     ),
    //   );
    // }

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
        return const TempPage2();
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
    icon: Icon(Icons.timer_outlined),
    activeIcon: Icon(Icons.timer_rounded),
    label: '타이머',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.settings_outlined),
    activeIcon: Icon(Icons.settings),
    label: '설정',
  ),
];
