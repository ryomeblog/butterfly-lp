import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// `#RRGGBB` を Color に。
Color colorOf(String hex) =>
    Color(int.parse(hex.replaceFirst('#', ''), radix: 16) | 0xFF000000);

/// カテゴリの色の丸。
class ColorDot extends StatelessWidget {
  const ColorDot(this.hex, {super.key, this.size = 14});

  final String hex;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: colorOf(hex), shape: BoxShape.circle),
  );
}

/// 「収入」「支出」などの小さな枠付きラベル。
class KindBadge extends StatelessWidget {
  const KindBadge(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outline),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label, style: Theme.of(context).textTheme.labelSmall),
  );
}

/// 見出し。
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.titleMedium),
        ),
        ?trailing,
      ],
    ),
  );
}

/// 注意の枠（橙）。警告には直すための操作（リンク・ボタン）を必ず置く（設計書 3.2）。
class WarningBox extends StatelessWidget {
  const WarningBox({super.key, required this.message, this.actions = const []});

  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        border: Border.all(color: scheme.tertiary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber, color: scheme.onTertiaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: scheme.onTertiaryContainer),
                ),
              ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
    );
  }
}

/// 金額（円・整数）の入力欄。マイナスを許すかどうかを選べる。
class YenField extends StatelessWidget {
  const YenField({
    super.key,
    required this.controller,
    this.label = '金額（円）',
    this.allowNegative = false,
    this.required = true,
    this.helperText,
  });

  final TextEditingController controller;
  final String label;
  final bool allowNegative;
  final bool required;
  final String? helperText;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      prefixText: '¥ ',
      helperText: helperText,
    ),
    textAlign: TextAlign.end,
    keyboardType: TextInputType.numberWithOptions(signed: allowNegative),
    inputFormatters: [
      FilteringTextInputFormatter.allow(
        allowNegative ? RegExp(r'^-?\d*') : RegExp(r'\d*'),
      ),
    ],
    validator: (v) {
      if (v == null || v.isEmpty || v == '-') {
        return required ? '入力してください' : null;
      }
      return int.tryParse(v) == null ? '数字で入力してください' : null;
    },
  );
}

/// 年率など小数の入力欄。
class DecimalField extends StatelessWidget {
  const DecimalField({
    super.key,
    required this.controller,
    required this.label,
    this.suffix = '%',
    this.allowNegative = true,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final bool allowNegative;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label, suffixText: suffix),
    textAlign: TextAlign.end,
    keyboardType: TextInputType.numberWithOptions(
      decimal: true,
      signed: allowNegative,
    ),
    inputFormatters: [
      FilteringTextInputFormatter.allow(
        allowNegative ? RegExp(r'^-?\d*\.?\d*') : RegExp(r'^\d*\.?\d*'),
      ),
    ],
    validator: (v) =>
        (v == null || double.tryParse(v) == null) ? '数字で入力してください' : null,
  );
}

/// 「保存」「キャンセル」の下部ボタン。
class SaveCancelBar extends StatelessWidget {
  const SaveCancelBar({
    super.key,
    required this.onSave,
    this.saveLabel = '保存',
    this.saveKey,
  });

  final VoidCallback? onSave;
  final String saveLabel;
  final Key? saveKey;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('キャンセル'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              key: saveKey,
              onPressed: onSave,
              child: Text(saveLabel),
            ),
          ),
        ],
      ),
    ),
  );
}

/// 一覧で選んでいるときに画面下に出す帯。件数・「すべて選ぶ」・選択をやめる×と、操作のボタン（[actions]）。
class SelectionBar extends StatelessWidget {
  const SelectionBar({
    super.key,
    required this.count,
    required this.onClear,
    required this.onSelectAll,
    required this.actions,
  });

  final int count;
  final VoidCallback onClear;
  final VoidCallback onSelectAll;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Material(
    elevation: 8,
    color: Theme.of(context).colorScheme.surfaceContainerHigh,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                key: const Key('select-clear'),
                tooltip: '選択をやめる',
                icon: const Icon(Icons.close),
                onPressed: onClear,
              ),
              Expanded(
                child: Text('$count件を選択中', key: const Key('select-count')),
              ),
              TextButton(
                key: const Key('select-all'),
                onPressed: onSelectAll,
                child: const Text('すべて選ぶ'),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: actions,
          ),
        ],
      ),
    ),
  );
}

/// 選択モードの行の先頭に付けるチェック。
class SelectMark extends StatelessWidget {
  const SelectMark({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) =>
      Icon(selected ? Icons.check_box : Icons.check_box_outline_blank);
}
