// lib/pages/budget_setup_page.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../models/budget_period.dart';
import '../../models/budget_item.dart';
import '../../models/budget_category.dart';
import '../../models/transaction.dart';

import 'category_edit_page.dart';
import '../../componenets/icon_map.dart';

class BudgeAddPage extends StatefulWidget {
  const BudgeAddPage({super.key});
  @override
  State<BudgeAddPage> createState() => _BudgeAddPageState();
}

/*───────────────────────────────────────────────────────────────*/
class _BudgeAddPageState extends State<BudgeAddPage> {
  /* ─ Hive box ─ */
  final _catBox    = Hive.box<BudgetCategory>('categories');
  final _itemBox   = Hive.box<BudgetItem>('budgetItems');
  final _periodBox = Hive.box<BudgetPeriod>('budgetPeriods');

  /* ─ 기간 선택 ─ */
  DateTime? _start, _end;
  bool _dateMissing = false, _rangeOverlap = false;

  /* ─ 임시 BudgetItem 입력 목록 ─ */
  final List<_TempItem> _draft = [ _TempItem() ];   // 첫 칸 미리 생성

  /* ─ 검증 플래그 ─ */
  bool get _emptyItems => _draft.every((d) => !d.isComplete);

  bool _showItemErrors = false;

  /*───────────────────────────────────────────────────────────*/
  /*                        날짜 bottom-sheet                   */
  /*───────────────────────────────────────────────────────────*/
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
                    style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                Expanded(
                  child: SfDateRangePicker(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    selectionMode: DateRangePickerSelectionMode.range,
                    headerStyle: DateRangePickerHeaderStyle(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      textStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      )
                    ),
                    headerHeight: 80,
                    showActionButtons: false,
                    initialSelectedRange:
                    (s != null && e != null) ? PickerDateRange(s, e) : null,
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

  bool _validateDates() {
    _dateMissing   = _start == null || _end == null;
    _rangeOverlap  =
        !_dateMissing && _periodClashes(_start!, _end!);
    setState(() {});
    return !_dateMissing && !_rangeOverlap;
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

  bool _periodClashes(DateTime s, DateTime e) {
    for (final p in _periodBox.values) {
      if (!e.isBefore(p.startDate) && !s.isAfter(p.endDate)) return true;
    }
    return false;
  }

  /*───────────────────────────────────────────────────────────*/
  /*                        저장 검증 & Hive                    */
  /*───────────────────────────────────────────────────────────*/
  bool _validateAll() {
    _showItemErrors = true;                    // <-- 추가
    final ok = _validateDates() && !_emptyItems;
    setState(() {});                           // 밑줄/행 error 갱신
    return ok;
  }

  Future<void> _save() async {

    debugPrintBudgetHive();

    if (!_validateAll()) return;

    /* ─ 완료된 항목만 선별 ─ */
    final completed = _draft.where((d) => d.isComplete).toList();

    /* ─ BudgetItem 저장 ─ */
    final List<BudgetItem> newItems = [];
    for (final d in completed) {
      final item = BudgetItem(
        id: 0,
        categoryId : d.categoryId!,
        limitAmount: d.limit,
        spentAmount: 0,
        iconKey    : '',
      );
      final key = await _itemBox.add(item);
      item.id = key;
      await item.save();
      newItems.add(item);
    }

    /* ─ BudgetPeriod 저장 ─ */
    final period = BudgetPeriod(
      id: 0,
      startDate: _start!,
      endDate  : _end!,
      items    : HiveList(_itemBox, objects: newItems),
    );
    period.id = await _periodBox.add(period);
    await period.save();

    if (mounted) Navigator.pop(context);
  }

  /*───────────────────────────────────────────────────────────*/
  /*                     UI (빌드)                              */
  /*───────────────────────────────────────────────────────────*/
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text('예산 편성')),
      body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /* ─ 날짜 버튼 ─ */
                _rangeButton(),
                if (_rangeOverlap)
                  const Padding(
                    padding: EdgeInsets.only(top:4),
                    child: Text('다른 예산 기간과 겹칩니다',
                        style: TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 24),

                /* ─ 입력 리스트 + 추가 버튼 ─ */
                Expanded(
                  child: ListView.separated(
                    itemCount: _draft.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 10,),
                    itemBuilder: (ctx, i) {
                      /*➊ 추가 버튼 줄 ----------------------------------------*/
                      if (i == _draft.length) {
                        return Center(
                            child: GestureDetector(
                                onTap: () =>
                                    setState(() => _draft.add(_TempItem())),
                                child: const Row(
                                  children: [
                                    Expanded(child: SizedBox()),
                                    Text(
                                      "예산 추가",
                                      style: TextStyle(
                                          fontSize: 17
                                      ),
                                    ),
                                    SizedBox(width: 5,),
                                    Icon(Icons.add_rounded),
                                    Expanded(child: SizedBox()),
                                  ],
                                )
                            )
                        );
                      }

                      /*➋ 입력 Row ---------------------------------------------*/
                      final d   = _draft[i];
                      final err = _showItemErrors && !d.isComplete;

                      return Row(
                        children: [
                          /* 카테고리 */
                          Expanded(
                            flex: 1,
                            child: _categoryField(
                              selectedId: d.categoryId,
                              hasErr   : err && d.categoryId == null,
                              onPicked : (id) => setState(() => d.categoryId = id),
                            ),
                          ),
                          const SizedBox(width:8),
                          /* 금액 */
                          Expanded(
                            flex: 2,
                            child: _amountField(
                              controller: d.amtCtrl,
                              hasErr: err && (int.tryParse(d.amtCtrl.text) ?? 0) == 0,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          /* 삭제 (길게) */
                          IconButton(
                            icon: const Icon(Icons.close),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ), // 최소 크기 제한
                            visualDensity: VisualDensity.compact, // 조금 더 촘촘하게
                            onPressed: () =>
                                setState(() => _draft.removeAt(i)),
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
                /* ─ 저장 버튼 ─ */
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: Text('저장하기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),),
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }

  /*──────────────────────── 날짜 버튼 위젯 ────────────────────────*/
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
        dense: true,
        leading : const Icon(Icons.calendar_month_rounded),
        title   : Text(lbl,
            style: TextStyle(
                color: hasErr ? Colors.red : null,
                fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.expand_more_rounded),
        onTap   : _pickDateRange,
      ),
    );
  }

  /*──────────────────────── 카테고리 필드 ────────────────────────*/
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
        isEmpty: (sel?.name ?? '').isEmpty, // TextField처럼 처리
        decoration: InputDecoration(
          hintText: '예산',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12), // height 조절
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: hasErr
                  ? Colors.red
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
          suffixIcon: const Icon(Icons.expand_more_rounded),
        ),
        child: Text(
          sel?.name ?? '',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
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
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
            // errorText는 InputDecorator에는 표시 안되므로 따로 처리 필요
          ),
          child: const SizedBox.shrink(), // child는 텍스트를 안 넣음
        ),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: InputBorder.none, // underline은 InputDecorator에 위임
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: onChanged,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }




  /*──────────────────────── 카테고리 Picker ─────────────────────*/
  Future<int?> _showCategoryPicker() async {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /* 헤더 */
            Padding(
              padding: const EdgeInsets.fromLTRB(16,18,16,8),
              child: Row(
                children: [
                  const Text('카테고리 선택',
                      style: TextStyle(
                          fontSize:18,fontWeight:FontWeight.bold)),
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
            /* 목록 */
            SizedBox(
              height: 350,
              child: ListView.separated(
                itemCount: _catBox.length,
                separatorBuilder: (_, __) =>
                const SizedBox(),
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

/*───────────────────────── Temp 모델 ──────────────────────────*/
class _TempItem {
  int? categoryId;
  final TextEditingController amtCtrl = TextEditingController();

  _TempItem({this.categoryId});

  int get limit => int.tryParse(amtCtrl.text) ?? 0;
  bool get isComplete => categoryId != null && limit > 0;
}
