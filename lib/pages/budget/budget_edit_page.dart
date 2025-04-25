import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../models/budget_period.dart';
import '../../models/budget_item.dart';
import '../../models/budget_category.dart';
import '../../componenets/icon_map.dart';
import '../../models/transaction.dart';
import 'category_edit_page.dart';

class BudgetEditPage extends StatefulWidget {
  final BudgetPeriod period;
  const BudgetEditPage({Key? key, required this.period}) : super(key: key);

  @override
  State<BudgetEditPage> createState() => _BudgetEditPageState();
}

class _BudgetEditPageState extends State<BudgetEditPage> {
  final _catBox    = Hive.box<BudgetCategory>('categories');
  final _itemBox   = Hive.box<BudgetItem>('budgetItems');
  final _periodBox = Hive.box<BudgetPeriod>('budgetPeriods');

  DateTime? _start, _end;
  bool _dateMissing = false, _rangeOverlap = false;

  late List<_EditItem> _draft;
  bool _showItemErrors = false;
  bool get _emptyItems => _draft.every((d) => !d.isComplete);

  @override
  void initState() {
    super.initState();
    // 1) 초기 날짜
    _start = widget.period.startDate;
    _end   = widget.period.endDate;

    // 2) 기존 BudgetItem 들을 편집용 Draft 로 복사
    _draft = widget.period.items.map((it) {
      return _EditItem(
        id:         it.id,
        categoryId: it.categoryId,
        limit:      it.limitAmount,
      );
    }).toList();
    // 하나도 없으면 빈 칸 하나
    if (_draft.isEmpty) _draft.add(_EditItem());
  }

