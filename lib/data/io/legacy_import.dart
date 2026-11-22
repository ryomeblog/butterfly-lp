import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../core/money.dart';
import '../../core/time.dart';
import '../../domain/calc/asset_valuation.dart';
import '../../domain/calc/rounding.dart';
import '../../domain/models/enums.dart';
import '../db/database.dart';
import '../repositories/plan_repository.dart';
import '../repositories/stamp.dart';

/// 参考アプリ（shin-lifeplan-app）の JSON からの移行（設計書 3.7）。
///
/// 参考アプリのデータは `{ "lifeplan": [ プラン… ] }`（localStorage の lifePlanData）で、各プランが
/// settings・categories・accounts・familyMembers・yearlyData（年ごとの transactions・events）・
/// assetInfo（priceHistory・dividendHistory）・holdingAssets・templates を持つ。
///
/// 取り込み先は新しく作るプラン1つ。
/// - 取引は年月の1日付の実績。投資（investment）の取引は、保有資産の購入実績と重なるため取り込まない
/// - 保有資産は資産（数量×単価）＋購入年1月1日の購入実績（売却年があれば売却年1月1日の売却実績）
/// - 年次価格は各年1月の月単位の価値、配当は保有している年ごとの資産の収益実績（各年12月31日）
/// - テンプレートはテンプレートとして（グループは作らない）、家族・イベントは新しいプランへ（金額なしのイベント）
/// - カテゴリ・口座は、同じ種類・同じ名前があればそれを使い、なければ作る
class LegacyImporter {
  LegacyImporter(this.db, this.stamp);

  final AppDatabase db;
  final Stamp stamp;

  /// ファイル内のプラン（id・名前）。
  static List<Map<String, dynamic>> plansOf(Object? json) {
    if (json is Map && json['lifeplan'] is List) {
      return [
        for (final p in json['lifeplan'] as List)
          if (p is Map) p.cast<String, dynamic>(),
      ];
    }
    if (json is Map && json['yearlyData'] != null) {
      return [json.cast<String, dynamic>()];
    }
    if (json is List) {
      return [
        for (final p in json)
          if (p is Map) p.cast<String, dynamic>(),
      ];
    }
    throw const FormatException('参考アプリのデータ（lifeplan の一覧）ではありません');
  }

  static Map<String, dynamic> parse(String text) => {'root': jsonDecode(text)};

