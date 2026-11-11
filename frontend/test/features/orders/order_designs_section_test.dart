import 'package:dayaa/core/print_colors/print_color.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_designs_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// **ما يُطبع الآن فوق، وما استُبدل مطويٌّ تحت «النسخ السابقة».**
///
/// طلبُ المالك ٢٠٢٦-١٠-٢٨، على الطلبية ١٤٧٠: «نسخة ١» و«نسخة ٢» كلتاهما «مقترح» بجانب بعضهما بعد
/// التعديل، «فالمسؤول على الطباعة ما يعرفش أي منهم». والوجهان المُرفقان معاً ليسا مسودّةً وتصحيحها،
/// فيبقيان «الحالية» كلاهما — انظر `OrderDesignVersions.current`.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// ساعةُ إنشاء الطلبية ١٤٧٠، وساعةُ تصحيحها.
  final created = DateTime(2026, 10, 24, 20, 24, 17);
  final corrected = DateTime(2026, 10, 28, 20, 25, 10);

  OrderDesign version(
    int number, {
    String status = 'proposed',
    String statusLabel = 'مقترح',
    DateTime? addedAt,
    String? rejectionReason,
  }) {
    return OrderDesign(
      id: number,
      version: number,
      status: status,
      statusLabel: statusLabel,
      isReviewed: status != 'proposed',
      rejectionReason: rejectionReason,
      createdAt: addedAt ?? created,
    );
  }

  Widget host(List<OrderDesign> designs, {bool colorsRequired = false}) {
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
          body: SingleChildScrollView(
            child: OrderDesignsSection(designs: designs, colorsRequired: colorsRequired),
          ),
        ),
      ),
    );
  }

  group('colours on a print order (PRINT-COLORS.md §9)', () {
    const missing = 'مطلوب: ألوان الطباعة — لا تنتقل الطلبية إلى «قيد الطباعة» دونها';

    testWidgets('a version with no colours says they are required', (tester) async {
      // Arrange / Act
      await tester.pumpWidget(host([version(1)], colorsRequired: true));
      await tester.pump();

      // Assert
      expect(find.text(missing), findsOneWidget);
    });

    testWidgets('a version with its colours says nothing', (tester) async {
      // Arrange / Act
      await tester.pumpWidget(
        host([
          version(1).copyWith(printColors: const [PrintColor(name: 'أسود', hex: '#000000')]),
        ], colorsRequired: true),
      );
      await tester.pump();

      // Assert
      expect(find.text(missing), findsNothing);
    });

    testWidgets('an order nobody prints here is not asked', (tester) async {
      // Arrange / Act
      await tester.pumpWidget(host([version(1)]));
      await tester.pump();

      // Assert
      expect(find.text(missing), findsNothing);
    });
  });

  testWidgets('the correction is current and the draft it replaced is folded away', (tester) async {
    // Arrange — الخادم يرسل الأحدث أولاً.
    await tester.pumpWidget(host([version(2, addedAt: corrected), version(1)]));

    // Act
    await tester.pump();

    // Assert
    expect(find.text('نسخة 2'), findsOneWidget);
    expect(find.text('الحالية'), findsOneWidget);
    expect(find.text('مقترح · 28 أكتوبر 2026'), findsOneWidget);
    expect(find.text('نسخة 1'), findsNothing);
    expect(find.text('النسخ السابقة (1)'), findsOneWidget);
  });

  testWidgets('opening «النسخ السابقة» shows the draft, marked not to be printed', (tester) async {
    // Arrange
    await tester.pumpWidget(host([version(2, addedAt: corrected), version(1)]));
    await tester.pump();

    // Act
    await tester.tap(find.text('النسخ السابقة (1)'));
    await tester.pump();

    // Assert
    expect(find.text('نسخة 1'), findsOneWidget);
    expect(find.text('قديمة · لا تُطبع'), findsOneWidget);
    expect(find.text('استُبدلت بنسخة 2'), findsOneWidget);
    expect(find.text('إخفاء النسخ السابقة'), findsOneWidget);
    expect(find.text('الحالية'), findsOneWidget);
  });

  testWidgets('two faces attached together are both current, and nothing is folded', (tester) async {
    // Arrange — الشعار وظهر الكيس، أُرفقا مع إنشاء الطلبية.
    await tester.pumpWidget(host([version(2), version(1)]));

    // Act
    await tester.pump();

    // Assert
    expect(find.text('نسخة 1'), findsOneWidget);
    expect(find.text('نسخة 2'), findsOneWidget);
    expect(find.text('الحالية'), findsNWidgets(2));
    expect(find.textContaining('النسخ السابقة'), findsNothing);
  });

  testWidgets('a rejected newest version leaves the one before it current', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host([
        version(
          2,
          status: 'rejected',
          statusLabel: 'مرفوض',
          addedAt: corrected,
          rejectionReason: 'الشعار صغير',
        ),
        version(1),
      ]),
    );
    await tester.pump();

    // Act
    await tester.tap(find.text('النسخ السابقة (1)'));
    await tester.pump();

    // Assert — المرفوضةُ سابقةٌ بسببها، لا «قديمة».
    expect(find.text('الحالية'), findsOneWidget);
    expect(find.text('مرفوض'), findsOneWidget);
    expect(find.text('الشعار صغير'), findsOneWidget);
    expect(find.text('قديمة · لا تُطبع'), findsNothing);
  });

  testWidgets('every version rejected: nothing is current and nothing is folded', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host([
        version(2, status: 'rejected', statusLabel: 'مرفوض', addedAt: corrected),
        version(1, status: 'rejected', statusLabel: 'مرفوض'),
      ]),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.text('الحالية'), findsNothing);
    expect(find.text('مرفوض'), findsNWidgets(2));
    expect(find.textContaining('النسخ السابقة'), findsNothing);
  });
}
