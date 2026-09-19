import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/design_tickets_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// زرّ تذاكر التصميم في شريط التطبيق، بعد أن خرج الصفّ من الدرج إلى جانب الأدوات.
///
/// ما ضاع بخروجه من الدرج شيئان، وهما ما يُختبر هنا: الصلاحية التي كانت تحجب الصفّ عمّن لا
/// يقرأ التذاكر — وأيقونةٌ في الشريط بلا حاجزٍ تفتح على صفحةٍ تردّ صاحبها إلى الرئيسية —
/// وإصغاؤه لتبدّل الجلسة، فالصلاحيات تتغيّر والشجرة قائمة.
///
/// Arrange - Act - Assert throughout.
void main() {
  late Session session;

  /// آخر مسارٍ دُفع، لأن ما يفعله الزرّ هو الذهاب إلى مكان.
  String? pushed;

  Future<void> arrange(List<AppPermission> grants) async {
    await Injector.reset();
    pushed = null;
    session = Session()
      ..adopt(
        AuthUser(
          id: 1,
          name: 'عبدالوهاب',
          phone: '0911234567',
          permissions: [for (final grant in grants) grant.wire],
        ),
      );
    sl.registerSingleton<Session>(session);
  }

  tearDown(Injector.reset);

  Widget host() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: SafeArea(child: DesignTicketsButton())),
        ),
        GoRoute(
          path: Routes.designTickets,
          builder: (context, state) {
            pushed = state.uri.path;

            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp.router(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
  }

  testWidgets('a reader of tickets gets the glyph', (tester) async {
    // Arrange
    await arrange([AppPermission.viewDesignTickets]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byIcon(AppIcons.designs), findsOneWidget);
  });

  testWidgets('it pushes the queue itself', (tester) async {
    // Arrange
    await arrange([AppPermission.viewDesignTickets]);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byType(DesignTicketsButton));
    await tester.pumpAndSettle();

    // Assert
    expect(pushed, Routes.designTickets);
  });

  testWidgets('without the grant there is no button at all', (tester) async {
    // Arrange — every ticket grant but the one that opens the list.
    await arrange([AppPermission.manageDesignTickets]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — hidden, not greyed: the route would send them back to الرئيسية.
    expect(find.byIcon(AppIcons.designs), findsNothing);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('a grant arriving with the tree mounted brings it', (tester) async {
    // Arrange — signed in with nothing, as before a pull-to-refresh re-reads `/auth/me`.
    await arrange([]);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(find.byIcon(AppIcons.designs), findsNothing);

    // Act
    session.adopt(
      AuthUser(
        id: 1,
        name: 'عبدالوهاب',
        phone: '0911234567',
        permissions: [AppPermission.viewDesignTickets.wire],
      ),
    );
    await tester.pumpAndSettle();

    // Assert
    expect(find.byIcon(AppIcons.designs), findsOneWidget);
  });
}