  /// 1つのプランを取り込み、新しいプランのIDと件数を返す。
  Future<LegacyResult> importPlan(Map<String, dynamic> p) {
    return db.transaction(() async {
      final now = stamp.now();
      final result = LegacyResult();
      final settings =
          (p['settings'] as Map?)?.cast<String, dynamic>() ?? const {};
      final startYear = _int(settings['planStartYear']) ?? DateTime.now().year;
      final members = [
        for (final m in p['familyMembers'] as List? ?? const [])
          if (m is Map) m.cast<String, dynamic>(),
      ];
      final first = members.firstOrNull;

      // プランと主人公（家族の1人目。いなければ「本人」）
      final names = {
        for (final x in await db.select(db.plans).get())
          if (x.deletedAt == null) x.name,
      };
      var name = (p['name'] as String?) ?? '移行したプラン';
      if (names.contains(name)) name = '$name(2)';
      final endYear = _int(settings['planEndYear']);
      final birth = _date(first?['birthDate']) ?? '1990-01-01';
      final life =
          _int(first?['lifeExpectancy']) ??
          (endYear == null ? 90 : endYear - int.parse(birth.substring(0, 4)));
      final planId = await PlanRepository(db, stamp).createPlan(
        NewPlanInput(
          name: name,
          startYear: startYear,
          protagonistName: (first?['name'] as String?) ?? '本人',
          protagonistBirthDate: birth,
          protagonistLifeExpectancy: life,
        ),
      );
      result.planId = planId;
      final protagonist = (await (db.select(
        db.plans,
      )..where((x) => x.id.equals(planId))).getSingle()).protagonistMemberId;
      for (final m in members.skip(1)) {
        await db
            .into(db.familyMembers)
            .insert(
              FamilyMembersCompanion.insert(
                id: newId(),
                createdAt: now,
                updatedAt: now,
                updatedBy: stamp.deviceId,
                planId: planId,
                name: (m['name'] as String?) ?? '家族',
                relation: Relation.other.code,
                birthDate: _date(m['birthDate']) ?? '1990-01-01',
                lifeExpectancy: _int(m['lifeExpectancy']) ?? 90,
                sortOrder: members.indexOf(m),
              ),
            );
      }

      // カテゴリ・口座
      final catMap = <String, String>{};
      for (final c in p['categories'] as List? ?? const []) {
        if (c is! Map) continue;
        final kind = c['type'] == 'income' ? 'income' : 'expense';
        catMap['${c['id']}'] = await _category(
          '${c['name'] ?? '名称なし'}',
          kind,
          '${c['color'] ?? ''}',
          now,
        );
      }
      final accMap = <String, String>{};
      for (final a in p['accounts'] as List? ?? const []) {
        if (a is! Map) continue;
        accMap['${a['id']}'] = await _account(
          '${a['name'] ?? '名称なし'}',
          _int(a['initialBalance']) ?? 0,
          '$startYear-01-01',
          now,
        );
      }
      Future<String> anyAccount() async =>
          accMap.values.firstOrNull ??
          await _account('現金', 0, '$startYear-01-01', now);
      Future<String> categoryOr(
        String? legacyId,
        String kind,
        String fallback,
      ) async => catMap[legacyId] ?? await _category(fallback, kind, '', now);

      // 取引（年月の1日付の実績）
      for (final y in p['yearlyData'] as List? ?? const []) {
        if (y is! Map) continue;
        for (final t in y['transactions'] as List? ?? const []) {
          if (t is! Map) continue;
          final type = t['type'];
          final year = _int(t['year']) ?? _int(y['year']);
          final month = (_int(t['month']) ?? 1).clamp(1, 12);
          final amount = _int(t['amount']);
          if (year == null || amount == null || amount <= 0) {
            result.skipped++;
            continue;
          }
          if (type == 'investment') {
            result.skippedInvestment++;
            continue;
          }
          final kind = switch (type) {
            'income' => TxnKind.income,
            'transfer' => TxnKind.transfer,
            _ => TxnKind.expense,
          };
          final from = accMap['${t['fromAccountId']}'];
          final to = accMap['${t['toAccountId']}'];
          final account =
              (kind == TxnKind.income ? to ?? from : from ?? to) ??
              await anyAccount();
          final memo = [
            t['title'],
            t['description'],
          ].whereType<String>().where((s) => s.isNotEmpty).toSet().join('・');
          await db
              .into(db.txns)
              .insert(
                TxnsCompanion.insert(
                  id: newId(),
                  createdAt: now,
                  updatedAt: now,
                  updatedBy: stamp.deviceId,
                  planId: planId,
                  date: YearMonth(year, month).firstDayString,
                  kind: kind.code,
                  amount: amount,
                  categoryId: Value(
                    kind == TxnKind.transfer
                        ? null
                        : await categoryOr(
                            '${t['categoryId']}',
                            kind.code,
                            kind == TxnKind.income ? 'その他の収入' : 'その他',
                          ),
                  ),
                  accountId: account,
                  toAccountId: Value(
                    kind == TxnKind.transfer ? (to ?? account) : null,
                  ),
                  memo: Value(memo.isEmpty ? null : memo),
                ),
              );
          result.txns++;
        }
        // イベント（金額なし）
        for (final e in y['events'] as List? ?? const []) {
          if (e is! Map) continue;
          await db
              .into(db.planEvents)
              .insert(
                PlanEventsCompanion.insert(
                  id: newId(),
                  createdAt: now,
                  updatedAt: now,
                  updatedBy: stamp.deviceId,
                  planId: planId,
                  memberId: protagonist,
                  title: '${e['title'] ?? 'イベント'}',
                  year: _int(e['year']) ?? _int(y['year']) ?? startYear,
                  month: 1,
                  status: EventStatus.planned.code,
                  memo: Value(e['description'] as String?),
                ),
              );
          result.events++;
        }
      }

      // 資産：資産情報＋保有資産
      final infos = {
        for (final a in p['assetInfo'] as List? ?? const [])
          if (a is Map) '${a['id']}': a.cast<String, dynamic>(),
      };
      final stockCat = await _category('株式・投資信託', 'asset', '', now);
      final buyCat = await _category('その他', 'expense', '', now);
      final sellCat = await _category('譲渡所得', 'income', '', now);
      final divCat = await _category('配当所得', 'income', '', now);
      for (final h in p['holdingAssets'] as List? ?? const []) {
        if (h is! Map) continue;
        final info = infos['${h['assetId']}'];
        final qty = (h['quantity'] as num?)?.toDouble();
        final buyYear = _int(h['purchaseYear']);
        if (info == null || qty == null || buyYear == null) {
          result.skipped++;
          continue;
        }
        final assetId = newId();
        final account = accMap['${h['accountId']}'] ?? await anyAccount();
        await db
            .into(db.assets)
            .insert(
              AssetsCompanion.insert(
                id: assetId,
                createdAt: now,
                updatedAt: now,
                updatedBy: stamp.deviceId,
                planId: planId,
                name: '${info['name'] ?? '資産'}',
                categoryId: stockCat,
                valuation: Valuation.quantity.code,
                code: Value(info['symbol'] as String?),
                accountId: Value(account),
                sortOrder: result.assets,
              ),
            );
        result.assets++;
        final prices = <int, num>{
          for (final x in info['priceHistory'] as List? ?? const [])
            if (x is Map && _int(x['year']) != null && x['price'] is num)
              _int(x['year'])!: x['price'] as num,
        };
        for (final e in prices.entries) {
          await db
              .into(db.assetValues)
              .insertOnConflictUpdate(
                AssetValuesCompanion.insert(
                  id: assetValueId(assetId, '${e.key}-01'),
                  createdAt: now,
                  updatedAt: now,
                  updatedBy: stamp.deviceId,
                  assetId: assetId,
                  unit: 'month',
                  valueDate: '${e.key.toString().padLeft(4, '0')}-01',
                  valueX100: (e.value * 100).round(),
                ),
              );
        }
        final points = [
          for (final e in prices.entries)
            ValuePoint(
              unit: 'month',
              date: '${e.key.toString().padLeft(4, '0')}-01',
              valueX100: (e.value * 100).round(),
            ),
        ];
        final q = (qty * 10000).round();
        Future<void> move(AssetAction action, int year) async {
          final price = valueAt(points, '$year-01-01') ?? 0;
          await db
              .into(db.txns)
              .insert(
                TxnsCompanion.insert(
                  id: newId(),
                  createdAt: now,
                  updatedAt: now,
                  updatedBy: stamp.deviceId,
                  planId: planId,
                  date: '$year-01-01',
                  kind: action == AssetAction.buy
                      ? TxnKind.expense.code
                      : TxnKind.income.code,
                  amount: amountForQuantity(q, price),
                  categoryId: Value(
                    action == AssetAction.buy ? buyCat : sellCat,
                  ),
                  accountId: account,
                  assetId: Value(assetId),
                  assetAction: Value(action.code),
                  quantityX1e4: Value(q),
                  memo: const Value('参考アプリから移行'),
                ),
              );
          result.txns++;
        }

        await move(AssetAction.buy, buyYear);
        final sellYear = _int(h['sellYear']);
        if (sellYear != null) await move(AssetAction.sell, sellYear);
        // 配当：保有している年ごとに、数量×1株あたり配当を各年12月31日の収益に
        for (final d in info['dividendHistory'] as List? ?? const []) {
          if (d is! Map) continue;
          final y = _int(d['year']);
          final per = d['dividendPerShare'];
          if (y == null ||
              per is! num ||
              y < buyYear ||
              (sellYear != null && y >= sellYear)) {
            continue;
          }
          final amount = floorYen(qty * per);
          if (amount <= 0) continue;
          await db
              .into(db.txns)
              .insert(
                TxnsCompanion.insert(
                  id: newId(),
                  createdAt: now,
                  updatedAt: now,
                  updatedBy: stamp.deviceId,
                  planId: planId,
                  date: '$y-12-31',
                  kind: TxnKind.income.code,
                  amount: amount,
                  categoryId: Value(divCat),
                  accountId: account,
                  assetId: Value(assetId),
                  assetAction: Value(AssetAction.income.code),
                  memo: const Value('配当（参考アプリから移行）'),
                ),
              );
          result.txns++;
        }
      }

      // テンプレート（グループは作らない）
      for (final t in p['templates'] as List? ?? const []) {
        if (t is! Map || t['type'] == 'investment') continue;
        final kind = t['type'] == 'income' ? TxnKind.income : TxnKind.expense;
        await db
            .into(db.templates)
            .insert(
              TemplatesCompanion.insert(
                id: newId(),
                createdAt: now,
                updatedAt: now,
                updatedBy: stamp.deviceId,
                name: '${t['name'] ?? 'テンプレート'}',
                kind: kind.code,
                amount: Value(_int(t['amount'])),
                categoryId: Value(catMap['${t['categoryId']}']),
                accountId: Value(accMap['${t['accountId']}']),
                memo: Value(t['description'] as String?),
                growthMode: GrowthMode.category.code,
              ),
            );
        result.templates++;
      }

      // 起点は取り込んだ日の実績から計算し直す
      final repo = PlanRepository(db, stamp);
      await repo.writeAccountBaselines(planId, todayString());
      await repo.writeAssetBaselines(planId, todayString());
      return result;
    });
  }

