import 'dart:async';

import 'package:go_router/go_router.dart';

/// يفتح الوجهةَ التي يحملها إشعارٌ ضُغط، فوق الشاشة الحاليّة.
///
/// **`push` لا `go`**: زرُّ الرجوع يعيد العميل حيث كان، أو إلى الرئيسية في الإقلاع البارد.
///
/// **ووجهةٌ لا يعرفها هذا البناء لا تُفتح.** تطبيقٌ قديم أمام خادمٍ أحدث هو الحالة العاديّة لا
/// العطل: قد يسمّي الإشعار شاشةً أُضيفت بعد هذا الإصدار، وصفحةُ خطأ الموجِّه أسوأ جوابٍ عليها —
/// فتحُ التطبيق وحده هو الجواب الصادق. ويُسأل الموجِّه قبل الدفع بدل التقاط استثناء (RULES §5).
///
/// الموجِّه يُمرَّر ولا يُستورد `AppRouter` هنا: هذا الملفّ لا يحتاج شاشات التطبيق كلّها ليُختبر.
void openNotificationRoute(String route, {required GoRouter router}) {
  final uri = Uri.tryParse(route);
  if (uri == null) return;

  final match = router.configuration.findMatch(uri);
  if (match.isError || match.isEmpty) return;

  unawaited(router.push(route));
}
