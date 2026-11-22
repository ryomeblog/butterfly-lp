import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../data/db/database.dart';
import '../../domain/calc/group_registration.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/group_item.dart';
import '../shared/plan_period.dart';
import '../shared/widgets.dart';
import '../shared/ym_picker.dart';

/// グループを登録（ワイヤーフレーム GroupRegister）。
///
/// グループ・開始年月・終了年月を選び、作られる項目を確かめて登録する。削除されたテンプレートの項目があれば、
/// 欠けている項目を示す確認を出し、グループの修正へ移るか残りの項目で登録する（設計書 3.2）。
class GroupRegisterScreen extends ConsumerStatefulWidget {
  const GroupRegisterScreen({super.key, required this.planId, this.groupId});

  final String planId;
  final String? groupId;

  @override
  ConsumerState<GroupRegisterScreen> createState() =>
      _GroupRegisterScreenState();
}

class _GroupRegisterScreenState extends ConsumerState<GroupRegisterScreen> {
  String? _groupId;
  YearMonth? _start;
  YearMonth? _end;
  RegistrationResult? _preview;
  List<GroupItemDraft> _items = const [];
  int _requestNo = 0;

  @override
  void initState() {
    super.initState();
    _groupId = widget.groupId;
  }

  Future<void> _refresh() async {
    final g = _groupId;
    final s = _start;
    final e = _end;
    if (g == null || s == null || e == null) return;
    final no = ++_requestNo;
    final items = await ref.read(templateRepositoryProvider).getGroupItems(g);
    final r = await ref
        .read(planLineRepositoryProvider)
        .preview(planId: widget.planId, groupId: g, start: s, end: e);
    if (!mounted || no != _requestNo) return;
    setState(() {
      _items = items;
      _preview = r;
    });
  }

  Future<void> _register(String groupName) async {
    final r = _preview!;
    if (r.skipped.isNotEmpty) {
      final go = await showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('欠けている項目があります'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('グループ「$groupName」の次の項目は使えません。'),
              for (final s in r.skipped)
                Text('・${s.templateName ?? '（削除されたテンプレート）'}：${s.reason}'),
              const SizedBox(height: 8),
              Text(
                'この項目を除いた ${_items.length - r.skipped.length}項目で予定を作ります。'
                '欠けた項目を基準にしている割合の項目も、金額を決められないため作りません。',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, 'fix'),
              child: const Text('グループを修正する'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              key: const Key('register-anyway'),
              onPressed: () => Navigator.pop(c, 'ok'),
              child: const Text('この内容で登録'),
            ),
          ],
        ),
      );
      if (go == 'fix' && mounted) {
        await context.push('/home/group/$_groupId');
        await _refresh();
        return;
      }
      if (go != 'ok') return;
    }
    await ref
        .read(planLineRepositoryProvider)
        .registerGroup(
          planId: widget.planId,
          groupId: _groupId!,
          start: _start!,
          end: _end!,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final plan = (ref.watch(plansProvider).value ?? const <PlanRow>[])
        .where((p) => p.id == widget.planId)
        .firstOrNull;
    final members = ref.watch(membersProvider(widget.planId)).value ?? const [];
    final groups = ref.watch(groupSummariesProvider).value ?? const [];
    final templates = {
      for (final t
          in ref.watch(templatesProvider).value ?? const <TemplateRow>[])
        t.id: t,
    };
    final period = plan == null ? null : planPeriod(plan, members);
    if (plan == null || period == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_start == null) {
      final now = YearMonth.ofDate(clock.now());
      _start = now < period.start
          ? period.start
          : (now > period.end ? period.start : now);
      _end = period.end;
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    }
    final group = groups.where((g) => g.group.id == _groupId).firstOrNull;
    final preview = _preview;
    final skippedIds = {
      for (final s in preview?.skipped ?? const <SkippedItem>[]) s.itemId,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('グループを登録')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${plan.name}に登録して、計画行（予定）を作ります。'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: const Key('register-group'),
            initialValue: group == null ? null : _groupId,
            decoration: const InputDecoration(labelText: 'グループ'),
            items: [
              for (final g in groups)
                DropdownMenuItem(
                  value: g.group.id,
                  child: Text('${g.group.name}（項目${g.itemCount}件）'),
                ),
            ],
            onChanged: (v) {
              setState(() => _groupId = v);
              _refresh();
            },
          ),
          const SizedBox(height: 16),
          YmPicker(
            key: const ValueKey('register-start'),
            label: '開始年月（上昇率の基準）',
            value: _start!,
            min: period.start,
            max: period.end,
            onChanged: (v) {
              setState(() {
                _start = v;
                if (_end! < v) _end = v;
              });
              _refresh();
            },
          ),
          const SizedBox(height: 16),
          YmPicker(
            key: const ValueKey('register-end'),
            label: '終了年月',
            value: _end!,
            min: _start!,
            max: period.end,
            onChanged: (v) {
              setState(() => _end = v);
              _refresh();
            },
          ),
          const SizedBox(height: 8),
          Text(
            '項目ごとの頻度で、この期間の計画行を作ります。固定額の収入・支出は上昇率で増やし'
            '（基準＝開始年）、割合の項目はそれに連動します。登録していない期間は収入・支出なしとして扱います。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (group != null && preview != null) ...[
            const SectionTitle('作られる予定（項目）'),
            for (final item in _items)
              _PreviewRow(
                item: item,
                all: _items,
                templates: templates,
                skipped: skippedIds.contains(item.id),
                first: preview.lines
                    .where((l) => l.itemId == item.id)
                    .firstOrNull,
              ),
            const SizedBox(height: 8),
            Text('作成される計画行：${preview.lines.length}件'),
          ],
        ],
      ),
      bottomNavigationBar: SaveCancelBar(
        saveLabel: '登録する',
        saveKey: const Key('register-save'),
        onSave: group == null || preview == null
            ? null
            : () => _register(group.group.name),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.item,
    required this.all,
    required this.templates,
    required this.skipped,
    required this.first,
  });

  final GroupItemDraft item;
  final List<GroupItemDraft> all;
  final Map<String, TemplateRow> templates;
  final bool skipped;
  final GeneratedLine? first;

  @override
  Widget build(BuildContext context) {
    final t = templates[item.templateId];
    final base = all.where((i) => i.id == item.baseItemId).firstOrNull;
    final how = item.amountMode == AmountMode.percent
        ? '${templates[base?.templateId]?.name ?? '?'}の${item.percent}%'
        : describeFrequency(item);
    final f = first;
    final sign = t == null
        ? ''
        : switch (TxnKind.of(t.kind)) {
            TxnKind.income => '+',
            TxnKind.expense => '−',
            TxnKind.transfer => '',
          };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(t?.name ?? '（削除されたテンプレート）'),
      subtitle: Text(how),
      trailing: skipped
          ? Text(
              '登録されない',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          : Text(f == null ? '—' : '$sign${formatYen(f.amount)}'),
    );
  }
}
