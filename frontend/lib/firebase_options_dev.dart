import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// خياراتُ Firebase لنكهة الاختبار — تطبيقا `ly.dayaa.app.dev` في مشروع `daya-bdf70`.
///
/// **وملفٌّ ثانٍ لا فرعٌ داخل `firebase_options.dart`**: ذاك يولّده FlutterFire CLI ويكتب فوقه
/// كاملاً عند كلّ `flutterfire configure`، فأيُّ تمييزٍ للنكهة يُوضع فيه يضيع صامتاً في أوّل
/// إعادةِ توليد. وهذا الملفُّ يُحرَّر بيدٍ، وقيمُه من
/// `firebase apps:sdkconfig ANDROID|IOS <app-id>` (٢٠٢٦-٠٩-٢١).
///
/// **و`google-services.json` وحده لا يكفي**، وهذا هو الفخّ: `main.dart` يُهيّئ Firebase بخيارات
/// Dart صريحة، وهي تَجُبّ ما في الملفّ الأصليّ. فحزمةُ `.dev` مع مُعرّف الإنتاج تطلب تسجيلاً
/// لدى تطبيقٍ لا يملك حزمتَها، فيُرفَض التسجيل: الإشعاراتُ وحدَها تموت، وكلُّ شيءٍ آخر يعمل —
/// عطلٌ يُبلَّغ عنه من المُختبِر على أنه «الإشعارات لا تصل».
///
/// مفتاحُ الـAPI مشتركٌ مع الإنتاج على كلّ منصّة (مفتاحُ المشروع، لا مفتاحُ التطبيق)؛
/// المُختلفُ هو `appId` وحده. هذا ما تُخرجه الأداة، وليس خطأَ نسخ.
class DevFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('نكهةُ الاختبار غيرُ مُهيّأةٍ للويب.');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'نكهةُ الاختبار مُهيّأةٌ لأندرويد وiOS فقط؛ المنصّةُ الحاليّة $defaultTargetPlatform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB-IaE6avnlOIsZpGLiJHL8OcKsg7Bg4c0',
    appId: '1:627605931055:android:9999e318c5e7d520edf2da',
    messagingSenderId: '627605931055',
    projectId: 'daya-bdf70',
    storageBucket: 'daya-bdf70.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBBdNMXNl0PxY-CLiARmrPmN5KcMNA3bM4',
    appId: '1:627605931055:ios:4afaca8c6bbf4846edf2da',
    messagingSenderId: '627605931055',
    projectId: 'daya-bdf70',
    storageBucket: 'daya-bdf70.firebasestorage.app',
    iosBundleId: 'ly.dayaa.app.dev',
  );
}
