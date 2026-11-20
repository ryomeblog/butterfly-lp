import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../core/money.dart';
import '../../domain/models/enums.dart';
import 'database.dart';

/// 初期データの更新日時。どの端末で作っても同じ行・同じ日時にし、
/// 利用者が編集・削除した行（新しい日時）が同期で必ず勝つようにする。
const seedTimestamp = '1970-01-01T00:00:00.000Z';
const seedDeviceId = 'seed';

/// 初期カテゴリ（設計書 3.1）。
const initialExpenseCategories = [
  '食費',
  '消耗品',
  '耐久消耗品',
  '交際費',
  '住居費',
  '水道光熱費',
  '通信費',
  '保険',
  '税金',
  'その他',
];

const initialIncomeCategories = [
  '利子所得',
  '配当所得',
  '不動産所得',
  '事業所得',
  '給与所得',
  '退職所得',
  '山林所得',
  '譲渡所得',
  '一時所得',
  '雑所得',
];

/// 初期の資産カテゴリ：名前・既定の評価のしかた・売却時に税の初期値を出すか。
const initialAssetCategories = [
  ('株式・投資信託', Valuation.quantity, true),
  ('不動産', Valuation.value, false),
  ('車・持ち物', Valuation.value, false),
];

/// DB を新しく作ったときに1回だけ呼ぶ。世帯設定と初期カテゴリを入れる。
Future<void> seedInitialData(AppDatabase db) async {
  await db.batch((b) {
    b.insert(
      db.household,
      HouseholdCompanion.insert(
        id: householdId,
        createdAt: seedTimestamp,
        updatedAt: seedTimestamp,
        updatedBy: seedDeviceId,
        schemaVersion: currentSchemaVersion,
      ),
    );

    void addCategory(
      CategoryKind kind,
      String name,
      int order, {
      Valuation? valuation,
      bool? saleTax,
    }) {
      b.insert(
        db.categories,
        CategoriesCompanion.insert(
          id: seedId('category:${kind.code}:$name'),
          createdAt: seedTimestamp,
          updatedAt: seedTimestamp,
          updatedBy: seedDeviceId,
          name: name,
          kind: kind.code,
          color: categoryPalette[order % categoryPalette.length],
          defaultValuation: Value(valuation?.code),
          saleTaxDefault: Value(saleTax == null ? null : (saleTax ? 1 : 0)),
          sortOrder: order,
        ),
      );
    }

    for (final (i, name) in initialExpenseCategories.indexed) {
      addCategory(CategoryKind.expense, name, i);
    }
    for (final (i, name) in initialIncomeCategories.indexed) {
      addCategory(CategoryKind.income, name, i);
    }
    for (final (i, (name, valuation, saleTax))
        in initialAssetCategories.indexed) {
      addCategory(
        CategoryKind.asset,
        name,
        i,
        valuation: valuation,
        saleTax: saleTax,
      );
    }
  });
}
