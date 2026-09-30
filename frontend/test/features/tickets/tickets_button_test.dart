import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/tickets/presentation/widgets/tickets_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// زرّ «التذاكر» في شريط التطبيق: تذاكر التصميم وتذاكر العملاء خلف أيقونةٍ واحدة.
///
/// كان زرَّ تذاكر التصميم وحدها، وتذاكرُ الدعم صفّاً في الدرج. جُمعتا في خانةٍ واحدة باسمٍ عامّ
/// (طلب المستخدم، 2026-09-25). فما يُختبر هنا: أن أيّاً من الصلاحيتين يُظهر الزرّ، وأن غيابهما
/// معاً يُخفيه — أيقونةٌ بلا حاجزٍ تفتح على صفحةٍ تردّ صاحبها إلى الرئيسية — وأنه يصغي لتبدّل
/// الجلسة، فالصلاحيات تتغيّر والشجرة قائمة.
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
          builder: (context, state) => const Scaffold(body: SafeArea(child: TicketsButton())),
        ),
        GoRoute(
          path: Routes.tickets,
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

  for (final grant in [AppPermission.viewDesignTickets, AppPermission.viewSupportTickets]) {
    testWidgets('«${grant.wire}» alone is enough to get «التذاكر»', (tester) async {
      // Arrange
      await arrange([grant]);

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byTooltip('التذاكر'), findsOneWidget);
      expect(find.byIcon(AppIcons.comments), findsOneWidget);
    });
  }

  testWidgets('it pushes the tickets screen', (tester) async {
    // Arrange
    await arrange([AppPermission.viewDesignTickets, AppPermission.viewSupportTickets]);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byType(TicketsButton));
    await tester.pumpAndSettle();

    // Assert
    expect(pushed, Routes.tickets);
  });

  testWidgets('without either grant there is no button at all', (tester) async {
    // Arrange — every other ticket grant, but neither of the two that open a list.
    await arrange([AppPermission.manageDesignTickets, AppPermission.manageSupportTickets]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — hidden, not greyed: the route would send them back to الرئيسية.
    expect(find.byTooltip('التذاكر'), findsNothing);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('a grant arriving with the tree mounted brings it', (tester) async {
    // Arrange — signed in with nothing, as before a pull-to-refresh re-reads `/auth/me`.
    await arrange([]);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(find.byTooltip('التذاكر'), findsNothing);

    // Act
    session.adopt(
      AuthUser(
        id: 1,
        name: 'عبدالوهاب',
        phone: '0911234567',
        permissions: [AppPermission.viewSupportTickets.wire],
      ),
    );
    await tester.pumpAndSettle();

    // Assert
    expect(find.byTooltip('التذاكر'), findsOneWidget);
  });
}
