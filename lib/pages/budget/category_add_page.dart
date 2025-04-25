// lib/pages/category/category_add_page.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:money_plan/models/budget_category.dart';
import 'package:money_plan/componenets/icon_map.dart'; // 미리 정의된 iconMap

class CategoryAddPage extends StatefulWidget {
  const CategoryAddPage({Key? key}) : super(key: key);

  @override
  State<CategoryAddPage> createState() => _CategoryAddPageState();
}

class _CategoryAddPageState extends State<CategoryAddPage> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // 선택된 아이콘 키, 색상
  String _iconKey = iconMap.keys.first;
  Color _color = Colors.primaries[Random().nextInt(Colors.primaries.length)];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _pickIcon() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true, // 그대로 두되…
      builder: (ctx) {
        return FractionallySizedBox(
          // 화면 높이의 60%만 차지하도록
          heightFactor: 0.6,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 0),
              child: GridView.count(
                crossAxisCount: 5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                padding: const EdgeInsets.all(16),
                children: iconMap.entries.map((e) {
                  return GestureDetector(
                    onTap: () => Navigator.pop(ctx, e.key),
                    child: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      child: Icon(e.value, color: Colors.black54),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() => _iconKey = selected);
    }
  }

  void _pickColor() async {
    final colors = <Color>[
      Colors.red, Colors.pink, Colors.purple,
      Colors.indigo, Colors.blue, Colors.cyan,
      Colors.teal, Colors.green, Colors.lime,
      Colors.amber, Colors.orange, Colors.brown,
      Colors.grey,
    ];
    final selected = await showModalBottomSheet<Color>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: 200,
            child: GridView.count(
              crossAxisCount: 6,
              padding: const EdgeInsets.all(16),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: colors.map((c) {
                return GestureDetector(
                  onTap: () => Navigator.pop(context, c),
                  child: Container(
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() => _color = selected);
    }
  }

  void _randomColor() {
    setState(() {
      _color = Colors.primaries[Random().nextInt(Colors.primaries.length)];
    });
  }

  Future<void> _createCategory() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카테고리 이름을 입력하세요')),
      );
      return;
    }

    final box = Hive.box<BudgetCategory>('categories');
    final cat = BudgetCategory(
      id: 0,
      name: name,
      iconKey: _iconKey,
      colorValue: _color.value,
    );
    final key = await box.add(cat);
    cat.id = key;
    await cat.save();

    Navigator.pop(context, cat);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconData = iconMap[_iconKey]!;
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('지출 카테고리 추가'),
      ),
      body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 1) 아이콘 선택
                GestureDetector(
                  onTap: _pickIcon,
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: _color,
                    child: Icon(iconData, size: 32, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text('아이콘을 눌러 선택', style: theme.textTheme.bodySmall),

                const SizedBox(height: 24),

                // 2) 이름 입력
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '카테고리 이름',
                    border: UnderlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),


                // 4) 색상 랜덤 / 직접 선택
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _randomColor,
                        child: const Text('랜덤 색상', style: TextStyle( fontWeight: FontWeight.bold),),
                      ),
                    ),
                    SizedBox(width: 5,),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _pickColor,
                        child: const Text('색상 선택', style: TextStyle( fontWeight: FontWeight.bold)),
                      ),
                    )

                  ],
                ),

                const Spacer(),

                // 5) 최종 저장
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _createCategory,
                    child: const Text('카테고리 생성', style: TextStyle( fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
      )


    );
  }
}
