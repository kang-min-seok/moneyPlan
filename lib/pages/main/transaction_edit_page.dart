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
import '../budget/category_edit_page.dart';

class TransactionEditPage extends StatefulWidget {
  final Transaction tx;
  const TransactionEditPage({Key? key, required this.tx}) : super(key: key);

  @override
  State<TransactionEditPage> createState() => _TransactionEditPageState();
}

class _TransactionEditPageState extends State<TransactionEditPage> {
  final _periodBox = Hive.box<BudgetPeriod>('budgetPeriods');
  final _catBox    = Hive.box<BudgetCategory>('categories');
  final _txBox     = Hive.box<Transaction>('transactions');
  final _bankBox   = Hive.box<Bank>('banks');

  late DateTime _date;
  BudgetPeriod? _period;
  BudgetItem?   _item;
  Bank?         _bank;

  late String _type; // 'expense' | 'income'
  late TextEditingController _amtCtrl;
  late TextEditingController _memoCtrl;

  @override
  void initState() {
    super.initState();
    final tx = widget.tx;

    _date = tx.date;
    _type = tx.type;
    _amtCtrl  = TextEditingController(text: tx.amount.toString());
    _memoCtrl = TextEditingController(text: tx.memo);

    // 초기 period & item 매핑
    _period = _periodBox.values.firstWhereOrNull((p) => p.id == tx.periodId);
    if (_period != null && tx.budgetItemId != 0) {
      _item = _period!.items.firstWhereOrNull((it) => it.id == tx.budgetItemId);
    }

    // 초기 bank 매핑 (path에 저장된 은행명으로 찾아서)
    _bank = _bankBox.values.firstWhereOrNull((b) => b.name == tx.path);
  }

  void _resolvePeriodByDate() {
    final found = _periodBox.values.firstWhereOrNull((p) => p.contains(_date));
    if (found != _period) {
      setState(() {
        _period = found;
        _item = null;
      });
    }
  }

  Future<void> _save() async {
    final tx = widget.tx;
    final oldAmt = tx.amount;
    final newAmt = int.tryParse(_amtCtrl.text.replaceAll(',', '')) ?? 0;
    if (newAmt <= 0) return;

    _resolvePeriodByDate();
    if (_period == null) {
      _showErr('선택한 날짜에 편성된 예산이 없습니다');
      return;
    }
    if (_type == 'expense' && _item == null) {
      _showErr('예산 항목을 선택하세요');
      return;
    }

    // 1) 예전 지출분 보정
    if (tx.type == 'expense') {
      final oldItem = Hive.box<BudgetItem>('budgetItems').get(tx.budgetItemId);
      if (oldItem != null) {
        oldItem.spentAmount = (oldItem.spentAmount - oldAmt).clamp(0, 1<<31);
        oldItem.expenseTxs.remove(tx);
        await oldItem.save();
      }
    }

    // 2) tx 정보 업데이트
    tx
      ..date        = _date
      ..type        = _type
      ..amount      = newAmt
      ..memo        = _memoCtrl.text.trim()
      ..path        = _bank?.name ?? '모름'
      ..periodId    = _period!.id
      ..categoryId  = _type == 'expense' ? _item!.categoryId : 0
      ..budgetItemId= _type == 'expense' ? _item!.id : 0;
    await tx.save();

    // 3) 새 지출분 반영
    if (_type == 'expense') {
      final newItem = Hive.box<BudgetItem>('budgetItems').get(_item!.id);
      if (newItem != null) {
        newItem.spentAmount += newAmt;
        newItem.expenseTxs.add(tx);
        await newItem.save();
      }
    }

    Navigator.pop(context);
  }

  void _showErr(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final themes = Theme.of(context);

    return DefaultTabController(
      length: 2,
      initialIndex: _type=='expense'?0:1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('지출/수입 수정'),
          bottom: TabBar(
            dividerColor: themes.dividerColor,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorColor: colors.primary,
            unselectedLabelColor: colors.onSurface.withOpacity(0.6),
            labelStyle: themes.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold, fontSize: 16),
            onTap: (i)=> setState(()=>_type=i==0?'expense':'income'),
            tabs: const [ Tab(text:'지출'), Tab(text:'수입') ],
          ),
        ),
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    _resolvePeriodByDate();
    return SafeArea(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                children:[
                  Expanded(child: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[
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
                          const SizedBox(height: 24),
                          Text(
                            _type == 'expense' ? '지출명' : '수입명',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500
                            ),
                          ),
                          /* 메모 입력 */
                          TextField(
                            controller: _memoCtrl,
                            decoration: InputDecoration(
                              hintText: _type == 'expense' ? '지출명을 입력해주세요' : '수입명을 입력해주세요',
                              isDense: true,
                              contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '금액',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500
                            ),
                          ),
                          /* 금액 입력 */
                          TextField(
                            controller: _amtCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '금액을 입력해주세요',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 24),

                          /* 예산 항목 선택 */
                          if (_type == 'expense') ...[
                            Text(
                              '예산 항목',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500
                              ),
                            ),

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


                            Text(
                              '지출 경로',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500
                              ),
                            ),
                            /* 은행 선택 */
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
                        ]
                    ),
                  )),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      child: Text('수정 완료', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),),
                    ),
                  ),
                ]
            )
        )
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
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BankEditPage(),
                        ),
                      );
                    },
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
}
