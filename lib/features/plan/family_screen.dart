import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/time.dart';
import '../../data/db/database.dart';
import '../../data/repositories/rate_family_repository.dart';
import '../../domain/models/enums.dart';

/// 家族（ワイヤーフレーム Family）：家族メンバー（続柄・生年月日・寿命）と主人公の指定。
///
/// 削除するときは、消えるデータ（イベント・予定・紐づきが外れる実績）を画面に出して確かめられるようにし、
/// 削除ボタンはモーダルの確認を挟まずにすぐ削除する（設計書 3.7）。
class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key, required this.planId});

  final String planId;

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  /// 編集中のメンバー（'new' は追加）
  String? _editing;

  @override
  Widget build(BuildContext context) {
    final plan = (ref.watch(plansProvider).value ?? const <PlanRow>[])
        .where((p) => p.id == widget.planId)
        .firstOrNull;
    final members = ref.watch(membersProvider(widget.planId)).value ?? const [];
    if (plan == null) return Scaffold(appBar: AppBar());
    return Scaffold(
      appBar: AppBar(title: Text('家族（${plan.name}）')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final m in members) ...[
            Card(
              child: ListTile(
                key: Key('member-${m.name}'),
                title: Row(
                  children: [
                    Flexible(child: Text(m.name)),
                    if (m.id == plan.protagonistMemberId) ...[
                      const SizedBox(width: 8),
                      const Chip(
                        label: Text('主人公'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
                subtitle: Text(_describe(m)),
                trailing: Icon(
                  _editing == m.id ? Icons.expand_less : Icons.expand_more,
                ),
                onTap: () =>
                    setState(() => _editing = _editing == m.id ? null : m.id),
              ),
            ),
            if (_editing == m.id)
              _MemberForm(
                key: ValueKey(m.id),
                planId: widget.planId,
                member: m,
                isProtagonist: m.id == plan.protagonistMemberId,
                onDone: () => setState(() => _editing = null),
              ),
            const SizedBox(height: 8),
          ],
          if (_editing == 'new')
            _MemberForm(
              key: const ValueKey('new'),
              planId: widget.planId,
              member: null,
              isProtagonist: false,
              onDone: () => setState(() => _editing = null),
            )
          else
            OutlinedButton.icon(
              key: const Key('member-add'),
              onPressed: () => setState(() => _editing = 'new'),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('家族を追加'),
            ),
          const SizedBox(height: 16),
          Text(
            '家族はプランごとに別です。続柄は表示用です。主人公はプラン期間の終わり（寿命の年）とグラフの年齢の基準になり、削除できません。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _describe(FamilyMemberRow m) {
    final b = parseDate(m.birthDate);
    return '${Relation.of(m.relation).label}・${b.year}/${b.month}/${b.day}生・寿命 ${m.lifeExpectancy}歳';
  }
}

class _MemberForm extends ConsumerStatefulWidget {
  const _MemberForm({
    super.key,
    required this.planId,
    required this.member,
    required this.isProtagonist,
    required this.onDone,
  });

  final String planId;
  final FamilyMemberRow? member;
  final bool isProtagonist;
  final VoidCallback onDone;

  @override
  ConsumerState<_MemberForm> createState() => _MemberFormState();
}

class _MemberFormState extends ConsumerState<_MemberForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.member?.name ?? '');
  late final _life = TextEditingController(
    text: '${widget.member?.lifeExpectancy ?? 90}',
  );
  late Relation _relation = widget.member == null
      ? Relation.child
      : Relation.of(widget.member!.relation);
  late DateTime? _birth = widget.member == null
      ? null
      : parseDate(widget.member!.birthDate);
  MemberDeletionImpact? _impact;

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    if (m != null && !widget.isProtagonist) {
      ref
          .read(rateFamilyRepositoryProvider)
          .memberDeletionImpact(m.id)
          .then((v) => mounted ? setState(() => _impact = v) : null);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _life.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_birth == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('生年月日を入れてください')));
      return;
    }
    final input = MemberInput(
      name: _name.text.trim(),
      relation: _relation,
      birthDate: dateString(_birth!),
      lifeExpectancy: int.parse(_life.text),
    );
    final repo = ref.read(rateFamilyRepositoryProvider);
    if (widget.member == null) {
      await repo.addMember(widget.planId, input);
    } else {
      await repo.updateMember(widget.member!.id, input);
    }
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final birth = _birth;
    final impact = _impact;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.member == null ? '家族を追加' : '${widget.member!.name}を編集',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('member-name'),
                controller: _name,
                decoration: const InputDecoration(labelText: '名前'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '入力してください' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Relation>(
                initialValue: _relation,
                decoration: const InputDecoration(labelText: '続柄'),
                items: [
                  for (final r in Relation.values)
                    DropdownMenuItem(value: r, child: Text(r.label)),
                ],
                onChanged: (r) => setState(() => _relation = r!),
              ),
              const SizedBox(height: 12),
              InkWell(
                key: const Key('member-birth'),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: birth ?? DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2200),
                    initialEntryMode: DatePickerEntryMode.input,
                  );
                  if (d != null) setState(() => _birth = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '生年月日（将来の子は予定日）',
                  ),
                  child: Text(
                    birth == null
                        ? '選んでください'
                        : '${birth.year}/${birth.month}/${birth.day}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('member-life'),
                controller: _life,
                decoration: const InputDecoration(
                  labelText: '寿命（歳）',
                  suffixText: '歳',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n < 1 || n > 130)
                      ? '1〜130で入力してください'
                      : null;
                },
              ),
              if (widget.member != null && !widget.isProtagonist)
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(rateFamilyRepositoryProvider)
                        .setProtagonist(widget.planId, widget.member!.id);
                    widget.onDone();
                  },
                  child: const Text('この人を主人公にする'),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: widget.onDone,
                    child: const Text('キャンセル'),
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const Key('member-save'),
                    onPressed: _save,
                    child: const Text('保存'),
                  ),
                ],
              ),
              if (widget.member != null && !widget.isProtagonist) ...[
                const Divider(height: 32),
                Text(
                  '削除すると消えるもの',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                if (impact == null)
                  const Text('確認しています…')
                else ...[
                  Text(
                    impact.eventTitles.isEmpty
                        ? 'この人のイベント：なし'
                        : 'この人のイベント ${impact.eventTitles.length}件：${impact.eventTitles.join('・')}',
                  ),
                  Text('イベントの予定（計画行）：${impact.planLineCount}件'),
                  Text('イベントとの紐づきが外れる実績：${impact.txnCount}件（実績は残ります）'),
                ],
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const Key('member-delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () async {
                    await ref
                        .read(rateFamilyRepositoryProvider)
                        .deleteMember(widget.member!.id);
                    widget.onDone();
                  },
                  child: const Text('この人を削除（すぐに削除します）'),
                ),
              ],
              if (widget.isProtagonist)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '主人公は削除できません。別の人を主人公にしてから削除してください。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
