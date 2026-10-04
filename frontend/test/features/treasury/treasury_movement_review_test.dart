import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «غير مراجَعة / تمت المراجعة» على سطرٍ من سجلّ الحساب حرّكته دفعةُ زبون.
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
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  Map<String, dynamic> line({Map<String, dynamic>? review}) => {
    'id': 1,
    'kind': 'payment',
    'kind_label': 'دفعة زبون',
    'direction': 'in',
    'signed_amount': '100.00',
    'order_id': 7,
    'is_reversal': false,
    'payment_review': ?review,
  };

  testWidgets('a payment nobody has checked says so', (tester) async {
    // Arrange
    final movement = TreasuryMovement.fromJson(line(review: {'is_reviewed': false, 'reviewer': null}));

    // Act
    await tester.pumpWidget(host(TreasuryMovementRow(movement: movement)));

    // Assert
    expect(find.text('غير مراجَعة'), findsOneWidget);
  });

  testWidgets('a checked payment names who checked it', (tester) async {
    // Arrange
    final movement = TreasuryMovement.fromJson(
      line(
        review: {
          'is_reviewed': true,
          'reviewed_at': '2026-10-04T09:30:00Z',
          'reviewer': {'id': 3, 'name': 'سارة'},
        },
      ),
    );

    // Act
    await tester.pumpWidget(host(TreasuryMovementRow(movement: movement)));

    // Assert
    expect(find.textContaining('تمت المراجعة — سارة'), findsOneWidget);
  });

  testWidgets('a line with no customer payment behind it carries no badge', (tester) async {
    // Arrange
    final movement = TreasuryMovement.fromJson(line());

    // Act
    await tester.pumpWidget(host(TreasuryMovementRow(movement: movement)));

    // Assert
    expect(find.byKey(const ValueKey('movement-review')), findsNothing);
  });

  test('a reversed line keeps its badge', () {
    // Arrange
    final movement = TreasuryMovement.fromJson(line(review: {'is_reviewed': true}));

    // Act
    final struck = movement.markedReversed();

    // Assert
    expect(struck.paymentReview?.isReviewed, isTrue);
  });
}
