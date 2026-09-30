import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cairo كما يحزمه التطبيق (`pubspec.yaml`)، لاختبارٍ يقيس نصّاً. والمضيف يسمّيه في ثيمه:
/// `ThemeData(fontFamily: 'Cairo')`.
///
/// **خطّ الاختبار يرسم كل حرفٍ مربّعاً بعرض الـ em**، فـ«FlyerX» و«معاينة على الكيس» فيه أعرض
/// بمرّتين منهما على الهاتف. الاختبار الذي يسأل «هل يتّسع الاسم؟» بخطّ الاختبار يفشل على ما لا
/// يحدث أبداً، أو ينجح على ما لا يعني شيئاً.
///
/// **يُستدعى في `setUpAll` لا داخل `testWidgets`**: تحميل الخطّ قراءةٌ حقيقية خارج الساعة المزيّفة،
/// ومستقبلٌ يبدأ داخلها لا يكتمل.
Future<void> loadCairo() async {
  // `rootBundle` يحتاج الربط، وملفٌّ لا `testWidgets` فيه لم يُنشئه بعد.
  TestWidgetsFlutterBinding.ensureInitialized();

  final loader = FontLoader('Cairo');
  for (final face in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold', 'Black']) {
    loader.addFont(rootBundle.load('assets/fonts/Cairo-$face.ttf'));
  }
  await loader.load();
}
