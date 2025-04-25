// lib/pages/transaction/transaction_add_page.dart
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:money_plan/pages/main/bank_edit_page.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../componenets/icon_map.dart';
import '../../models/bank.dart';
import '../../models/budget_period.dart';
import '../../models/budget_item.dart';
import '../../models/budget_category.dart';
import '../../models/transaction.dart';
import '../budget/categort_edit_page.dart';

class TransactionAddPage extends StatefulWidget {
  const TransactionAddPage({super.key});

  @override
  State<TransactionAddPage> createState() => _TransactionAddPageState();
}

class _TransactionAddPageState extends State<TransactionAddPage> {
  final _periodBox = Hive.box<BudgetPeriod>('budgetPeriods');
  final _catBox = Hive.box<BudgetCategory>('categories');
  final _txBox = Hive.box<Transaction>('transactions');
  final _bankBox = Hive.box<Bank>('banks');

  DateTime _date = DateTime.now();
  BudgetPeriod? _period;
  BudgetItem? _item;
  Bank? _bank;

  String _type = 'expense'; // 'expense' | 'income'
  final _amtCtrl = TextEditingController();
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
    if (_bank == null) {
      _showErr('은행을 선택하세요');
      return;
    }

    if (_period == null) {
      _showErr('선택한 날짜에 편성된 예산이 없습니다');
      return;
    }
    if (_type == 'expense' && _item == null) {
      _showErr('예산 항목을 선택하세요');
      return;
    }

    final tx = Transaction(
      id: 0,
      date: _date,
      type: _type,
      amount: amt,
      categoryId: _type == 'expense' ? _item!.categoryId : 0,
      memo: _memoCtrl.text.trim(),
      path: _bank!.name,
      periodId: _period!.id,
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
    final colors = Theme.of(context).colorScheme;
    final themes = Theme.of(context);

    return DefaultTabController(
      length: 2,
      initialIndex: _type == 'expense' ? 0 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('소비/수익 추가'),
          bottom: TabBar(
            dividerColor: themes.dividerColor,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorColor: colors.primary,
            unselectedLabelColor: colors.onSurface.withOpacity(0.6),
            labelStyle: themes.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            unselectedLabelStyle: themes.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
            onTap: (index) {
              setState(() {
                _type = index == 0 ? 'expense' : 'income';
              });
            },
            tabs: const [
              Tab(text: '지출'),
              Tab(text: '수입'),
            ],
          ),
        ),
        body: _buildBody(context), // body 따로 분리
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    _resolvePeriodByDate();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            //  스크롤 가능한 입력 필드
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    /* 날짜 선택 */
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.calendar_month_rounded),
                        title: Text(
                          DateFormat('yyyy.MM.dd').format(_date),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: _period == null
                            ? const Text(
                                '이 날짜에는 예산이 없습니다',
                                style: TextStyle(color: Colors.red),
                              )
                            : null,
                        trailing: const Icon(Icons.expand_more_rounded),
                        onTap: _pickSingleDate,
                      ),
                    ),
                    const SizedBox(height: 12),

                    /* 메모 입력 */
                    TextField(
                      controller: _memoCtrl,
                      decoration: InputDecoration(
                        hintText: _type == 'expense' ? '지출명' : '수입명',
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),

                    /* 금액 입력 */
                    TextField(
                      controller: _amtCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '금액 (원)',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),

                    /* 예산 항목 선택 */
                    if (_type == 'expense') ...[
                      GestureDetector(
                        onTap: () async {
                          if (_period == null) return;
                          final selected = await _showItemPicker();
                          if (selected != null) {
                            setState(() => _item = selected);
                          }
                        },
                        child: InputDecorator(
                          isEmpty: _item == null,
                          decoration: const InputDecoration(
                            hintText: '예산 항목 선택',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _item == null
                                    ? ''
                                    : _catBox.get(_item!.categoryId)?.name ??
                                        '',
                                style: const TextStyle(fontSize: 17),
                              ),
                              const Icon(Icons.expand_more_rounded),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    /* 은행 선택 */
                    if (_type == 'expense') ...[
                      GestureDetector(
                        onTap: () async {
                          final selected = await _showBankPicker();
                          if (selected != null) {
                            setState(() => _bank = selected);
                          }
                        },
                        child: InputDecorator(
                          isEmpty: _bank == null,
                          decoration: const InputDecoration(
                            hintText: '지출 은행 선택',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _bank?.name ?? '',
                                style: const TextStyle(fontSize: 17),
                              ),
                              const Icon(Icons.expand_more_rounded),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // 🔹 아래 고정된 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('저장'),
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSingleDate() async {
    DateTime? picked = _date;

    final result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets,
          child: FractionallySizedBox(
            heightFactor: 0.7,
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text('날짜 선택',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  child: SfDateRangePicker(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    selectionMode: DateRangePickerSelectionMode.single,
                    initialSelectedDate: _date,
                    headerStyle: DateRangePickerHeaderStyle(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      textStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    headerHeight: 80,
                    showActionButtons: false,
                    onSelectionChanged: (args) {
                      if (args.value is DateTime) {
                        picked = args.value;
                      }
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(ctx).padding.bottom + 20),
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          child: const Text('확인'),
                          onPressed: () => Navigator.pop(ctx, picked),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() => _date = result);
    }
  }

  Future<BudgetItem?> _showItemPicker() async {
    final items = _period?.items ?? [];

    return showModalBottomSheet<BudgetItem>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Row(
                children: [
                  const Text('예산 항목 선택',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                ],
              ),
            ),
            SizedBox(
              height: 350,
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(),
                itemBuilder: (_, i) {
                  final it = items[i];
                  final cat = _catBox.get(it.categoryId);
                  final iconData = iconMap[cat?.iconKey] ?? Icons.help_outline;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(cat?.colorValue ?? 0xFF888888),
                      child: Icon(iconData, color: Colors.white),
                    ),
                    title: Text(cat?.name ?? '—'),
                    onTap: () => Navigator.pop(ctx, it),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Bank?> _showBankPicker() async {
    final banks = _bankBox.values.toList();
    return showModalBottomSheet<Bank>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Row(
                children: [
                  const Text('지출 은행 선택',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BankEditPage(),
                      ),
                    ),
                    child: const Text('편집'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 350,
              child: ListView.separated(
                itemCount: banks.length,
                separatorBuilder: (_, __) => const SizedBox(),
                itemBuilder: (_, i) {
                  final b = banks[i];
                  return ListTile(
                    leading: Image.asset(
                      b.imagePath,
                      width: 45,
                      height: 45,
                      fit: BoxFit.cover,
                    ),
                    title: Text(b.name),
                    onTap: () => Navigator.pop(ctx, b),
                  );
                },
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
