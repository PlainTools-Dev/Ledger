// logic/month_utils.dart

/// Utility functions for working with "YYYY-MM" month keys, ported
/// directly from the PWA's monthKey/monthLabel/shiftKey/billDateFor
/// functions — these get called constantly throughout the app, so
/// worth keeping the exact same semantics as the original.
class MonthUtils {
  /// Port of JS `monthKey(d)`.
  static String keyFor(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
  }

  /// Port of JS `monthLabel(k)` — e.g. "July 2026".
  static String label(String monthKey) {
    final year = int.parse(monthKey.substring(0, 4));
    final month = int.parse(monthKey.substring(5, 7));
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[month - 1]} $year';
  }

  /// Port of JS `shiftKey(k, delta)` — move forward/back by [delta] months.
  static String shift(String monthKey, int delta) {
    var year = int.parse(monthKey.substring(0, 4));
    var month = int.parse(monthKey.substring(5, 7)) + delta;
    while (month > 12) {
      month -= 12;
      year += 1;
    }
    while (month < 1) {
      month += 12;
      year -= 1;
    }
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  /// Port of JS `daysInMonth(k)`.
  static int daysInMonth(String monthKey) {
    final year = int.parse(monthKey.substring(0, 4));
    final month = int.parse(monthKey.substring(5, 7));
    return DateTime(year, month + 1, 0).day;
  }

  /// Port of JS `billDateFor(k, day)` — clamps the bill's posting day
  /// to a valid date within the given month (e.g. day 31 in February
  /// becomes the 28th/29th).
  static String billDateFor(String monthKey, int day) {
    final clamped = day.clamp(1, daysInMonth(monthKey));
    return '$monthKey-${clamped.toString().padLeft(2, '0')}';
  }

  /// Port of JS `todayISO()`.
  static String todayISO() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
