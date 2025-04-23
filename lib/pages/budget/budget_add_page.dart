// lib/pages/budget_setup_page.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/budget_period.dart';
import '../../models/budget_item.dart';
import '../../models/budget_category.dart';

import 'package:money_plan/componenets/bottom_sheet/bottom_sheet_category_add.dart';

import '../../models/transaction.dart';

class BudgeAddPage extends StatefulWidget {
  const BudgeAddPage({super.key});

  @override
  State<BudgeAddPage> createState() => _BudgeAddPageState();
}

class _BudgeAddPageState extends State<BudgeAddPage> {
  final _catBox   = Hive.box<BudgetCategory>('categories');
  final _itemBox  = Hive.box<BudgetItem>('budgetItems');
  final _periodBox= Hive.box<BudgetPeriod>('budgetPeriods');

  DateTime? _start;
  DateTime? _end;

  bool _dateMissing = false;       // 시작·종료일 중 하나라도 비었을 때
  bool _rangeOverlap = false;      // 기존 예산과 기간이 겹칠 때
  bool _emptyItems   = false;      // 항목을 하나도 안 넣었을 때

  bool _periodClashes(DateTime s, DateTime e) {
    for (final p in _periodBox.values) {
      final overlap = !e.isBefore(p.startDate) && !s.isAfter(p.endDate);
      if (overlap) return true;
    }
    return false;
  }

  bool _validate() {
    _dateMissing = _start == null || _end == null;
    _emptyItems  = _draft.isEmpty;
    _rangeOverlap =
        !_dateMissing && _periodClashes(_start!, _end!);

    setState(() {});          // UI에 빨간 테두리 반영
    return !(_dateMissing || _emptyItems || _rangeOverlap);
  }

  final List<_TempItem> _draft = [];          // 입력 중인 BudgetItem 목록
  final _amtCtrl = TextEditingController();
  int? _selectedCatId;

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_start ?? now) : (_end ?? now),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('ko'),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
          if (_end != null && _end!.isBefore(_start!)) _end = _start;
        } else {
          _end = picked;
          if (_start != null && _end!.isBefore(_start!)) _start = _end;
        }
      });
    }
  }

  void _addTemp() {
    final amt = int.tryParse(_amtCtrl.text.replaceAll(',', '')) ?? 0;
    if (amt <= 0 || _selectedCatId == null) return;
    setState(() {
      _draft.add(_TempItem(categoryId: _selectedCatId!, limit: amt));
      _amtCtrl.clear();
      _selectedCatId = null;
    });
  }

  Future<void> _save() async {
    debugPrintBudgetHive();
    if (!_validate()) return;

    // ───── 1) BudgetItem 저장
    final List<BudgetItem> newItems = [];
    for (final d in _draft) {
      final item = BudgetItem(
        id          : 0,                 // placeholder
        categoryId  : d.categoryId,
        limitAmount : d.limit,
        spentAmount : 0,
        iconKey     : '',                // 필요 없으면 모델에서 제거
      );

      final key = await _itemBox.add(item); // Hive가 key 생성 (≤ 0xFFFFFFFF)
      item.id = key;                        // 모델에도 반영
      await item.save();                    // 필드 변경 저장

      newItems.add(item);
    }

    // ───── 2) BudgetPeriod 저장
    final period = BudgetPeriod(
      id        : 0,                       // placeholder
      startDate : _start!,
      endDate   : _end!,
      items     : HiveList(_itemBox, objects: newItems),
    );

    final pKey = await _periodBox.add(period);
    period.id = pKey;
    await period.save();

    if (mounted) Navigator.pop(context);
  }

  Future<void> _showCategoryEditor() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const BottomSheetCategoryAdd(),
    );
    setState(() {}); // 새 카테고리 반영
  }

  Future<void> debugPrintBudgetHive() async {
    final catBox   = Hive.box<BudgetCategory>('categories');
    final itemBox  = Hive.box<BudgetItem>('budgetItems');
    final periodBox= Hive.box<BudgetPeriod>('budgetPeriods');
    final txBox    = Hive.box<Transaction>('transactions');

    debugPrint('─── BudgetCategory (${catBox.length}) ───');
    for (var c in catBox.values) {
      debugPrint('[${c.id}]  ${c.name}  icon:${c.iconKey}  color:${c.colorValue.toRadixString(16)}');
    }

    debugPrint('─── BudgetItem (${itemBox.length}) ───');
    for (var i in itemBox.values) {
      debugPrint('[${i.id}]  cat:${i.categoryId}  limit:${i.limitAmount}  spent:${i.spentAmount}');
    }

    debugPrint('─── BudgetPeriod (${periodBox.length}) ───');
    for (var p in periodBox.values) {
      debugPrint('[${p.id}]  ${p.startDate} ~ ${p.endDate}  items:${p.items.map((e) => e.id).join(",")}');
    }

    debugPrint('─── Transaction (${txBox.length}) ───');
    for (var t in txBox.values) {
      debugPrint('[${t.id}]  ${t.date}  type:${t.type}  amt:${t.amount}  cat:${t.categoryId}  item:${t.budgetItemId}');
    }
    debugPrint('──────────────────────────────────────');
  }

  @override
  void dispose() {
    _amtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy.MM.dd');
    final amtFmt = NumberFormat('#,##0', 'ko');
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.background,
          elevation: 0,
          title: const Text('예산 편성')
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 날짜 입력
            Row(
              children: [
                Expanded(child: _dateButton(true)),
                const SizedBox(width: 8),
                const Text('~'),
                const SizedBox(width: 8),
                Expanded(child: _dateButton(false)),
              ],
            ),
            if (_rangeOverlap)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '다른 예산 기간과 겹칩니다',
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
            // 예산 항목 입력
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int>(
                    value: _selectedCatId,
                    hint: const Text('카테고리'),
                    items: _catBox.values.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.name));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedCatId = v),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: '카테고리 추가',
                  onPressed: _showCategoryEditor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amtCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '예산 금액'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTemp,
                )
              ],
            ),
            const SizedBox(height: 16),
            // 임시 목록
            Expanded(
              child: ListView.separated(
                itemCount: _draft.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, i) {
                  final d = _draft[i];
                  final cat = _catBox.get(d.categoryId);
                  return ListTile(
                    leading: Icon(Icons.label, color: Color(cat?.colorValue ?? 0)),
                    title: Text(cat?.name ?? ''),
                    trailing: Text('${amtFmt.format(d.limit)} 원'),
                    onLongPress: () => setState(() => _draft.removeAt(i)),
                  );
                },
              ),
            ),
            if (_emptyItems)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '예산 항목을 하나 이상 추가하세요',
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateButton(bool isStart) {
    final date = isStart ? _start : _end;
    final hasErr = _dateMissing;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: hasErr ? Colors.red : Theme.of(context).colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextButton(
        onPressed: () => _pickDate(isStart),
        child: Text(
          date == null ? (isStart ? '시작일' : '종료일')
              : DateFormat('yyyy.MM.dd').format(date),
          style: TextStyle(color: hasErr ? Colors.red : null),
        ),
      ),
    );
  }

}

class _TempItem {
  final int categoryId;
  final int limit;
  _TempItem({required this.categoryId, required this.limit});
}