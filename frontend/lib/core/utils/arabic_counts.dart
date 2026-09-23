/// العددُ والمعدود في جملةٍ عربية — في موضعٍ واحد.
///
/// «منذ 2 يوم» و«3 طلبية» جملتان لا يقولهما أحد. القاعدةُ التي تكفي ما يعدّه هذا التطبيق:
/// الواحدُ والاثنان كلمتان، ومن الثلاثة إلى العشرة جمع، وما فوقها مفردٌ منصوب. وبعد المئة يقرّر
/// الرقمان الأخيران: «103 أيام» و«111 يوماً».
///
/// **والأرقامُ لاتينية** كسائر أرقام التطبيق — انظر `digits.dart`.
library;

/// `arabicCount(3, one: 'يوم', two: 'يومين', few: 'أيام', many: 'يوماً')` → `'3 أيام'`.
String arabicCount(
  int n, {
  required String one,
  required String two,
  required String few,
  required String many,
}) {
  if (n == 1) return one;
  if (n == 2) return two;

  final tail = n % 100;

  return tail >= 3 && tail <= 10 ? '$n $few' : '$n $many';
}

/// «منذ اليوم» · «منذ يومين» · «منذ 3 أيام» — كم مرّ على شيءٍ صار مستحقّاً.
String sinceDays(int days) => days <= 0
    ? 'منذ اليوم'
    : 'منذ ${arabicCount(days, one: 'يوم', two: 'يومين', few: 'أيام', many: 'يوماً')}';

/// «طلبية واحدة» · «طلبيتين» · «3 طلبيات» · «14 طلبية».
String ordersCount(int n) =>
    arabicCount(n, one: 'طلبية واحدة', two: 'طلبيتين', few: 'طلبيات', many: 'طلبية');
