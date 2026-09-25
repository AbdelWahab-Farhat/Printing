import 'package:dayaa_client/app.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/support_badge_feed.dart';
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

  runApp(const DayaaClientApp());
}
