import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/platform.dart';
import '../../app/providers.dart';
import '../../core/time.dart';
import '../../data/repositories/plan_repository.dart';

/// プランの作成。初回起動では「最初のプランを作る画面」として出す（設計書 7.1）。
class PlanCreateScreen extends ConsumerStatefulWidget {
  const PlanCreateScreen({super.key, required this.isFirst});

  /// 初回起動（プランが1つもない）。口座「現金」も作り、「同期から始める」を出す。
  final bool isFirst;

  @override
  ConsumerState<PlanCreateScreen> createState() => _PlanCreateScreenState();
}

class _PlanCreateScreenState extends ConsumerState<PlanCreateScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.isFirst ? 'プラン1' : '');
  late final _startYear = TextEditingController(text: '${clock.now().year}');
  final _protagonist = TextEditingController(text: '本人');
  final _life = TextEditingController(text: '90');
  DateTime? _birthDate;
  bool _saving = false;

  /// 実績と資産を引き継ぐプラン（null なら空の家計簿から始める）
  String? _inheritFrom;

  @override
  void dispose() {
    _name.dispose();
    _startYear.dispose();
    _protagonist.dispose();
    _life.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = clock.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 35, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 30, 12, 31),
      initialEntryMode: DatePickerEntryMode.input,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('生年月日を入れてください')));
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(planRepositoryProvider);
    final input = NewPlanInput(
      name: _name.text.trim(),
      startYear: int.parse(_startYear.text),
      protagonistName: _protagonist.text.trim(),
      protagonistBirthDate: dateString(_birthDate!),
      protagonistLifeExpectancy: int.parse(_life.text),
      createCashAccount: widget.isFirst,
    );
    final from = _inheritFrom;
    final planId = from == null
        ? await repo.createPlan(input)
        : await ref
              .read(planAdminRepositoryProvider)
              .createInheriting(input, from);
    await ref.read(deviceRepositoryProvider).setSelectedPlan(planId);
    if (!mounted) return;
    if (widget.isFirst) {
      context.go('/home');
    } else {
      context.pop();
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? '入力してください' : null;

  String? _intRange(String? v, int min, int max) {
    final n = int.tryParse(v ?? '');
    if (n == null) return '数字で入力してください';
    if (n < min || n > max) return '$min〜$max の範囲で入力してください';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final birth = _birthDate;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFirst ? 'はじめに' : 'プランを作成'),
        automaticallyImplyLeading: !widget.isFirst,
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.isFirst) ...[
              Text(
                '最初のライフプランを作ります。家計簿・資産・イベントはプランごとに持ちます。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              key: const Key('plan-name'),
              controller: _name,
              decoration: const InputDecoration(labelText: 'プラン名'),
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('plan-start-year'),
              controller: _startYear,
              decoration: const InputDecoration(labelText: '開始年'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => _intRange(v, 1900, 2200),
            ),
            const SizedBox(height: 24),
            Text('主人公', style: Theme.of(context).textTheme.titleMedium),
            const Text('プラン期間の終わり（主人公の寿命の年）とグラフの年齢の基準になります。'),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('protagonist-name'),
              controller: _protagonist,
              decoration: const InputDecoration(labelText: '名前'),
              validator: _required,
            ),
            const SizedBox(height: 16),
            InkWell(
              key: const Key('protagonist-birth'),
              onTap: _pickBirthDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: '生年月日'),
                child: Text(
                  birth == null
                      ? '選んでください'
                      : '${birth.year}/${birth.month}/${birth.day}',
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('protagonist-life'),
              controller: _life,
              decoration: const InputDecoration(
                labelText: '寿命（歳）',
                suffixText: '歳',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => _intRange(v, 1, 130),
            ),
            if (!widget.isFirst) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                key: const Key('plan-inherit'),
                initialValue: _inheritFrom,
                decoration: const InputDecoration(labelText: '家計簿（実績）と資産'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('空から始める')),
                  for (final p in ref.watch(plansProvider).value ?? const [])
                    DropdownMenuItem(
                      value: p.id,
                      child: Text('「${p.name}」から引き継ぐ'),
                    ),
                ],
                onChanged: (v) => setState(() => _inheritFrom = v),
              ),
              const SizedBox(height: 4),
              Text(
                '引き継ぐと、そのプランの実績と資産（価値を含む）を写します。家族・計画・イベントは引き継ぎません。'
                'すべてを写すときは、ホームのプランのメニューの「複製」を使います。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (widget.isFirst) ...[
              const SizedBox(height: 16),
              Text(
                '口座「現金」（初期残高0円）を1つ作ります。口座は設定から追加・編集できます。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('plan-create-save'),
              onPressed: _saving ? null : _save,
              child: Text(widget.isFirst ? 'このプランで始める' : 'プランを作成'),
            ),
            // Web 版は同期を持たない（設計書 3.12）
            if (widget.isFirst && AppPlatform.canSync) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/welcome/sync'),
                child: const Text('同期から始める（家族の端末のデータを取り込む）'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
