// lib/pages/bank/bank_add_page.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../componenets/bank_map.dart';
import '../../models/bank.dart'; // Hive 모델

class BankAddPage extends StatefulWidget {
  const BankAddPage({Key? key}) : super(key: key);

  @override
  State<BankAddPage> createState() => _BankAddPageState();
}

class _BankAddPageState extends State<BankAddPage> {
  final Box<Bank> _bankBox = Hive.box<Bank>('banks');
  final Set<int> _selectedIndices = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 1) 이미 저장된 은행명 셋으로 추출
    final existing = _bankBox.values.map((b) => b.name).toSet();
    // 2) 전체 매핑(bankMap)에서 아직 없는 것만 필터링
    final availableBanks =
        bankMap.where((m) => !existing.contains(m['name'])).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('은행 추가'),
      ),
      body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    itemCount: availableBanks.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      final asset = availableBanks[index]['asset']!;
                      final name = availableBanks[index]['name']!;
                      final isSel = _selectedIndices.contains(index);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSel)
                              _selectedIndices.remove(index);
                            else
                              _selectedIndices.add(index);
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: isSel
                                ? Border.all(
                                color: theme.colorScheme.primary, width: 2)
                                : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.asset(asset, fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSel
                                      ? theme.colorScheme.primary
                                      : theme.textTheme.bodyLarge?.color,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedIndices.isEmpty
                        ? null
                        : () async {
                      // 선택된 은행들 한꺼번에 저장
                      for (final idx in _selectedIndices) {
                        // idx 역시 availableBanks 기준
                        final map = availableBanks[idx];
                        final bank = Bank(
                          id: 0,
                          name: map['name']!,
                          imagePath: map['asset']!,
                        );
                        final key = await _bankBox.add(bank);
                        bank.id = key;
                        await bank.save();
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('추가'),
                  ),
                ),
              ],
            ),
          ),

      )


    );
  }
}
