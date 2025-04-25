// lib/pages/bank/bank_edit_page.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:money_plan/pages/main/bank_add_page.dart';

import '../../models/bank.dart';

class BankEditPage extends StatefulWidget {
  const BankEditPage({Key? key}) : super(key: key);

  @override
  State<BankEditPage> createState() => _BankEditPageState();
}

class _BankEditPageState extends State<BankEditPage> {
  late Box<Bank> _bankBox;
  late List<Bank> _banks;

  @override
  void initState() {
    super.initState();
    _bankBox = Hive.box<Bank>('banks');
    _banks = _bankBox.values.toList();
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _banks.removeAt(oldIndex);
      _banks.insert(newIndex, item);
    });
    // 순서 변경을 Hive에 반영
    await _bankBox.clear();
    for (final b in _banks) {
      final key = await _bankBox.add(b);
      b.id = key;
      await b.save();
    }
  }

  void _deleteBank(int index) async {
    final toDelete = _banks[index];
    await _bankBox.delete(toDelete.id);
    setState(() => _banks.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: const Text('은행 편집'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '은행 추가',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BankAddPage(),
              ),
            ),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        onReorder: _onReorder,
        itemCount: _banks.length,
        buildDefaultDragHandles: false,
        itemBuilder: (context, index) {
          final bank = _banks[index];
          return ListTile(
            key: ValueKey(bank.id),
            leading: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => _deleteBank(index),
            ),
            title: Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(bank.imagePath),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Text(bank.name, style: const TextStyle(fontSize: 16)),
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