  Future<String> _category(
    String name,
    String kind,
    String color,
    String now,
  ) async {
    final found =
        await (db.select(db.categories)..where(
              (c) =>
                  c.name.equals(name) &
                  c.kind.equals(kind) &
                  c.deletedAt.isNull(),
            ))
            .get();
    if (found.isNotEmpty) return found.first.id;
    final id = newId();
    final m = db.categories.sortOrder.max();
    final order =
        ((await (db.selectOnly(
              db.categories,
            )..addColumns([m])).getSingle()).read(m) ??
            -1) +
        1;
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            updatedBy: stamp.deviceId,
            name: name,
            kind: kind,
            color: normalizePaletteColor(color),
            defaultValuation: Value(
              kind == 'asset' ? Valuation.quantity.code : null,
            ),
            saleTaxDefault: Value(kind == 'asset' ? 1 : null),
            sortOrder: order,
          ),
        );
    return id;
  }

  Future<String> _account(
    String name,
    int initial,
    String date,
    String now,
  ) async {
    final found = await (db.select(
      db.accounts,
    )..where((a) => a.name.equals(name) & a.deletedAt.isNull())).get();
    if (found.isNotEmpty) return found.first.id;
    final id = newId();
    final m = db.accounts.sortOrder.max();
    final order =
        ((await (db.selectOnly(
              db.accounts,
            )..addColumns([m])).getSingle()).read(m) ??
            -1) +
        1;
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            updatedBy: stamp.deviceId,
            name: name,
            kind: AccountKind.other.code,
            initialBalance: initial,
            initialDate: date,
            sortOrder: order,
          ),
        );
    return id;
  }
}

class LegacyResult {
  String? planId;
  int txns = 0;
  int events = 0;
  int assets = 0;
  int templates = 0;

  /// 取り込めなかった取引・保有資産
  int skipped = 0;

  /// 保有資産の購入実績と重なるため取り込まなかった投資の取引
  int skippedInvestment = 0;
}

int? _int(Object? v) =>
    v is int ? v : (v is num && v == v.roundToDouble() ? v.toInt() : null);

String? _date(Object? v) {
  if (v is! String || v.length < 10) return null;
  final s = v.substring(0, 10);
  return DateTime.tryParse(s) == null ? null : s;
}
