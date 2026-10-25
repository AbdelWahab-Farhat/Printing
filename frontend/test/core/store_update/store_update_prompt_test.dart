import 'package:dayaa/core/store_update/store_update.dart';
import 'package:dayaa/core/store_update/store_update_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStoreUpdate extends Mock implements StoreUpdate {}

final _release = StoreRelease(
  version: '1.13.0',
  url: Uri.parse('https://apps.apple.com/ly/app/daya-staff/id6808283408'),
);

void main() {
  late _MockStoreUpdate update;

  setUpAll(() => registerFallbackValue(_release));

  setUp(() {
    update = _MockStoreUpdate();
    when(() => update.snooze(any())).thenAnswer((_) async {});
    when(() => update.open(any())).thenAnswer((_) async => true);
  });

  Future<void> pumpPrompt(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StoreUpdatePrompt(update: update, child: const Scaffold()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a pending update is announced with its version', (tester) async {
    // Arrange
    when(() => update.pending()).thenAnswer((_) async => _release);

    // Act
    await pumpPrompt(tester);

    // Assert
    expect(find.text('تحديث جديد'), findsOneWidget);
    expect(find.textContaining('1.13.0'), findsOneWidget);
  });

  testWidgets('«تحديث» opens the App Store page', (tester) async {
    // Arrange
    when(() => update.pending()).thenAnswer((_) async => _release);
    await pumpPrompt(tester);

    // Act
    await tester.tap(find.text('تحديث'));
    await tester.pumpAndSettle();

    // Assert
    verify(() => update.open(_release)).called(1);
    verifyNever(() => update.snooze(any()));
  });

  testWidgets('«لاحقاً» snoozes the version', (tester) async {
    // Arrange
    when(() => update.pending()).thenAnswer((_) async => _release);
    await pumpPrompt(tester);

    // Act
    await tester.tap(find.text('لاحقاً'));
    await tester.pumpAndSettle();

    // Assert
    verify(() => update.snooze(_release)).called(1);
    verifyNever(() => update.open(any()));
  });

  testWidgets('nothing pending shows nothing', (tester) async {
    // Arrange
    when(() => update.pending()).thenAnswer((_) async => null);

    // Act
    await pumpPrompt(tester);

    // Assert
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('coming back to the app asks again', (tester) async {
    // Arrange
    when(() => update.pending()).thenAnswer((_) async => null);
    await pumpPrompt(tester);

    // Act
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    // Assert
    verify(() => update.pending()).called(2);
  });
}
