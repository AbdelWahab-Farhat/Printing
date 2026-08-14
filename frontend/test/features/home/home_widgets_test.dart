import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/home/models/home_summary.dart';
import 'package:dayaa/features/home/presentation/widgets/employee_card.dart';
import 'package:dayaa/features/home/presentation/widgets/status_board.dart';
import 'package:dayaa/features/home/presentation/widgets/summary_tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The pieces of the home screen that decide something — an initial, a missing code, which
/// status is highlighted, how a number is punctuated.
///
/// Arrange - Act - Assert throughout.
void main() {
  Widget host(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Directionality(textDirection: TextDirection.rtl, child: child),
        ),
      ),
    );
  }

  group('employee card', () {
    const user = AuthUser(
      id: 2,
      name: 'عبدالوهاب فرحات',
      phone: '0911000001',
      employeeCode: '1002',
      roles: [UserRole(name: 'staff', label: 'موظف')],
    );

    testWidgets('names the employee, their code and their role', (tester) async {
      // Arrange
      await tester.pumpWidget(host(const EmployeeCard(user: user)));

      // Act
      await tester.pump();

      // Assert
      expect(find.text('عبدالوهاب فرحات'), findsOneWidget);
      expect(find.text('#1002'), findsOneWidget);
      expect(find.text('موظف'), findsOneWidget);
      // The avatar carries the first letter, not a slice of the code units behind it.
      expect(find.text('ع'), findsOneWidget);
    });

    testWidgets('copies the code to the clipboard when it is tapped', (tester) async {
      // Arrange
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }

          return null;
        },
      );
      await tester.pumpWidget(host(const EmployeeCard(user: user)));

      // Act
      await tester.tap(find.text('#1002'));
      await tester.pump();

      // Assert
      expect(copied, '1002');
      expect(find.text('تم نسخ كود الموظف'), findsOneWidget);

      // The confirmation toast owns an animation and a dismissal timer. Left running, they
      // outlive this test and fail the *next* one — so it is played out here.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('says so plainly when the account predates employee codes', (tester) async {
      // Arrange
      const codeless = AuthUser(id: 3, name: 'موظف', phone: '0911000002');

      // Act
      await tester.pumpWidget(host(const EmployeeCard(user: codeless)));

      // Assert — never "#null", and never an empty chip nobody can explain.
      expect(find.text('لا يوجد كود موظف'), findsOneWidget);
      expect(find.textContaining('null'), findsNothing);
    });

    testWidgets('carries the brand mark', (tester) async {
      // Arrange
      await tester.pumpWidget(host(const EmployeeCard(user: user)));

      // Act
      final mark = tester.widget<Image>(find.byType(Image));

      // Assert — the app's one logo file, the same one the splash and the login screen draw.
      expect((mark.image as AssetImage).assetName, 'assets/images/logo.png');
    });

    testWidgets('the mark is decoration — it neither speaks nor takes a tap', (tester) async {
      // Arrange — a watermark announced to a screen reader is a word read out on every visit to
      // the home screen that tells nobody anything.
      await tester.pumpWidget(host(const EmployeeCard(user: user)));

      // Act
      final semantics = tester.getSemantics(find.byType(EmployeeCard));

      // Assert — the card still says who is signed in, and says nothing about a logo.
      expect(semantics, isNot(matchesSemantics(label: 'logo')));
      expect(find.descendant(of: find.byType(Image), matching: find.byType(InkWell)), findsNothing);
      expect(find.text('عبدالوهاب فرحات'), findsOneWidget);
    });

    testWidgets('the mark never pushes the card out of shape', (tester) async {
      // Arrange — the watermark bleeds off the corner, so it is laid out *behind* the row
      // rather than beside it. A card that grew to fit it would be a different card.
      await tester.pumpWidget(host(const EmployeeCard(user: user)));
      final withMark = tester.getSize(find.byType(EmployeeCard));

      // Act — the longest name and role the card is likely to meet.
      await tester.pumpWidget(
        host(
          const EmployeeCard(
            user: AuthUser(
              id: 4,
              name: 'عبدالوهاب فرحات',
              phone: '0911000003',
              employeeCode: '1002',
              roles: [UserRole(name: 'staff', label: 'موظف')],
            ),
          ),
        ),
      );

      // Assert
      expect(tester.getSize(find.byType(EmployeeCard)), withMark);
    });
  });

  group('summary tiles', () {
    testWidgets('shows all four counts, punctuated', (tester) async {
      // Arrange
      const summary = HomeSummary(
        totalOrders: 9651,
        customersCount: 8041,
        dailyOrders: 5,
        monthlyOrders: 34,
      );

      // Act
      await tester.pumpWidget(host(const SummaryTiles(summary: summary)));

      // Assert
      expect(find.text('9,651'), findsOneWidget);
      expect(find.text('8,041'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('34'), findsOneWidget);
      expect(find.text('الطلبات الكلية'), findsOneWidget);
      expect(find.text('عدد العملاء'), findsOneWidget);
      expect(find.text('الطلبات اليومية'), findsOneWidget);
      expect(find.text('الطلبات الشهرية'), findsOneWidget);
    });

    test('grouping puts a separator every three digits and nowhere else', () {
      // Arrange - Act - Assert
      expect(0.grouped, '0');
      expect(9.grouped, '9');
      expect(999.grouped, '999');
      expect(1000.grouped, '1,000');
      expect(9651.grouped, '9,651');
      expect(1234567.grouped, '1,234,567');
      expect((-4500).grouped, '-4,500');
    });
  });

  group('status board', () {
    testWidgets('renders whatever statuses it is handed', (tester) async {
      // Arrange
      const statuses = [
        OrderStatusCount(status: 'new', label: 'جديدة', count: 72),
        OrderStatusCount(status: 'cancelled', label: 'ملغاة', count: 76),
      ];

      // Act
      await tester.pumpWidget(host(const StatusBoard(statuses: statuses)));

      // Assert
      expect(find.text('حالات الطلبات'), findsOneWidget);
      expect(find.text('جديدة'), findsOneWidget);
      expect(find.text('72'), findsOneWidget);
      expect(find.text('ملغاة'), findsOneWidget);
      expect(find.text('76'), findsOneWidget);
    });

    testWidgets('every card is the same colour, and none is marked', (tester) async {
      // Arrange
      const statuses = [
        OrderStatusCount(status: 'new', label: 'جديدة', count: 72),
        OrderStatusCount(status: 'cancelled', label: 'ملغاة', count: 76),
      ];
      await tester.pumpWidget(host(const StatusBoard(statuses: statuses)));
      await tester.pumpAndSettle();

      // Act
      final backgrounds = tester
          .widgetList<Container>(find.byType(Container))
          .map((container) => container.decoration)
          .whereType<BoxDecoration>()
          .where((decoration) => decoration.borderRadius != null)
          .map((decoration) => decoration.color)
          .toSet();

      // Assert — one fill across the board, and nothing else claiming attention. The dot that
      // used to sit here marked a *status*, so «جديدة» wore it while counting zero — a warning
      // about nothing, which teaches the reader to stop believing the mark.
      expect(backgrounds, hasLength(1));
      expect(find.textContaining('تحتاج متابعة'), findsNothing);
    });

    testWidgets('takes up no room at all when there is nothing to show', (tester) async {
      // Arrange
      await tester.pumpWidget(host(const StatusBoard(statuses: [])));

      // Act
      final size = tester.getSize(find.byType(StatusBoard));

      // Assert — no orphan heading over an empty grid.
      expect(find.text('حالات الطلبات'), findsNothing);
      expect(size.height, 0);
    });
  });

  group('cards that open something', () {
    const shortage = OrderStatusCount(status: 'shortage', label: 'نواقص', count: 14);
    const empty = OrderStatusCount(status: 'resend', label: 'إعادة إرسال', count: 0);

    testWidgets('tapping a status card asks for that status by its wire name', (tester) async {
      // Arrange
      OrderStatusCount? opened;

      await tester.pumpWidget(
        host(
          StatusBoard(
            statuses: const [shortage],
            onOpen: (status) => opened = status,
          ),
        ),
      );

      // Act — the ink sits over the card, so the tap goes to it rather than to the label
      // painted underneath.
      await tester.tap(find.byType(InkWell));
      await tester.pump();

      // Assert — the card hands over its own row, so the screen it opens gets both the filter
      // and the Arabic to put at the top of it.
      expect(opened?.status, 'shortage');
      expect(opened?.label, 'نواقص');
    });

    testWidgets('a status with nothing in it does not respond', (tester) async {
      // Arrange
      var taps = 0;

      await tester.pumpWidget(
        host(StatusBoard(statuses: const [empty], onOpen: (_) => taps++)),
      );

      // Act
      // The miss is the assertion: there is no ink to hit on a card with nothing to open.
      await tester.tap(find.text('إعادة إرسال'), warnIfMissed: false);
      await tester.pump();

      // Assert — a tap that opens «لا توجد طلبيات» teaches the reader nothing the card did not
      // already say.
      expect(taps, isZero);
    });

    testWidgets('a board with nowhere to go is still readable', (tester) async {
      // Arrange & Act — no `onOpen`, which is what it was before any of this.
      await tester.pumpWidget(host(const StatusBoard(statuses: [shortage])));

      // Assert
      expect(find.text('نواقص'), findsOneWidget);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('the day tile is inert when the day was quiet', (tester) async {
      // Arrange
      var days = 0;
      var alls = 0;

      const summary = HomeSummary(
        totalOrders: 26,
        customersCount: 9,
        dailyOrders: 0,
        monthlyOrders: 11,
      );

      // Act
      await tester.pumpWidget(
        host(
          SummaryTiles(
            summary: summary,
            onAllOrders: () => alls++,
            onDay: () => days++,
          ),
        ),
      );

      await tester.tap(find.text('الطلبات اليومية'), warnIfMissed: false);
      // The only ink on screen: the quiet day has none.
      await tester.tap(find.byType(InkWell));
      await tester.pump();

      // Assert
      expect(days, isZero);
      expect(alls, 1);
    });
  });
}
