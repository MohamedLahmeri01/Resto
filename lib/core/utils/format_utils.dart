import 'package:intl/intl.dart';

class FormatUtils {
  static String money(int cents, {String currency = 'DA'}) {
    final amount = cents / 100;
    return '${amount.toStringAsFixed(0)} $currency';
  }

  static String moneyDecimal(int cents, {String currency = 'DA'}) {
    final amount = cents / 100;
    return '${amount.toStringAsFixed(2)} $currency';
  }

  static String date(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String time(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String dateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }

  static String duration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
