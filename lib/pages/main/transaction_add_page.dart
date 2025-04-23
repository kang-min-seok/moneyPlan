// lib/pages/transaction/transaction_add_page.dart
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/budget_period.dart';
import '../../models/budget_item.dart';
import '../../models/budget_category.dart';
import '../../models/transaction.dart';

class TransactionAddPage extends StatefulWidget {
  const TransactionAddPage({super.key});
  @override
  State<TransactionAddPage> createState() => _TransactionAddPageState();
}

class _TransactionAddPageState extends State<TransactionAddPage> {
  final _periodBox = Hive.box<BudgetPeriod>('budgetPeriods');
  final _catBox    = Hive.box<BudgetCategory>('categories');
  final _txBox     = Hive.box<Transaction>('transactions');

  DateTime _date   = DateTime.now();
  BudgetPeriod? _period;
  BudgetItem?   _item;

  String  _type   = 'expense';      // 'expense' | 'income'
  final _amtCtrl  = TextEditingController();
  final _memoCtrl = TextEditingController();

  /*──────── 날짜 → 기간 매핑 ────────*/
  void _resolvePeriodByDate() {
    final found = _periodBox.values.firstWhereOrNull((p) => p.contains(_date));
    if (found != _period) {
      _period = found;
      if (_item == null || _period == null || !_period!.items.contains(_item)) {
        _item = null;
      }
    }
  }

  /*──────── 저장 ────────*/
  Future<void> _save() async {
    final amt = int.tryParse(_amtCtrl.text.replaceAll(',', '')) ?? 0;
    if (amt <= 0) return;

    _resolvePeriodByDate();
    if (_period == null) {
      _showErr('선택한 날짜에 편성된 예산이 없습니다');
      return;
    }
    if (_type == 'expense' && _item == null) {
      _showErr('예산 항목을 선택하세요');
      return;
    }

    final tx = Transaction(
      id          : 0,
      date        : _date,
      type        : _type,
      amount      : amt,
      categoryId  : _type == 'expense' ? _item!.categoryId : 0,
      memo        : _memoCtrl.text.trim(),
      periodId    : _period!.id,
      budgetItemId: _type == 'expense' ? _item!.id : 0,
    );
    final key = await _txBox.add(tx);
    tx.id = key;
    await tx.save();

    // 지출이면 spentAmount 갱신
    if (_type == 'expense') {
      _item!
        ..spentAmount += amt
        ..expenseTxs.add(tx);
      await _item!.save();
    }

    if (mounted) Navigator.pop(context);
  }

  void _showErr(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  /*──────── UI ────────*/
  @override
  Widget build(BuildContext context) {
    _resolvePeriodByDate();
    final amtFmt = NumberFormat('#,##0', 'ko');

    return Scaffold(
      appBar: AppBar(title: const Text('소비/수익 추가')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            /*── 날짜 선택 ─*/
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title : Text(DateFormat('yyyy.MM.dd').format(_date)),
              subtitle: _period == null
                  ? const Text('이 날짜에는 예산이 없습니다',
                  style: TextStyle(color: Colors.red))
                  : null,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(_date.year - 5),
                  lastDate : DateTime(_date.year + 5),
                  locale   : const Locale('ko'),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const Divider(),

            /*── 지출/수입 토글 ─*/
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('지출'), icon: Icon(Icons.remove)),
                ButtonSegment(value: 'income',  label: Text('수입'), icon: Icon(Icons.add)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),

            /*── 예산 항목 드롭다운 (지출일 때만) ─*/
            if (_type == 'expense') ...[
              DropdownButtonFormField<BudgetItem>(
                value: _item,
                hint : const Text('예산 항목 선택'),
                items: (_period?.items ?? [])
                    .map<DropdownMenuItem<BudgetItem>>((it) {
                  final cat = _catBox.get(it.categoryId);
                  return DropdownMenuItem(
                    value: it,
                    child: Text(cat?.name ?? '—'),
                  );
                }).toList(),
                onChanged: _period == null
                    ? null
                    : (v) => setState(() => _item = v),
              ),
              const SizedBox(height: 12),
            ],



            /*── 금액 입력 ─*/
            TextField(
              controller: _amtCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '금액 (원)'),
            ),
            const SizedBox(height: 12),

            /*── 메모 입력 ─*/
            TextField(
              controller: _memoCtrl,
              decoration: const InputDecoration(labelText: '메모 (선택)'),
            ),
            const SizedBox(height: 24),

            /*── 저장 버튼 ─*/
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon : const Icon(Icons.save),
                label: const Text('저장'),
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amtCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }
}
