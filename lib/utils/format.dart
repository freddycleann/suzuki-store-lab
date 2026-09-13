import 'package:intl/intl.dart';

final _thb = NumberFormat('#,##0', 'en_US');

String formatThb(num value) => '฿${_thb.format(value)}';

String formatDate(DateTime date) => DateFormat('EEE, d MMM yyyy').format(date);

/// Lower-case alphanumerics only, so "V-Strom 800DE" matches "vstrom800de".
String normalizeModel(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

String formatKm(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  if (km < 10) return '${km.toStringAsFixed(1)} km';
  return '${km.round()} km';
}

String shortReference(String id) =>
    (id.length > 8 ? id.substring(id.length - 8) : id).toUpperCase();
