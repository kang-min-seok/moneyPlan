// lib/pages/category/category_edit_page.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// TODO: 나중에 실제 구현될 카테고리 추가 페이지로 교체하세요
import './category_add_page.dart';
import 'package:money_plan/componenets/icon_map.dart';
import 'package:money_plan/models/budget_category.dart';

class CategoryEditPage extends StatefulWidget {
  const CategoryEditPage({Key? key}) : super(key: key);

  @override
  State<CategoryEditPage> createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends State<CategoryEditPage> {
  late Box<BudgetCategory> _catBox;
  late List<BudgetCategory> _cats;

  @override
  void initState() {
    super.initState();
    _catBox = Hive.box<BudgetCategory>('categories');
    _cats = _catBox.values.toList();
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _cats.removeAt(oldIndex);
      _cats.insert(newIndex, item);
    });
    // Hive에도 순서대로 다시 저장
    await _catBox.clear();
    for (final c in _cats) {
      final key = await _catBox.add(c);
      c.id = key;
      await c.save();
    }
  }

  void _deleteCategory(int index) async {
    final toDelete = _cats[index];
    await _catBox.delete(toDelete.id);
    setState(() => _cats.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: BackButton(),
        title: const Text('카테고리 편집'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '카테고리 추가',
            onPressed: () async {
              // AddPage 를 띄우고, pop 할 때 넘긴 cat 을 받아옵니다.
              final BudgetCategory? newCat =
                  await Navigator.push<BudgetCategory?>(
                context,
                MaterialPageRoute(builder: (_) => const CategoryAddPage()),
              );
              if (newCat != null) {
                setState(() {
                  // 로컬 리스트에도 바로 추가
                  _cats.insert(0, newCat);
                });
              }
            },
          ),
        ],
      ),
      body: ReorderableListView.builder(
        onReorder: _onReorder,
        itemCount: _cats.length,
        buildDefaultDragHandles: false,
        itemBuilder: (context, index) {
          final cat = _cats[index];
          final iconData = iconMap[cat.iconKey] ?? Icons.category;
          return ListTile(
            key: ValueKey(cat.id),
            leading: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => _deleteCategory(index),
            ),
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(cat.colorValue),
                  child: Icon(iconData, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(cat.name, style: const TextStyle(fontSize: 16)),
              ],
            ),
            trailing: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
          );
        },
      ),
    );
  }
}
