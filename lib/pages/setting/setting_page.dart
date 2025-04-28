import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../componenets/default_data.dart';
import '../../models/bank.dart';
import '../../models/budget_category.dart';
import '../../models/budget_item.dart';
import '../../models/budget_period.dart';
import '../../models/transaction.dart';
import 'design_setting_page.dart';
import './qr_export_page.dart';
import './qr_import_page.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  static String themeText = "기기 테마";

  @override
  void initState() {
    getThemeText();
    super.initState();
  }

  void getThemeText() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedThemeMode = prefs.getString('themeMode');

    if (savedThemeMode == null) {
      setState(() {
        themeText = "기기 테마";
      });
    } else if (savedThemeMode == "light") {
      setState(() {
        themeText = "밝은 테마";
      });
    } else if (savedThemeMode == "dark") {
      setState(() {
        themeText = "어두운 테마";
      });
    } else if (savedThemeMode == "system") {
      setState(() {
        themeText = "기기 테마";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text("설정"),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: ListView(
            children: [
              _SingleSection(
                title: "환경",
                children: [
                  _CustomListTile(
                    title: "테마",
                    icon: Icons.format_paint_outlined,
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DesignSettingPage()),
                      ).then((_) {
                        getThemeText();
                      });
                    },
                    trailing: Text(
                      themeText,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ],
              ),

              _SingleSection(
                title: "데이터 관리",
                children: [
                  _CustomListTile(
                    title: "qr로 내보내기",
                    icon: Icons.qr_code_2_outlined,
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const QrExportPage()),
                      );
                    },
                  ),

                  _CustomListTile(
                    title: "qr로 가져오기",
                    icon: Icons.qr_code_scanner_rounded,
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const QrImportPage()),
                      ).then((_) {
                        getThemeText();
                      });
                    },
                  ),

                  _CustomListTile(
                    title: "데이터 초기화하기",
                    icon: Icons.restore_outlined,
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("데이터 초기화"),
                          content: const Text(
                              "모든 데이터를 삭제하고 설치 직후 상태로 되돌립니다.\n계속하시겠습니까?"
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(_, false),
                              child: const Text("취소"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(_, true),
                              child: const Text("확인"),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;

                      // 1) 모든 Box clear
                      await Hive.box<BudgetPeriod>('budgetPeriods').clear();
                      await Hive.box<BudgetItem>('budgetItems').clear();
                      await Hive.box<Transaction>('transactions').clear();
                      // 카테고리·은행도 비우고 다시 주입
                      final catBox  = Hive.box<BudgetCategory>('categories');
                      final bankBox = Hive.box<Bank>('banks');
                      await catBox.clear();
                      await bankBox.clear();

                      // 2) 기본 데이터 주입
                      for (final c in defaultCategories()) {
                        final key = await catBox.add(c);
                        c.id = key;
                        await c.save();
                      }
                      for (final b in defaultBanks()) {
                        final key = await bankBox.add(b);
                        b.id = key;
                        await b.save();
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("데이터가 초기화되었습니다"))
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomListTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _CustomListTile({
    Key? key,
    required this.title,
    required this.icon,
    this.trailing,
    this.onTap, // onTap 추가
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      leading: Icon(icon),
      trailing: trailing,
      onTap: onTap, // onTap 할당
    );
  }
}

class _SingleSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  const _SingleSection({
    Key? key,
    this.title,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        Column(
          children: children,
        ),
      ],
    );
  }
}
