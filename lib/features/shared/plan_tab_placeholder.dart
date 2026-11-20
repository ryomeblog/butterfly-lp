import 'package:flutter/material.dart';

import 'placeholder.dart';
import 'plan_switch_sheet.dart';

/// 家計簿・資産・イベントのタブの仮画面。上部に表示中のプラン名（押すと切り替え）を出す。
class PlanTabPlaceholder extends StatelessWidget {
  const PlanTabPlaceholder({
    super.key,
    required this.title,
    required this.milestone,
  });

  final String title;
  final String milestone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: PlanSwitchTitle(title: title)),
      body: NotYetImplemented(feature: title, milestone: milestone),
    );
  }
}
