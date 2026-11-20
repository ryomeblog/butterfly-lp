/// DB に文字列で保存する種類の定義。`code` が保存値、`label` が画面の表示名。
library;

enum TxnKind {
  income('income', '収入'),
  expense('expense', '支出'),
  transfer('transfer', '振替');

  const TxnKind(this.code, this.label);
  final String code;
  final String label;
  static TxnKind of(String code) => values.firstWhere((e) => e.code == code);
}

enum AccountKind {
  cash('cash', '現金'),
  bank('bank', '銀行'),
  securities('securities', '証券'),
  other('other', 'その他');

  const AccountKind(this.code, this.label);
  final String code;
  final String label;
  static AccountKind of(String code) =>
      values.firstWhere((e) => e.code == code);

  /// 資金不足の判定に使う現金系口座（設計書 6.5）。
  bool get isCashLike => this != AccountKind.securities;
}

enum CategoryKind {
  expense('expense', '支出'),
  income('income', '収入'),
  asset('asset', '資産');

  const CategoryKind(this.code, this.label);
  final String code;
  final String label;
  static CategoryKind of(String code) =>
      values.firstWhere((e) => e.code == code);
}

enum Valuation {
  quantity('quantity', '数量×単価'),
  value('value', '評価額');

  const Valuation(this.code, this.label);
  final String code;
  final String label;
  static Valuation of(String code) => values.firstWhere((e) => e.code == code);
}

enum AssetAction {
  buy('buy', '購入'),
  sell('sell', '売却'),
  income('income', '収益'),
  cost('cost', '費用');

  const AssetAction(this.code, this.label);
  final String code;
  final String label;
  static AssetAction of(String code) =>
      values.firstWhere((e) => e.code == code);
}

enum Relation {
  self('self', '本人'),
  spouse('spouse', '配偶者'),
  child('child', '子'),
  parent('parent', '親'),
  other('other', 'その他');

  const Relation(this.code, this.label);
  final String code;
  final String label;
  static Relation of(String code) => values.firstWhere((e) => e.code == code);
}

enum PlanLineSource {
  manual('manual', '手入力'),
  group('group', 'グループ'),
  event('event', 'イベント');

  const PlanLineSource(this.code, this.label);
  final String code;
  final String label;
  static PlanLineSource of(String code) =>
      values.firstWhere((e) => e.code == code);
}

enum GrowthMode {
  category('category', 'カテゴリの率'),
  template('template', 'このテンプレートの率'),
  none('none', '上昇なし');

  const GrowthMode(this.code, this.label);
  final String code;
  final String label;
  static GrowthMode of(String code) => values.firstWhere((e) => e.code == code);
}

enum AmountMode {
  fixed('fixed', '固定額'),
  percent('percent', '別の項目の○%');

  const AmountMode(this.code, this.label);
  final String code;
  final String label;
  static AmountMode of(String code) => values.firstWhere((e) => e.code == code);
}

enum Frequency {
  monthly('monthly', '毎月'),
  yearly('yearly', '毎年'),
  everyNMonths('every_n_months', 'Nか月ごと'),
  everyNYears('every_n_years', 'N年ごと'),
  weekly('weekly', '毎週'),
  specificMonths('specific_months', '特定の月のみ');

  const Frequency(this.code, this.label);
  final String code;
  final String label;
  static Frequency of(String code) => values.firstWhere((e) => e.code == code);
}

enum EventStatus {
  planned('planned', '予定'),
  done('done', '実施済み');

  const EventStatus(this.code, this.label);
  final String code;
  final String label;
  static EventStatus of(String code) =>
      values.firstWhere((e) => e.code == code);
}

/// plan_rate / plan_baseline の target_type。
abstract final class TargetType {
  static const account = 'account';
  static const asset = 'asset';
  static const category = 'category';
}
