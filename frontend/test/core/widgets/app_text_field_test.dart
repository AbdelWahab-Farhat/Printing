import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/widgets/app_text_field.dart';

/// The shared input's own behaviour — the part that is not decoration.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// The same frame the app boots into: ScreenUtil initialised at the reference design size,
  /// Arabic and right-to-left, because the field is never rendered in any other.
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
        home: Scaffold(body: Directionality(
          textDirection: TextDirection.rtl,
          child: child,
        )),
      ),
    );
  }

  TextField field(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField));

  group('password', () {
    testWidgets('starts masked', (tester) async {
      // Arrange
      await tester.pumpWidget(host(const AppTextField.password()));

      // Act
      await tester.pump();

      // Assert
      expect(field(tester).obscureText, isTrue);
      expect(find.byIcon(AppIcons.passwordVisible), findsOneWidget);
    });

    testWidgets('the eye reveals the characters, and hides them again', (tester) async {
      // Arrange
      await tester.pumpWidget(host(const AppTextField.password()));

      // Act
      await tester.tap(find.byIcon(AppIcons.passwordVisible));
      await tester.pump();

      // Assert
      expect(field(tester).obscureText, isFalse);
      expect(find.byIcon(AppIcons.passwordHidden), findsOneWidget);

      // Act — back again
      await tester.tap(find.byIcon(AppIcons.passwordHidden));
      await tester.pump();

      // Assert
      expect(field(tester).obscureText, isTrue);
    });
  });

  group('errors', () {
    testWidgets('an error handed in from outside is rendered', (tester) async {
      // Arrange
      const serverMessage = 'رقم الهاتف أو كلمة المرور غير صحيحة';

      // Act
      await tester.pumpWidget(host(const AppTextField(errorText: serverMessage)));

      // Assert
      expect(find.text(serverMessage), findsOneWidget);
    });

    testWidgets('the validator is what the form asks, and its message is shown', (tester) async {
      // Arrange
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        host(
          Form(
            key: formKey,
            child: AppTextField(
              validator: (value) => (value ?? '').isEmpty ? 'هذا الحقل مطلوب' : null,
            ),
          ),
        ),
      );

      // Act
      final isValid = formKey.currentState!.validate();
      await tester.pump();

      // Assert
      expect(isValid, isFalse);
      expect(find.text('هذا الحقل مطلوب'), findsOneWidget);
    });
  });

  testWidgets('text starts at the reading edge, and nothing is added on the far side', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(
      host(const AppTextField(prefixIcon: Icons.phone_outlined, hint: '09XXXXXXXX')),
    );

    // Act
    final decoration = field(tester).decoration!;

    // Assert
    expect(field(tester).textAlign, TextAlign.start);
    expect(decoration.suffixIcon, isNull);
  });

  testWidgets('typing reaches the caller', (tester) async {
    // Arrange
    final typed = <String>[];
    await tester.pumpWidget(host(AppTextField(onChanged: typed.add)));

    // Act
    await tester.enterText(find.byType(TextField), '0912345678');

    // Assert
    expect(typed, ['0912345678']);
  });
}
