import 'package:flutter/material.dart';

class MainSummaryPage extends StatelessWidget {
  const MainSummaryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '요약 페이지',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}