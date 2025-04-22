import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/consumption.dart';

class AddConsumptionPage extends StatefulWidget {
  const AddConsumptionPage({Key? key}) : super(key: key);

  @override
  State<AddConsumptionPage> createState() => _AddConsumptionPageState();
}

class _AddConsumptionPageState extends State<AddConsumptionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _methodController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _type = '지출';
  DateTime _transactionDate = DateTime.now();

  Future<void> _pickTransactionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _transactionDate = picked);
    }
  }

  void _saveConsumption() {
    if (_formKey.currentState!.validate()) {
      final box = Hive.box<Consumption>('consumptions');
      final existingIds = box.values.map((e) => e.id);
      final nextId = existingIds.isEmpty ? 1 : existingIds.reduce(max) + 1;
      final amount = int.tryParse(_amountController.text.trim()) ?? 0;

      final newEntry = Consumption(
        id: nextId,
        type: _type,
        category: _categoryController.text.trim(),
        description: _descriptionController.text.trim(),
        method: _methodController.text.trim(),
        date: _transactionDate,
        addDate: DateTime.now(),
        amount: amount,
      );

      box.add(newEntry);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _descriptionController.dispose();
    _methodController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('소비 내역 추가'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: '타입'),
                items: const [
                  DropdownMenuItem(value: '지출', child: Text('지출')),
                  DropdownMenuItem(value: '수입', child: Text('수입')),
                ],
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: '금액',
                  prefixText: '₩',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return '금액을 입력하세요';
                  if (int.tryParse(v.trim()) == null) return '숫자만 입력 가능';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: '예산 카테고리'),
                validator: (v) => v == null || v.isEmpty ? '필수 입력' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: '내용'),
                validator: (v) => v == null || v.isEmpty ? '필수 입력' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _methodController,
                decoration: const InputDecoration(labelText: '소비 수단'),
                validator: (v) => v == null || v.isEmpty ? '필수 입력' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('거래 날짜'),
                subtitle: Text(
                  '${_transactionDate.year}-${_transactionDate.month.toString().padLeft(2, '0')}-${_transactionDate.day.toString().padLeft(2, '0')}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickTransactionDate,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveConsumption,
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
