import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/core/widgets/app_text_field.dart';
import 'package:printing/core/widgets/dismiss_keyboard.dart';

/// Tapping away from a field puts the keyboard away.
///
/// Arrange - Act - Assert throughout.
void main() {
  final fieldFocus = FocusNode();
  final otherFocus = FocusNode();

  tearDownAll(() {
    fieldFocus.dispose();
    otherFocus.dispose();
  });

  Widget host({VoidCallback? onButtonPressed}) => MaterialApp(
    home: DismissKeyboard(
      child: Scaffold(
        body: Column(
          children: [
            TextField(focusNode: fieldFocus),
            const SizedBox(height: 40, child: Text('فراغ')),
            ElevatedButton(
              onPressed: onButtonPressed ?? () {},
              child: const Text('زر'),
            ),
            Expanded(
              child: ListView(
                children: const [SizedBox(height: 600, child: Text('قائمة'))],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  testWidgets('a tap on empty space takes the focus away from the field', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(fieldFocus.hasFocus, isTrue);

    // Act
    await tester.tap(find.text('فراغ'));
    await tester.pump();

    // Assert
    expect(fieldFocus.hasFocus, isFalse);
  });

  testWidgets('a tap inside the field keeps it', (tester) async {
    // Arrange — the wrapper must not fight the thing it is wrapping.
    await tester.pumpWidget(host());

    // Act
    await tester.tap(find.byType(TextField));
    await tester.pump();

    // Assert
    expect(fieldFocus.hasFocus, isTrue);
  });

  testWidgets('a button still gets its own tap', (tester) async {
    // Arrange — the risk of a catch-all tap handler is that it eats the taps meant for
    // something else. It must not: the deeper recogniser wins the arena.
    var taps = 0;
    await tester.pumpWidget(host(onButtonPressed: () => taps++));

    // Act
    await tester.tap(find.text('زر'));
    await tester.pump();

    // Assert
    expect(taps, 1);
  });

  testWidgets('a shared field closes even when something else claims the tap', (tester) async {
    // Arrange — the wrapper cannot see this tap at all: the button wins the gesture arena, so
    // its `onTap` never fires. `AppTextField.onTapOutside` is what covers it, because a
    // `TapRegion` is not in the arena.
    var taps = 0;
    await tester.pumpWidget(
      // AppTextField measures itself with ScreenUtil, so it needs the same frame the app boots
      // into.
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => MaterialApp(
          home: DismissKeyboard(
            child: Scaffold(
              body: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(focusNode: fieldFocus),
                  ElevatedButton(onPressed: () => taps++, child: const Text('زر')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(fieldFocus.hasFocus, isTrue);

    // Act
    await tester.tap(find.text('زر'));
    await tester.pump();

    // Assert — the button did its job *and* the keyboard went away.
    expect(taps, 1);
    expect(fieldFocus.hasFocus, isFalse);
  });

  testWidgets('scrolling a list does not count as tapping away', (tester) async {
    // Arrange — a drag is not a tap. Dismissing on every scroll would make a long form
    // unusable: reaching the next field would close the keyboard on the way.
    await tester.pumpWidget(host());
    await tester.tap(find.byType(TextField));
    await tester.pump();

    // Act
    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pump();

    // Assert
    expect(fieldFocus.hasFocus, isTrue);
  });

  testWidgets('a tap away when nothing is focused does nothing at all', (tester) async {
    // Arrange
    await tester.pumpWidget(host());

    // Act
    await tester.tap(find.text('فراغ'));
    await tester.pump();

    // Assert
    expect(fieldFocus.hasFocus, isFalse);
    expect(tester.takeException(), isNull);
  });
}
