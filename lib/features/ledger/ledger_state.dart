import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time.dart';
import '../../domain/calc/ledger.dart';
import '../../domain/models/enums.dart';

/// 家計簿の上部の切り替え（設計書 3.1・7.1）。
enum LedgerMode { actual, plan, compare }

enum LedgerView { breakdown, list, calendar }

enum LedgerUnit { year, month }

/// 年表示でカテゴリのアコーディオンを開いたときの表示。
enum YearOpenMode { monthly, each }

class LedgerState {
  const LedgerState({
    required this.ym,
    this.mode = LedgerMode.actual,
    this.view = LedgerView.breakdown,
    this.unit = LedgerUnit.year,
    this.pieKind = TxnKind.expense,
    this.yearOpenMode = YearOpenMode.monthly,
    this.filter,
  });

  /// 表示中の年月（年表示では年だけを使う）
  final YearMonth ym;
  final LedgerMode mode;
  final LedgerView view;
  final LedgerUnit unit;

  /// 円グラフ・内訳の種類（支出／収入）
  final TxnKind pieKind;
  final YearOpenMode yearOpenMode;

  /// リストの絞り込み。null なら表示中の月だけ
  final LedgerFilter? filter;

  LedgerFilter get listFilter => filter ?? LedgerFilter.month(ym);

  /// 内訳の期間
  String get from =>
      unit == LedgerUnit.year ? '${ym.year}-01-01' : ym.firstDayString;
  String get to =>
      unit == LedgerUnit.year ? '${ym.year}-12-31' : ym.lastDayString;

  LedgerState copyWith({
    YearMonth? ym,
    LedgerMode? mode,
    LedgerView? view,
    LedgerUnit? unit,
    TxnKind? pieKind,
    YearOpenMode? yearOpenMode,
    LedgerFilter? Function()? filter,
  }) => LedgerState(
    ym: ym ?? this.ym,
    mode: mode ?? this.mode,
    view: view ?? this.view,
    unit: unit ?? this.unit,
    pieKind: pieKind ?? this.pieKind,
    yearOpenMode: yearOpenMode ?? this.yearOpenMode,
    filter: filter != null ? filter() : this.filter,
  );
}

class LedgerController extends Notifier<LedgerState> {
  @override
  LedgerState build() => LedgerState(ym: YearMonth.ofDate(clock.now()));

  void set(LedgerState s) => state = s;

  /// 前後の年・月へ。
  void shift(int delta) {
    final months =
        state.view == LedgerView.breakdown && state.unit == LedgerUnit.year
        ? 12 * delta
        : delta;
    state = state.copyWith(ym: state.ym.addMonths(months), filter: () => null);
  }

  /// 年表示の「月ごと」から月を選ぶと、その月の表示へ。
  void openMonth(int month) => state = state.copyWith(
    ym: YearMonth(state.ym.year, month),
    unit: LedgerUnit.month,
  );

  /// 「すべて表示」：そのカテゴリ・その年で絞り込んだリストへ。
  void openListFor({
    required String? categoryId,
    required String from,
    required String to,
  }) => state = state.copyWith(
    view: LedgerView.list,
    filter: () => LedgerFilter(from: from, to: to, categoryIds: {?categoryId}),
  );
}

final ledgerProvider = NotifierProvider<LedgerController, LedgerState>(
  LedgerController.new,
);

/// 家計簿のリストで選んだ実績（予定のリストでは計画行）のID（空なら選択モードではない）。
/// 選択中は右下の入力ボタンを隠し、画面下に登録の帯を出す。
class TxnSelection extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String id) =>
      state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};

  void addAll(Iterable<String> ids) => state = {...state, ...ids};

  void clear() {
    // 画面を閉じたあと（あとで呼ばれる）にアプリごと破棄されていることがある
    if (ref.mounted) state = const {};
  }
}

final txnSelectionProvider = NotifierProvider<TxnSelection, Set<String>>(
  TxnSelection.new,
);
