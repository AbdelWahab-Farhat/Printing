import 'package:dayaa/features/orders/presentation/widgets/pickup_to_delivery_confirmation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The question the edit form asks before an office pickup becomes a delivery.
///
/// Arrange - Act - Assert throughout.
void main() {
  Future<Future<bool>> open(WidgetTester tester) async {
    late Future<bool> answer;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => answer = confirmPickupBecomesDelivery(context, cityName: 'جنزور'),
            child: const Text('حفظ'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    return answer;
  }

  testWidgets('names «إعادة إرسال» and the city', (tester) async {
    // Arrange - Act
    await open(tester);

    // Assert
    expect(find.textContaining('إعادة إرسال'), findsOneWidget);
    expect(find.textContaining('جنزور'), findsOneWidget);
  });

  testWidgets('a yes lets the save go on', (tester) async {
    // Arrange
    final answer = await open(tester);

    // Act
    await tester.tap(find.byKey(const ValueKey('accept-pickup-to-delivery')));
    await tester.pumpAndSettle();

    // Assert
    expect(await answer, isTrue);
  });

  testWidgets('«تراجع» stops it', (tester) async {
    // Arrange
    final answer = await open(tester);

    // Act
    await tester.tap(find.text('تراجع'));
    await tester.pumpAndSettle();

    // Assert
    expect(await answer, isFalse);
  });
}
