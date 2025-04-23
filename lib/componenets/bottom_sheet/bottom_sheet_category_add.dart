// lib/pages/budget/category_editor_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hive/hive.dart';

import '../../models/budget_category.dart';

class BottomSheetCategoryAdd extends StatefulWidget {
  const BottomSheetCategoryAdd({super.key});

  @override
  State<BottomSheetCategoryAdd> createState() => _BottomSheetCategoryAddState();
}

class _BottomSheetCategoryAddState extends State<BottomSheetCategoryAdd> {
  final _nameCtrl = TextEditingController();
  final _iconCtrl = TextEditingController(text: 'mdiFood'); // 임시 기본값
  Color _picked = const Color(0xFF198CFF);

  final _box = Hive.box<BudgetCategory>('categories');

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;

    final cat = BudgetCategory(
      id: 0,                                 // 임시값
      name: _nameCtrl.text.trim(),
      iconKey: _iconCtrl.text.trim(),
      colorValue: _picked.value,
    );

    final key = await _box.add(cat);        // Hive가 안전한 key 생성
    cat.id = key;                           // 모델에도 반영
    await cat.save();                       // 필드 변경 저장

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '카테고리 이름'),
            ),
            TextField(
              controller: _iconCtrl,
              decoration: const InputDecoration(labelText: '아이콘 key'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('색상'),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () async {
                    final c = await showDialog<Color>(
                      context: context,
                      builder: (_) => AlertDialog(
                        content: SingleChildScrollView(
                          child: MaterialPicker(
                            pickerColor: _picked,
                            onColorChanged: (c) => _picked = c,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, _picked),
                            child: const Text('확인'),
                          ),
                        ],
                      ),
                    );
                    if (c != null) setState(() => _picked = c);
                  },
                  child: CircleAvatar(backgroundColor: _picked),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _save,
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }
}