  // ────────────────────────────────────────────────────────
  // 날짜 선택 BottomSheet (range)
  Future<void> _pickDateRange() async {
    final result = await showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        DateTime? s = _start, e = _end;
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets,
          child: FractionallySizedBox(
            heightFactor: .8,
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text('기간 선택',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  child: SfDateRangePicker(
                    selectionMode: DateRangePickerSelectionMode.range,
                    initialSelectedRange: (s != null && e != null)
                        ? PickerDateRange(s, e)
                        : null,
                    headerStyle: DateRangePickerHeaderStyle(
                      textStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    headerHeight: 80,
                    showActionButtons: false,
                    onSelectionChanged: (a) {
                      if (a.value is PickerDateRange) {
                        s = (a.value as PickerDateRange).startDate;
                        e = (a.value as PickerDateRange).endDate;
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
                          onPressed: () => Navigator.pop(
                              ctx,
                              (s != null && e != null)
                                  ? DateTimeRange(start: s!, end: e!)
                                  : null),
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
      _start = result.start;
      _end   = result.end;
      _validateDates();
    }
  }

  bool _periodClashes(DateTime s, DateTime e) {
    for (final p in _periodBox.values) {
      if (p.id == widget.period.id) continue;
      if (!e.isBefore(p.startDate) && !s.isAfter(p.endDate)) return true;
    }
    return false;
  }

  bool _validateDates() {
    _dateMissing  = _start == null || _end == null;
    _rangeOverlap = !_dateMissing && _periodClashes(_start!, _end!);
    setState(() {});
    return !_dateMissing && !_rangeOverlap;
  }

  bool _validateAll() {
    _showItemErrors = true;
    final ok = _validateDates() && !_emptyItems;
    setState(() {});
    return ok;
  }

  Future<void> _save() async {
    if (!_validateAll()) return;

       // 1) 제거된 아이템 및 연관 트랜잭션 삭제
       final txBox = Hive.box<Transaction>('transactions');
       final removedIds = widget.period.items
           .map((it) => it.id)
           .where((oldId) => !_draft.any((d) => d.id == oldId));
       for (final itemId in removedIds) {
         // 1-a) 이 기간에 속한, 해당 아이템의 트랜잭션부터 삭제
         final toDeleteTxs = txBox.values
             .where((tx) =>
                 tx.budgetItemId == itemId &&
                 tx.periodId == widget.period.id)
             .toList();
         for (final tx in toDeleteTxs) {
           await txBox.delete(tx.key);
         }
         // 1-b) 이제 예산 아이템 자체 삭제
         await _itemBox.delete(itemId);
       }

    // 2) 업데이트 / 생성된 아이템
    final List<BudgetItem> newItems = [];
    for (final d in _draft.where((d) => d.isComplete)) {
      if (d.id != null) {
        // 기존
        final exist = _itemBox.get(d.id!);
        exist!
          ..limitAmount = d.limit
          ..categoryId  = d.categoryId!; // 카테고리 변경도 가능
        await exist.save();
        newItems.add(exist);
      } else {
        // 신규
        final cat = _catBox.get(d.categoryId!);
        final item = BudgetItem(
          id:         0,
          categoryId: d.categoryId!,
          limitAmount:d.limit,
          iconKey:    cat?.iconKey ?? '',
          spentAmount:0,
          // expenseTxs: HiveList(_itemBox, objects: []),
        );
        final key = await _itemBox.add(item);
        item.id = key;
        await item.save();
        newItems.add(item);
      }
    }

    // 3) 기간 정보 업데이트
    widget.period
      ..startDate = _start!
      ..endDate   = _end!
      ..items     = HiveList(_itemBox, objects: newItems);
    await widget.period.save();

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('예산 수정')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _rangeButton(),
              if (_rangeOverlap)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('다른 예산 기간과 겹칩니다',
                      style: TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _draft.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    if (i == _draft.length) {
                      return Center(
                        child: GestureDetector(
                          onTap: () => setState(() => _draft.add(_EditItem())),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('예산 추가', style: TextStyle(fontSize: 17)),
                              SizedBox(width: 5),
                              Icon(Icons.add_rounded),
                            ],
                          ),
                        ),
                      );
                    }
                    final d   = _draft[i];
                    final err = _showItemErrors && !d.isComplete;
                    return Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _categoryField(
                            selectedId: d.categoryId,
                            hasErr: err && d.categoryId == null,
                            onPicked: (id) =>
                                setState(() => d.categoryId = id),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _amountField(
                            controller: d.amtCtrl,
                            hasErr: err && d.limit <= 0,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _draft.removeAt(i)),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (_emptyItems)
                const Text('예산 항목을 하나 이상 추가하세요',
                    style: TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text('수정 완료', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rangeButton() {
    final hasErr = _dateMissing || _rangeOverlap;
    final lbl = (_start == null || _end == null)
        ? '기간 선택'
        : '${DateFormat('yyyy.MM.dd').format(_start!)}'
        ' ~ ${DateFormat('yyyy.MM.dd').format(_end!)}';
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
            color: hasErr
                ? Colors.red
                : Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: const Icon(Icons.calendar_month_rounded),
        title: Text(lbl,
            style: TextStyle(
                color: hasErr ? Colors.red : null,
                fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.expand_more_rounded),
        onTap: _pickDateRange,
      ),
    );
  }

  Widget _categoryField({
    required int? selectedId,
    required bool hasErr,
    required ValueChanged<int> onPicked,
  }) {
    final sel = _catBox.get(selectedId);
    return InkWell(
      onTap: () async {
        final id = await _showCategoryPicker();
        if (id != null) onPicked(id);
      },
      child: InputDecorator(
        isEmpty: sel?.name == null,
        decoration: InputDecoration(
          hintText: '예산',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
                color: hasErr
                    ? Colors.red
                    : Theme.of(context).colorScheme.outline),
          ),
          suffixIcon: const Icon(Icons.expand_more_rounded),
        ),
        child: Text(sel?.name ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _amountField({
    required TextEditingController controller,
    required bool hasErr,
    required ValueChanged<String> onChanged,
  }) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        InputDecorator(
          isEmpty: controller.text.isEmpty,
          decoration: InputDecoration(
            hintText: '금액',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                  color: hasErr
                      ? Colors.red
                      : Theme.of(context).colorScheme.outline),
            ),
          ),
          child: const SizedBox.shrink(),
        ),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: onChanged,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Future<int?> _showCategoryPicker() {
    return showModalBottomSheet<int>(
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
                  const Text('카테고리 선택',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CategoryEditPage(),
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
                itemCount: _catBox.length,
                separatorBuilder: (_, __) => const SizedBox(),
                itemBuilder: (_, i) {
                  final c = _catBox.getAt(i)!;
                  final iconData = iconMap[c.iconKey] ?? Icons.help_outline;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(c.colorValue),
                      child: Icon(iconData, color: Colors.white),
                    ),
                    title: Text(c.name),
                    onTap: () => Navigator.pop(ctx, c.id),
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

/// 편집용 임시 모델
class _EditItem {
  final int? id;
  int? categoryId;
  final TextEditingController amtCtrl;

  _EditItem({this.id, int? categoryId, int? limit})
      : categoryId = categoryId,
        amtCtrl = TextEditingController(
            text: limit != null ? limit.toString() : '');
  int get limit => int.tryParse(amtCtrl.text) ?? 0;
  bool get isComplete => categoryId != null && limit > 0;
}
