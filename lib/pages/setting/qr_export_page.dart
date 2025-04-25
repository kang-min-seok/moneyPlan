import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/budget_category.dart';
import '../../models/budget_item.dart';
import '../../models/budget_period.dart';
import '../../models/transaction.dart';
import '../../models/bank.dart';

class QrExportPage extends StatelessWidget {
  const QrExportPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 모든 박스 가져오기
    final catBox    = Hive.box<BudgetCategory>('categories');
    final itemBox   = Hive.box<BudgetItem>('budgetItems');
    final periodBox = Hive.box<BudgetPeriod>('budgetPeriods');
    final txBox     = Hive.box<Transaction>('transactions');
    final bankBox   = Hive.box<Bank>('banks');

    // JSON 으로 변환
    final Map<String, dynamic> data = {
      'categories': catBox.values.map((c) => {
        'id': c.id,
        'name': c.name,
        'iconKey': c.iconKey,
        'colorValue': c.colorValue,
      }).toList(),
      'items': itemBox.values.map((i) => {
        'id': i.id,
        'categoryId': i.categoryId,
        'limitAmount': i.limitAmount,
        'iconKey': i.iconKey,
        'spentAmount': i.spentAmount,
      }).toList(),
      'periods': periodBox.values.map((p) => {
        'id': p.id,
        'startDate': p.startDate.toIso8601String(),
        'endDate': p.endDate.toIso8601String(),
        'items': p.items.map((it) => it.id).toList(),
      }).toList(),
      'transactions': txBox.values.map((t) => {
        'id'          : t.id,
        'date'        : t.date.toIso8601String(),
        'type'        : t.type,
        'amount'      : t.amount,
        'categoryId'  : t.categoryId,
        'memo'        : t.memo,
        'path'        : t.path,
        'periodId'    : t.periodId,
        'budgetItemId': t.budgetItemId,
      }).toList(),
      'banks': bankBox.values.map((b) => {
        'id': b.id,
        'name': b.name,
        'imagePath': b.imagePath,
      }).toList(),
    };

    final jsonString = jsonEncode(data);

    return Scaffold(
      appBar: AppBar(title: const Text('백업용 QR 코드 생성')),
      body: Center(
        child: QrImageView(
          data: jsonString,
          version: QrVersions.auto,
          size: MediaQuery.of(context).size.width * 0.8,
          backgroundColor: Colors.white,
        ), // QrImageView 사용 :contentReference[oaicite:0]{index=0}
      ),
    );
  }
}
