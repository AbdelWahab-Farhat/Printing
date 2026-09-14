import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:dayaa/features/shortages/models/shortage_counts.dart';
import 'package:dayaa/features/shortages/presentation/widgets/shortage_filter_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every way of narrowing the نواقص list, behind one button.
///
/// **This replaced two rows of chips.** The list opened with a scrolling status row *and* a
/// second row for the two queues — a hundred points of every screen spent saying «الكل», with
/// «مكتمل» off the edge of a row nothing suggested continued. The counts came with them, because
/// they are the one thing the row was good for.
///
/// Arrange - Act - Assert throughout.
void main() {
  const counts = ShortageCounts(
    byStatus: {'new': 12, 'searching': 7, 'unavailable': 3, 'completed': 25},
    total: 50,
  );

  Widget host({
    ShortageFilterSelection selection = const ShortageFilterSelection(),
    ValueChanged<ShortageFilterSelection>? onApplied,
  }) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: ShortageFilterButton(
              selection: selection,
              counts: counts,
              onApplied: onApplied ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> openTheSheet(WidgetTester tester) async {
    await tester.tap(find.byType(ShortageFilterButton));
    await tester.pumpAndSettle();
  }

  testWidgets('the list carries no chip rows — every question is behind the button', (
    tester,
  ) async {
    // Arrange - Act
    await tester.pumpWidget(host());

    // Assert — nothing is offered until it is asked for.
    expect(find.byType(FilterOptionChip), findsNothing);
  });

  testWidgets('the sheet asks the two questions that belong in it', (tester) async {
    // Arrange
    await tester.pumpWidget(host());

    // Act
    await openTheSheet(tester);

    // Assert — «المصدر» is deliberately **not** here: it lives on the page, because it is the
    // split somebody flips between while reading rather than a question they set once.
    expect(find.text('حالة النقص'), findsOneWidget);
    expect(find.text('الإسناد'), findsOneWidget);
    expect(find.text('المصدر'), findsNothing);
  });

  testWidgets('the counts the chip row used to carry are on the statuses', (tester) async {
    // Arrange
    await tester.pumpWidget(host());

    // Act
    await openTheSheet(tester);

    // Assert — «الكل» reads the server's own total, never the four added up: a status this build
    // has never heard of is still inside that number.
    expect(find.text('جاري البحث'), findsOneWidget);
    expect(find.textContaining('50'), findsWidgets);
  });

  testWidgets('the two queues are options here rather than a row of their own', (tester) async {
    // Arrange
    await tester.pumpWidget(host());

    // Act
    await openTheSheet(tester);

    // Assert — «غير مُسنَدة» is a queue a supervisor works from, not an absence.
    expect(find.text('المسندة إليّ'), findsOneWidget);
    expect(find.text('غير مُسنَدة'), findsOneWidget);
  });

  testWidgets('nothing is applied until «تطبيق» is pressed', (tester) async {
    // Arrange — the choice is applied on the button rather than on the tap, so a mis-tap can be
    // corrected without reopening the sheet.
    ShortageFilterSelection? applied;
    await tester.pumpWidget(host(onApplied: (picked) => applied = picked));
    await openTheSheet(tester);

    // Act
    await tester.tap(find.text('جاري البحث'));
    await tester.pumpAndSettle();

    // Assert
    expect(applied, isNull);
  });

  testWidgets('«تطبيق» answers with all three at once', (tester) async {
    // Arrange
    ShortageFilterSelection? applied;
    await tester.pumpWidget(host(onApplied: (picked) => applied = picked));
    await openTheSheet(tester);

    // Act
    await tester.tap(find.text('جاري البحث'));
    await tester.pump();
    await tester.tap(find.text('غير مُسنَدة'));
    await tester.pump();
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    // Assert — one answer, so the list is narrowed in one request rather than two.
    expect(applied?.status, ShortageStatus.searching);
    expect(applied?.assignedTo, 'none');
  });

  testWidgets('«مسح الفلاتر» appears only once there is something to clear', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await openTheSheet(tester);
    expect(find.text('مسح الفلاتر'), findsNothing);

    // Act
    await tester.tap(find.text('جديد'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('مسح الفلاتر'), findsOneWidget);
  });

  testWidgets('a narrowed list says so before the sheet is opened', (tester) async {
    // Arrange - Act
    await tester.pumpWidget(
      host(selection: const ShortageFilterSelection(assignedTo: 'me')),
    );

    // Assert — the button is filled, which is what answers «is this list narrowed?» at a glance.
    expect(const ShortageFilterSelection(assignedTo: 'me').isNarrowed, isTrue);
    expect(const ShortageFilterSelection().isNarrowed, isFalse);
  });
}
