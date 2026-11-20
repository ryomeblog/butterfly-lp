import 'package:clock/clock.dart';

/// 日付まわりの共通処理。「今日」は必ず [clock] から取り、テストで差し替えられるようにする。

String _two(int v) => v.toString().padLeft(2, '0');
String _three(int v) => v.toString().padLeft(3, '0');

/// `updated_at` 用。UTC のミリ秒付き ISO8601（例 `2026-11-20T01:02:03.456Z`）。
String timestampOf(DateTime t) {
  final u = t.toUtc();
  return '${u.year.toString().padLeft(4, '0')}-${_two(u.month)}-${_two(u.day)}'
      'T${_two(u.hour)}:${_two(u.minute)}:${_two(u.second)}.${_three(u.millisecond)}Z';
}

String nowTimestamp() => timestampOf(clock.now());

/// `YYYY-MM-DD`（端末のローカル日付）。
String dateString(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

String todayString() => dateString(clock.now());

DateTime parseDate(String yyyyMmDd) {
  final p = yyyyMmDd.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// 年月（`YYYY-MM`）。比較・加算できる値オブジェクト。
class YearMonth implements Comparable<YearMonth> {
  const YearMonth(this.year, this.month) : assert(month >= 1 && month <= 12);

  factory YearMonth.parse(String ym) {
    final p = ym.split('-');
    return YearMonth(int.parse(p[0]), int.parse(p[1]));
  }

  factory YearMonth.ofDate(DateTime d) => YearMonth(d.year, d.month);

  factory YearMonth.ofDateString(String yyyyMmDd) =>
      YearMonth.parse(yyyyMmDd.substring(0, 7));

  final int year;
  final int month;

  /// 0年1月からの通し番号。差の計算に使う。
  int get index => year * 12 + (month - 1);

  YearMonth addMonths(int n) {
    final i = index + n;
    return YearMonth(i ~/ 12, i % 12 + 1);
  }

  int monthsUntil(YearMonth other) => other.index - index;

  DateTime get firstDay => DateTime(year, month, 1);
  DateTime get lastDay => DateTime(year, month + 1, 0);
  int get daysInMonth => lastDay.day;

  String get firstDayString => dateString(firstDay);
  String get lastDayString => dateString(lastDay);

  @override
  String toString() => '${year.toString().padLeft(4, '0')}-${_two(month)}';

  @override
  int compareTo(YearMonth other) => index.compareTo(other.index);

  bool operator <(YearMonth o) => index < o.index;
  bool operator <=(YearMonth o) => index <= o.index;
  bool operator >(YearMonth o) => index > o.index;
  bool operator >=(YearMonth o) => index >= o.index;

  @override
  bool operator ==(Object other) => other is YearMonth && other.index == index;

  @override
  int get hashCode => index.hashCode;
}

/// 生年月日から、ある日付時点の満年齢を求める。
int ageAt(String birthDate, DateTime on) {
  final b = parseDate(birthDate);
  var age = on.year - b.year;
  if (on.month < b.month || (on.month == b.month && on.day < b.day)) age--;
  return age;
}
