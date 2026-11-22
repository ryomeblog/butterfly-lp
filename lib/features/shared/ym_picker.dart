import 'package:flutter/material.dart';

import '../../core/time.dart';

/// 年月の選択（年と月のドロップダウン）。[min]〜[max] の範囲で選ぶ。
class YmPicker extends StatelessWidget {
  const YmPicker({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final YearMonth value;
  final YearMonth min;
  final YearMonth max;
  final ValueChanged<YearMonth> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<int>(
              key: key == null ? null : Key('${(key as ValueKey).value}-year'),
              value: value.year,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: [
                for (var y = min.year; y <= max.year; y++)
                  DropdownMenuItem(value: y, child: Text('$y年')),
              ],
              onChanged: (y) => onChanged(_clamp(YearMonth(y!, value.month))),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<int>(
              key: key == null ? null : Key('${(key as ValueKey).value}-month'),
              value: value.month,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: [
                for (var m = 1; m <= 12; m++)
                  DropdownMenuItem(value: m, child: Text('$m月')),
              ],
              onChanged: (m) => onChanged(_clamp(YearMonth(value.year, m!))),
            ),
          ),
        ],
      ),
    );
  }

  YearMonth _clamp(YearMonth v) => v < min ? min : (v > max ? max : v);
}
