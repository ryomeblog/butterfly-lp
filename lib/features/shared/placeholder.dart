import 'package:flutter/material.dart';

/// まだ実装していない画面の仮表示。どのマイルストーンで作るかを示す。
class NotYetImplemented extends StatelessWidget {
  const NotYetImplemented({
    super.key,
    required this.feature,
    required this.milestone,
  });

  final String feature;
  final String milestone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '「$feature」は $milestone で実装します。',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
