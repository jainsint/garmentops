/// IST (Indian Standard Time) Utilities
/// All date/time operations in Jains Int are hardcoded to IST (UTC+5:30)
/// regardless of the device's local timezone.
library;

class ISTUtils {
  static const Duration _istOffset = Duration(hours: 5, minutes: 30);

  /// Returns the current DateTime in IST.
  static DateTime now() {
    return DateTime.now().toUtc().add(_istOffset);
  }

  /// Returns today's date in IST as a DateTime with time zeroed out.
  static DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Returns today's date as a string "YYYY-MM-DD" in IST.
  static String todayString() {
    final n = now();
    return '${n.year}-${_pad(n.month)}-${_pad(n.day)}';
  }

  /// Converts a UTC DateTime to IST DateTime.
  static DateTime toIST(DateTime utc) {
    return utc.toUtc().add(_istOffset);
  }

  /// Parses an ISO-8601 string (with or without timezone) and returns IST DateTime.
  static DateTime? parseToIST(String? s) {
    if (s == null || s.isEmpty) return null;
    final dt = DateTime.tryParse(s);
    if (dt == null) return null;
    // If the string has no timezone info, treat it as UTC
    if (dt.isUtc || s.contains('Z') || s.contains('+') || s.contains('-', 10)) {
      return dt.toUtc().add(_istOffset);
    }
    // Naive datetime — assume UTC and convert
    return DateTime.utc(
      dt.year,
      dt.month,
      dt.day,
      dt.hour,
      dt.minute,
      dt.second,
    ).add(_istOffset);
  }

  /// Returns a human-readable relative time string based on IST "now".
  /// e.g. "Just now", "5m ago", "2h ago", "3d ago"
  static String relativeTime(DateTime istTimestamp) {
    final diff = now().difference(istTimestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Returns "Today HH:mm" or "DD MMM HH:mm" based on IST.
  static String formatTimestamp(DateTime istTimestamp) {
    final t = today();
    final d = DateTime(istTimestamp.year, istTimestamp.month, istTimestamp.day);
    final hm = '${_pad(istTimestamp.hour)}:${_pad(istTimestamp.minute)}';
    if (d == t) return 'Today $hm';
    return '${_pad(istTimestamp.day)} ${_monthAbbr(istTimestamp.month)} $hm';
  }

  /// Days remaining from today (IST) to a delivery date string "YYYY-MM-DD".
  static int daysUntilDelivery(String? deliveryDateStr) {
    if (deliveryDateStr == null || deliveryDateStr.isEmpty) return 0;
    final delivery = DateTime.tryParse(deliveryDateStr);
    if (delivery == null) return 0;
    final deliveryDay = DateTime(delivery.year, delivery.month, delivery.day);
    return deliveryDay.difference(today()).inDays;
  }

  /// Returns a DateTime for the start of the current IST week (Monday).
  static DateTime startOfWeek() {
    final t = today();
    final weekday = t.weekday; // 1=Mon, 7=Sun
    return t.subtract(Duration(days: weekday - 1));
  }

  /// Returns a list of 6 consecutive days centered around today (IST):
  /// [today-2, today-1, today, today+1, today+2, today+3]
  static List<DateTime> weekStrip() {
    final t = today();
    return List.generate(
      6,
      (i) => t.subtract(const Duration(days: 2)).add(Duration(days: i)),
    );
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static String _monthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  static String dayAbbr(int weekday) {
    const abbrs = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return abbrs[weekday - 1];
  }
}
