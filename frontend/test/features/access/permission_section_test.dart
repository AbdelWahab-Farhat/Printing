import 'package:dayaa/features/access/models/role.dart';
import 'package:dayaa/features/access/presentation/widgets/permission_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// One section of permissions, in both the shapes it has to be: chosen, and read.
///
/// The pair of tests that matters is the last one — a permission granted under «الطلبيات» in
/// the editor must be found under «الطلبيات» on the screen that reports. A read-only view laid
/// out differently from the editor makes the reader do the matching by hand.
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
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }

  const orders = PermissionGroup(
    title: 'الطلبيات',
    permissions: [
      PermissionOption(name: 'orders.view', label: 'عرض الطلبيات'),
      PermissionOption(name: 'orders.manage', label: 'إضافة وتعديل الطلبيات'),
      PermissionOption(name: 'orders.discount', label: 'منح خصم على الطلبية'),
    ],
  );

  group('editable', () {
    testWidgets('counts how much of the section is granted, not just how many exist', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        host(
          PermissionSection.editable(
            group: orders,
            isSelected: (name) => name == 'orders.view',
            selectedCount: 1,
            onToggle: (_) {},
            onToggleGroup: () {},
          ),
        ),
      );

      // Act

      // Assert — «١ من ٣» is a sentence somebody can act on; «٣» alone is not.
      expect(find.text('1 من 3'), findsOneWidget);
      expect(find.text('الطلبيات'), findsOneWidget);
    });

    testWidgets('shows the machine name under the Arabic, for when a grant misbehaves', (
      tester,
    ) async {
      // Arrange — `orders.discount` is what a route's `can:` names, so it is what somebody
      // reads out when a permission is not doing what they expect.
      await tester.pumpWidget(
        host(
          PermissionSection.editable(
            group: orders,
            isSelected: (_) => false,
            selectedCount: 0,
            onToggle: (_) {},
            onToggleGroup: () {},
          ),
        ),
      );

      // Act

      // Assert
      expect(find.text('منح خصم على الطلبية'), findsOneWidget);
      expect(find.text('orders.discount'), findsOneWidget);
    });

    testWidgets('a partly ticked section offers to fill it, a full one to empty it', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        host(
          PermissionSection.editable(
            group: orders,
            isSelected: (name) => name == 'orders.view',
            selectedCount: 1,
            onToggle: (_) {},
            onToggleGroup: () {},
          ),
        ),
      );

      // Act & Assert — half-filled reads "select all", which is the direction people mean.
      expect(find.text('تحديد الكل'), findsOneWidget);

      // Arrange — the same section, fully ticked.
      await tester.pumpWidget(
        host(
          PermissionSection.editable(
            group: orders,
            isSelected: (_) => true,
            selectedCount: 3,
            onToggle: (_) {},
            onToggleGroup: () {},
          ),
        ),
      );

      // Assert
      expect(find.text('إلغاء الكل'), findsOneWidget);
    });

    testWidgets('tapping a row reports which permission it was', (tester) async {
      // Arrange
      final toggled = <String>[];
      await tester.pumpWidget(
        host(
          PermissionSection.editable(
            group: orders,
            isSelected: (_) => false,
            selectedCount: 0,
            onToggle: toggled.add,
            onToggleGroup: () {},
          ),
        ),
      );

      // Act
      await tester.tap(find.text('إضافة وتعديل الطلبيات'));
      await tester.pump();

      // Assert
      expect(toggled, ['orders.manage']);
    });
  });

  group('readOnly', () {
    testWidgets('lists what is granted, with no way to change it', (tester) async {
      // Arrange — only the granted subset reaches this widget, so every row shown is granted.
      const granted = PermissionGroup(
        title: 'الطلبيات',
        permissions: [PermissionOption(name: 'orders.view', label: 'عرض الطلبيات')],
      );

      // Act
      await tester.pumpWidget(host(const PermissionSection.readOnly(group: granted)));

      // Assert
      expect(find.text('عرض الطلبيات'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.text('تحديد الكل'), findsNothing);
      // Every row shown is granted, so the header counts rather than reporting a fraction.
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('keeps the section heading the editor granted it under', (tester) async {
      // Arrange — the whole reason the two share a widget: somebody who ticked a box under
      // «حالات الطلبيات» must find it under a heading of that name here.
      const granted = PermissionGroup(
        title: 'حالات الطلبيات',
        permissions: [
          PermissionOption(name: 'orders.status.ready', label: 'تحويل الطلبية إلى جاهزة'),
        ],
      );

      // Act
      await tester.pumpWidget(host(const PermissionSection.readOnly(group: granted)));

      // Assert
      expect(find.text('حالات الطلبيات'), findsOneWidget);
      expect(find.text('تحويل الطلبية إلى جاهزة'), findsOneWidget);
    });
  });
}
