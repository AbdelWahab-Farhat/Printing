import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/theme/text_theme.dart';
import 'package:dayaa/core/theme/theme.dart';
import 'package:dayaa/core/widgets/dismiss_keyboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The root widget: theme, locale, direction, router.
///
/// Kept out of `main.dart` so `main` stays a list of start-up steps and this stays a widget —
/// the two change for entirely different reasons.
class DayaaApp extends StatelessWidget {
  const DayaaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // The reference device the designs were drawn on. Every `.w`/`.h`/`.sp` is relative to
      // this, so changing it silently rescales the entire app.
      designSize: const Size(430, 932),
      minTextAdapt: true,
      builder: (context, _) {
        final theme = MaterialTheme(createTextTheme(context, 'Cairo', 'Cairo'));

        return MaterialApp.router(
          title: 'دعاية',
          debugShowCheckedModeBanner: false,
          theme: theme.light(),
          darkTheme: theme.dark(),

          // Arabic, right-to-left, and not negotiable at runtime: the app is built for one
          // locale, and leaving the system to choose gives an English layout to anyone whose
          // phone is set to English.
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          routerConfig: AppRouter.instance,

          // Wrapped around every route rather than around each screen: a keyboard that only
          // closes on some forms is worse than one that never does, because the user stops
          // trusting the gesture. `builder` is the one place that sits above the router and
          // below the theme, so it covers dialogs and sheets too.
          builder: (context, child) => DismissKeyboard(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
