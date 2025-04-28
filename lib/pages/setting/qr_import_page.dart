import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import '../../models/budget_category.dart';
import '../../models/budget_item.dart';
import '../../models/budget_period.dart';
import '../../models/transaction.dart';
import '../../models/bank.dart';

class QrImportPage extends StatefulWidget {
  const QrImportPage({Key? key}) : super(key: key);

  @override
  _QrImportPageState createState() => _QrImportPageState();
}

class _QrImportPageState extends State<QrImportPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _scanned = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR 코드로 복원')),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
        onPermissionSet: (ctrl, permissionGranted) {
          if (!permissionGranted) {
            // 권한 거부 시 안내 다이얼로그
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('카메라 권한 필요'),
                content: const Text('QR 코드를 스캔하려면 카메라 권한을 허용해 주세요.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('확인'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    controller!.scannedDataStream.listen((scanData) async {
      if (_scanned) return;
      _scanned = true;

      try {
        final Map<String, dynamic> map = jsonDecode(scanData.code!);
        await _importData(map);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('데이터 복원이 완료되었습니다')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('데이터 복원 실패: $e')),
          );
        }
      }
    });
  }

  Future<void> _importData(Map<String, dynamic> map) async {
    final catBox = Hive.box<BudgetCategory>('categories');
    final itemBox = Hive.box<BudgetItem>('budgetItems');
    final periodBox = Hive.box<BudgetPeriod>('budgetPeriods');
    final txBox = Hive.box<Transaction>('transactions');
    final bankBox = Hive.box<Bank>('banks');

    // 0) 전부 비우기
    await catBox.clear();
    await itemBox.clear();
    await periodBox.clear();
    await txBox.clear();
    await bankBox.clear();

    // 1) 카테고리 복원 & 매핑
    final Map<int, int> catMap = {};
    for (final c in map['categories']) {
      final cat = BudgetCategory(
        id: 0,
        name: c['name'],
        iconKey: c['iconKey'],
        colorValue: c['colorValue'],
      );
      final newKey = await catBox.add(cat);
      cat.id = newKey;
      await cat.save();
      catMap[c['id']] = newKey;
    }

    // 2) 예산 아이템 복원 & 매핑
    final Map<int, int> itemMap = {};
    for (final i in map['items']) {
      final item = BudgetItem(
        id: 0,
        categoryId: catMap[i['categoryId']]!,
        limitAmount: i['limitAmount'],
        iconKey: i['iconKey'] ?? '',
        spentAmount: i['spentAmount'],
      );
      final newKey = await itemBox.add(item);
      item.id = newKey;
      await item.save();
      itemMap[i['id']] = newKey;
    }
    final allItems = itemBox.values.toList();

    // 3) 기간 복원 & 매핑
    final Map<int, int> periodMap = {};
    for (final p in map['periods']) {
      // 옛날 ID → 새 키로 변환
      final newItemKeys =
          (p['items'] as List).map((oldId) => itemMap[oldId]!).toList();
      final objs = allItems.where((it) => newItemKeys.contains(it.id)).toList();

      final period = BudgetPeriod(
        id: 0,
        startDate: DateTime.parse(p['startDate']),
        endDate: DateTime.parse(p['endDate']),
        items: HiveList(itemBox, objects: objs),
      );
      final newKey = await periodBox.add(period);
      period.id = newKey;
      await period.save();
      periodMap[p['id']] = newKey;
    }

    // 4) 은행 복원 (필요시 매핑)
    for (final b in map['banks']) {
      final bank = Bank(
        id: 0,
        name: b['name'],
        imagePath: b['imagePath'],
      );
      final newKey = await bankBox.add(bank);
      bank.id = newKey;
      await bank.save();
    }

    // 5) 거래 내역 복원 (카테고리·기간·아이템 ID 매핑)
    for (final t in map['transactions']) {
      // null 가능하게 int? 로 받기
      final int? oldCatId =
          (t['categoryId'] as Object?) is int ? t['categoryId'] as int : null;
      final int? oldPerId =
          (t['periodId'] as Object?) is int ? t['periodId'] as int : null;
      final int? oldItemId = (t['budgetItemId'] as Object?) is int
          ? t['budgetItemId'] as int
          : null;

      // 매핑 테이블에서 새 키를 찾되, 없으면 null
      final int? newCatId = oldCatId != null ? catMap[oldCatId] : null;
      final int? newPerId = oldPerId != null ? periodMap[oldPerId] : null;
      final int? newItemId = oldItemId != null ? itemMap[oldItemId] : null;

      final tx = Transaction(
        id: 0,
        date: DateTime.parse(t['date']),
        type: t['type'],
        amount: t['amount'],
        categoryId: newCatId,
        // int? field
        memo: t['memo'],
        path: t['path'],
        periodId: newPerId,
        // int? field
        budgetItemId: newItemId, // int? field
      );
      final newKey = await txBox.add(tx);
      tx.id = newKey;
      await tx.save();
    }

    // 6) 지출합계·리스트 갱신
    for (final it in allItems) {
      final related =
          txBox.values.where((tx) => tx.budgetItemId == it.id).toList();
      it
        ..expenseTxs = HiveList(txBox, objects: related)
        ..spentAmount = related.fold(0, (sum, tx) => sum + tx.amount);
      await it.save();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
