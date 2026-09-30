import 'package:dayaa_client/app.dart';
import 'package:dayaa_client/core/config/app_config.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/network/safe_request.dart';
import 'package:dayaa_client/core/push/open_notification_route.dart';
import 'package:dayaa_client/core/push/push_service.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/support_badge_feed.dart';
import 'package:dayaa_client/firebase_options.dart';
import 'package:dayaa_client/firebase_options_dev.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Start-up, in order, and nothing else.
///
/// Every step here has to finish before the first frame — anything that does not belongs in a
/// Cubit that loads after the UI is up, because work done here is time the user spends looking
/// at a splash screen.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // خط Cairo محزومٌ في التطبيق، ورخصته (SIL OFL) تُوزَّع معه: تُعرض مع رخص الحزم.
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Cairo'], license);
  });

  // قبل `Injector.init`: خدمةُ الإشعارات حين تُبنى مكانُها الحاوية، و`FirebaseMessaging.instance`
  // يرمي على تطبيقٍ لم يُهيَّأ بدل أن يُرجع null.
  //
  // **وفشلُه لا يوقف التطبيق.** الإشعاراتُ ميزةٌ واحدة؛ الطلبات والسلّة والدعم نقاطٌ عاديّة لا
  // تدين لـFirebase بشيء، فملفُّ إعداداتٍ ناقصٌ على جهازِ أحدٍ يكلّفه الإشعاراتِ لا التطبيق.
  //
  // **والخياراتُ تُنتقى بالحزمة المُنصَّبة**: تمريرُ خيارات الإنتاج من حزمة `ly.dayaa.client.dev`
  // (أو العكس) يطلب تسجيلاً لدى تطبيقٍ لا يملكها فيُرفَض — انظر [DevFirebaseOptions].
  // ولذلك [appFlavor] لا `AppConfig.isDev`: هذا يتبع ملفَّ البيئة، و`--dart-define=FLAVOR=dev`
  // وحده يجعله صادقاً في حزمةٍ اسمُها `ly.dayaa.client`. أمّا `--flavor` فهو ما يسمّي الحزمة.
  final firebase = await safePlatformCall(
    () => Firebase.initializeApp(
      options: appFlavor == Flavor.dev.name
          ? DevFirebaseOptions.currentPlatform
          : DefaultFirebaseOptions.currentPlatform,
    ),
  );
  firebase.fold(
    (_) => debugPrint('Firebase did not start; push is off for this run'),
    (_) {},
  );

  await Injector.init(
    // The interceptor has just cleared a rejected token; all that is left is to get the user
    // somewhere sensible. Passed in as a callback so the network layer never imports the
    // router — that dependency would point the wrong way.
    onUnauthorized: () async {
      AppRouter.instance.go(Routes.home);
    },
  );

  // شارةُ «الدعم» حيّة ما دام العميل داخلاً — تتبع الجلسة بعدها وحدها. انظر SupportBadgeFeed.
  sl<SupportBadgeFeed>().start();

  // بعد الحاوية وقبل أوّل إطار، ليجد إشعارٌ ضُغط والتطبيقُ في الخلفية وجهةً حين يصل.
  //
  // **الإقلاعُ البارد تقرؤه شاشةُ البداية لا هذا**: `getInitialMessage()` لا يُعمل به قبل أن
  // تحسم الجلسة، وإلا دُفع عميلٌ بلا جلسة إلى شاشةٍ تحتاجها.
  final push = sl<PushService>()
    ..onOpenRoute = (route) => openNotificationRoute(route, router: AppRouter.instance);
  await push.start();

  runApp(const DayaaClientApp());
}
