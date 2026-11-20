import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:butterfly_lp/data/repositories/txn_repository.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late TxnRepository repo;

  setUp(() {
    db = memoryDb();
    repo = TxnRepository(db, const Stamp(testDeviceId));
  });
  tearDown(() => db.close());

  TxnInput input(String plan, String date, {TxnKind kind = TxnKind.expense}) =>
      TxnInput(
        planId: plan,
        date: date,
        kind: kind,
        amount: 1000,
        accountId: 'bank',
        categoryId: 'food',
        toAccountId: 'sec',
      );

  test('プランと期間で絞り込み、新しい順に返す', () async {
    await repo.createTxn(input('A', '2026-01-10'));
    await repo.createTxn(input('A', '2026-02-10'));
    await repo.createTxn(input('A', '2026-03-10'));
    await repo.createTxn(input('B', '2026-02-11'));
    final rows = await repo
        .watchTxns('A', from: '2026-02-01', to: '2026-12-31')
        .first;
    expect(rows.map((r) => r.date), ['2026-03-10', '2026-02-10']);
  });

  test('支出はカテゴリを持ち入金先を持たない／振替はカテゴリを持たない', () async {
    final e = await repo.createTxn(input('A', '2026-01-10'));
    final t = await repo.createTxn(
      input('A', '2026-01-10', kind: TxnKind.transfer),
    );
    final er = (await repo.getTxn(e))!;
    final tr = (await repo.getTxn(t))!;
    expect(er.categoryId, 'food');
    expect(er.toAccountId, isNull);
    expect(tr.categoryId, isNull);
    expect(tr.toAccountId, 'sec');
  });

  test('更新しても資産・グループの記録は変えない', () async {
    final id = await repo.createTxn(input('A', '2026-01-10'));
    await (db.update(db.txns)..where((t) => t.id.equals(id))).write(
      const TxnsCompanion(groupItemId: Value('item1'), entryId: Value('e1')),
    );
    await repo.updateTxn(
      id,
      const TxnInput(
        planId: 'A',
        date: '2026-01-11',
        kind: TxnKind.expense,
        amount: 2000,
        accountId: 'bank',
        categoryId: 'food',
      ),
    );
    final r = (await repo.getTxn(id))!;
    expect(r.amount, 2000);
    expect(r.date, '2026-01-11');
    expect(r.groupItemId, 'item1');
    expect(r.entryId, 'e1');
    expect(r.updatedBy, testDeviceId);
  });

  test('削除は墓石', () async {
    final id = await repo.createTxn(input('A', '2026-01-10'));
    await repo.deleteTxn(id);
    expect(await repo.watchTxns('A').first, isEmpty);
    expect((await repo.getTxn(id))!.deletedAt, isNotNull);
  });
}
