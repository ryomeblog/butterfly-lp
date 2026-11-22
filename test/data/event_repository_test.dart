import 'package:butterfly_lp/data/db/database.dart';
import 'package:butterfly_lp/data/repositories/asset_repository.dart';
import 'package:butterfly_lp/data/repositories/event_repository.dart';
import 'package:butterfly_lp/data/repositories/stamp.dart';
import 'package:butterfly_lp/domain/calc/event_matching.dart';
import 'package:butterfly_lp/domain/models/enums.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late EventRepository repo;
  const stamp = Stamp(testDeviceId);

  setUp(() {
    db = memoryDb();
    repo = EventRepository(db, stamp);
  });
  tearDown(() => db.close());

  const input = EventInput(
    planId: 'p',
    memberId: 'm',
    title: '住宅購入',
    year: 2030,
    month: 3,
  );

  Future<List<PlanLineRow>> liveLines() =>
      (db.select(db.planLines)..where((l) => l.deletedAt.isNull())).get();

  test('予定の収支は source=event の計画行として、イベントの年月に置く', () async {
    final id = await repo.saveEvent(
      input: input,
      lines: [
        EventLineDraft(
          id: 'l1',
          kind: TxnKind.expense,
          amount: 5000000,
          accountId: 'bank',
          categoryId: 'house',
        ),
        EventLineDraft(
          id: 'l2',
          kind: TxnKind.expense,
          amount: 300000,
          accountId: 'bank',
          categoryId: 'other',
        ),
      ],
    );
    final lines = await liveLines();
    expect(lines, hasLength(2));
    expect(
      lines.every(
        (l) =>
            l.source == 'event' &&
            l.sourceId == id &&
            l.eventId == id &&
            l.memberId == 'm' &&
            l.year == 2030 &&
            l.month == 3,
      ),
      isTrue,
    );
    final e = (await repo.getEvent(id))!;
    expect((e.status, e.day), ('planned', null));
  });

  test('年月を変えると予定も移り、外した行は削除する', () async {
    final id = await repo.saveEvent(
      input: input,
      lines: [
        EventLineDraft(
          id: 'l1',
          kind: TxnKind.expense,
          amount: 1,
          accountId: 'bank',
          categoryId: 'a',
        ),
        EventLineDraft(
          id: 'l2',
          kind: TxnKind.expense,
          amount: 2,
          accountId: 'bank',
          categoryId: 'b',
        ),
      ],
    );
    await repo.saveEvent(
      eventId: id,
      input: const EventInput(
        planId: 'p',
        memberId: 'm',
        title: '住宅購入',
        year: 2031,
        month: 4,
        day: 20,
      ),
      lines: [
        EventLineDraft(
          id: 'l1',
          kind: TxnKind.expense,
          amount: 10,
          accountId: 'bank',
          categoryId: 'a',
        ),
      ],
    );
    final lines = await liveLines();
    expect(lines.single.id, 'l1');
    expect(
      (lines.single.year, lines.single.month, lines.single.amount),
      (2031, 4, 10),
    );
    expect((await repo.getEvent(id))!.day, 20);
  });

  test('実績を入力：event_id 付きの実績になり、実施済みにする。予定と突き合わせると入力済み', () async {
    final id = await repo.saveEvent(
      input: input,
      lines: [
        EventLineDraft(
          id: 'l1',
          kind: TxnKind.expense,
          amount: 5000000,
          accountId: 'bank',
          categoryId: 'house',
        ),
        EventLineDraft(
          id: 'l2',
          kind: TxnKind.expense,
          amount: 300000,
          accountId: 'bank',
          categoryId: 'other',
        ),
      ],
    );
    final e = (await repo.getEvent(id))!;
    expect(EventRepository.plannedDate(e), '2030-03-01');
    await repo.recordActual(
      event: e,
      doneDate: '2030-04-02',
      items: const [
        EventActualItem(
          kind: TxnKind.expense,
          amount: 4900000,
          accountId: 'bank',
          categoryId: 'house',
        ),
      ],
      markDone: true,
    );
    final t = await db.select(db.txns).getSingle();
    expect((t.eventId, t.date, t.amount), (id, '2030-04-02', 4900000));
    final done = (await repo.getEvent(id))!;
    expect((done.status, done.doneDate), ('done', '2030-04-02'));

    // 予定と違う月に実施しても対応づく（設計書 6.8）
    final actuals = eventLineActuals(
      [for (final l in await liveLines()) matchItemOfLine(l)],
      [matchItemOfTxn(t)],
    );
    expect(actuals, {'l1': 4900000, 'l2': 0});
  });

  test('資産の購入：数量×単価は実施日の単価で数量を、評価額は価値を記録する', () async {
    final assets = AssetRepository(db, stamp);
    final stock = await assets.createAsset(
      const AssetInput(
        planId: 'p',
        name: 'A',
        categoryId: 'k',
        valuation: Valuation.quantity,
      ),
    );
    final home = await assets.createAsset(
      const AssetInput(
        planId: 'p',
        name: '自宅',
        categoryId: 'k',
        valuation: Valuation.value,
      ),
    );
    await assets.setValue(stock, 'month', '2030-03', 200000);
    final id = await repo.saveEvent(input: input, lines: const []);
    await repo.recordActual(
      event: (await repo.getEvent(id))!,
      doneDate: '2030-03-20',
      items: [
        EventActualItem(
          kind: TxnKind.expense,
          amount: 30000,
          accountId: 'bank',
          categoryId: 'c',
          assetId: stock,
          assetAction: AssetAction.buy,
        ),
        EventActualItem(
          kind: TxnKind.expense,
          amount: 35000000,
          accountId: 'bank',
          categoryId: 'c',
          assetId: home,
          assetAction: AssetAction.buy,
        ),
      ],
      markDone: false,
    );
    final txns = await db.select(db.txns).get();
    expect(txns.firstWhere((t) => t.assetId == stock).quantityX1e4, 150000);
    final v = await (db.select(
      db.assetValues,
    )..where((v) => v.assetId.equals(home))).getSingle();
    expect((v.valueDate, v.valueX100), ('2030-03-20', 3500000000));
    expect((await repo.getEvent(id))!.status, 'planned');
  });

  test('削除：予定の収支は削除、実績と手入力の予定はイベントとの関連だけ外す', () async {
    final id = await repo.saveEvent(
      input: input,
      lines: [
        EventLineDraft(
          id: 'l1',
          kind: TxnKind.expense,
          amount: 1,
          accountId: 'bank',
          categoryId: 'a',
        ),
      ],
    );
    await repo.recordActual(
      event: (await repo.getEvent(id))!,
      doneDate: '2030-03-01',
      items: const [
        EventActualItem(
          kind: TxnKind.expense,
          amount: 1,
          accountId: 'bank',
          categoryId: 'a',
        ),
      ],
      markDone: true,
    );
    await db
        .into(db.planLines)
        .insert(
          PlanLinesCompanion.insert(
            id: 'manual',
            createdAt: 'x',
            updatedAt: 'x',
            updatedBy: 'x',
            planId: 'p',
            year: 2030,
            month: 3,
            kind: 'expense',
            amount: 5,
            accountId: 'bank',
            source: 'manual',
            eventId: Value(id),
          ),
        );

    await repo.deleteEvent(id);

    final lines = await liveLines();
    expect(lines.single.id, 'manual');
    expect(lines.single.eventId, isNull);
    final t = await db.select(db.txns).getSingle();
    expect((t.deletedAt, t.eventId), (null, null));
    expect((await repo.getEvent(id))!.deletedAt, isNotNull);
  });
}
