import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/auth/models/auth_user.dart';
import 'package:printing/features/home/models/home_summary.dart';
import 'package:printing/features/home/presentation/widgets/employee_card.dart';
import 'package:printing/features/home/presentation/widgets/status_board.dart';
import 'package:printing/features/home/presentation/widgets/summary_tiles.dart';

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
        OrderStatusCount(status: 'new', label: 'الجديدة', count: 72, needsAttention: true),
        OrderStatusCount(status: 'rejected', label: 'مرفوض', count: 76),
      ];

      // Act
      await tester.pumpWidget(host(const StatusBoard(statuses: statuses)));

      // Assert
      expect(find.text('حالات الطلبات'), findsOneWidget);
      expect(find.text('الجديدة'), findsOneWidget);
      expect(find.text('72'), findsOneWidget);
      expect(find.text('مرفوض'), findsOneWidget);
      expect(find.text('76'), findsOneWidget);
    });

    testWidgets('every card is the same colour, urgent or not', (tester) async {
      // Arrange
      const statuses = [
        OrderStatusCount(status: 'new', label: 'الجديدة', count: 72, needsAttention: true),
        OrderStatusCount(status: 'rejected', label: 'مرفوض', count: 76),
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

      // Assert — one fill across the board. Urgency is carried by the dot, not by a tint.
      expect(backgrounds, hasLength(1));
      expect(find.text('1 تحتاج متابعة'), findsOneWidget);
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
}
