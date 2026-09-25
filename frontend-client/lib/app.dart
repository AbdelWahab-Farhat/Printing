import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/theme/text_theme.dart';
import 'package:dayaa_client/core/theme/theme.dart';
import 'package:dayaa_client/core/theme/theme_mode_cubit.dart';
import 'package:dayaa_client/core/widgets/dismiss_keyboard.dart';
import 'package:dayaa_client/features/badges/presentation/viewmodel/badges_cubit.dart';
import 'package:dayaa_client/features/badges/presentation/views/badge_refresher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The root widget: theme, locale, direction, router.
///
/// Kept out of `main.dart` so `main` stays a list of start-up steps and this stays a widget —
/// the two change for entirely different reasons.
class DayaaClientApp extends StatelessWidget {
  const DayaaClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // The reference device the designs were drawn on. Every `.w`/`.h`/`.sp` is relative to
      // this, so changing it silently rescales the entire app.
      designSize: const Size(430, 932),
      minTextAdapt: true,
      builder: (context, _) {
        final theme = MaterialTheme(createTextTheme(context, 'Cairo', 'Cairo'));

        // **The whole app is under this builder, and that is the point.** A palette is not a
        // screen's property: rebuilding one page would leave every other page — and every route
        // already on the stack — wearing the old one until something else happened to rebuild
        // it. `MaterialApp` is the highest place the choice can be read, so it is read here.
        return BlocBuilder<ThemeModeCubit, ThemeMode>(
          bloc: sl<ThemeModeCubit>(),
          builder: (context, themeMode) => MaterialApp.router(
            title: 'دعاية',
            debugShowCheckedModeBanner: false,
            // **Both palettes ship, and the phone chooses by default.** The mockup was drawn in
            // the dark one and that is still the app's own appearance — see `MaterialTheme.light`
            // for how the daylight scheme is reasoned out of it rather than drawn. Somebody who
            // wants one or the other regardless says so on «حسابي»; see [ThemeModeCubit].
            theme: theme.light(),
            darkTheme: theme.dark(),
            themeMode: themeMode,

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
            // **Two wrappers, and the order matters only in that neither cares.**
            // `DismissKeyboard` watches pointers; `BadgeRefresher` watches the app's lifecycle.
            // Both are properties of the app rather than of a screen, and `builder` is the one
            // place above the router and below the theme — so they cover dialogs and sheets too.
            //
            // The cubit is provided here rather than per screen because the counts belong to the
            // session: see [BadgesCubit].
            builder: (context, child) => BlocProvider<BadgesCubit>.value(
              value: sl<BadgesCubit>(),
              child: BadgeRefresher(
                child: DismissKeyboard(child: child ?? const SizedBox.shrink()),
              ),
            ),
          ),
        );
      },
    );
  }
}
