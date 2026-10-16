import 'dart:math';

/// مفتاحٌ فريد من الإصدار الرابع (RFC 4122) — `3f2b…-4…-a…`. نسخةُ تطبيق الموظفين نفسها.
///
/// **يرافق طلب كتابةٍ مالية** — الدفعُ من المحفظة — فيعرف به الخادمُ الإعادةَ فلا يسجّلها مرّتين.
/// ستّ عشرة بايتاً من [Random.secure] تكفيه، وحزمةٌ كاملة لسطرين اعتمادٌ بلا مقابل.
///
/// [random] للاختبار وحده؛ في التطبيق يُترك فيكون المصدرَ الآمن.
String uuidV4([Random? random]) {
  final source = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => source.nextInt(256));

  // الإصدار في النصف الأعلى من البايت السابع، والنوع (10xx) في أعلى الثامن.
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  final hex = [for (final byte in bytes) byte.toRadixString(16).padLeft(2, '0')].join();

  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}
