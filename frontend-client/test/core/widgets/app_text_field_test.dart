import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

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

  // الكمية في صفحة المنتج رقمٌ كبير في صندوقٍ صغير، والصندوق نفسه صندوق كل الحقول.
  testWidgets('a style from the caller is laid over the field\'s own, which keeps its colour', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(
      host(const AppTextField(style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900))),
    );

    // Act
    final style = field(tester).style!;

    // Assert
    expect(style.fontSize, 30);
    expect(style.fontWeight, FontWeight.w900);
    expect(style.color, isNotNull);
  });

  // العنوان فوق الصندوق لا داخله — «حقولٌ معنونة» كما في تصميم شاشة الدخول، في كل حقول التطبيق.
  group('the label', () {
    testWidgets('sits above the box, not inside it', (tester) async {
      // Arrange
      await tester.pumpWidget(host(const AppTextField(label: 'رقم الهاتف', hint: '09X')));

      // Act
      final label = tester.getRect(find.text('رقم الهاتف'));
      final box = tester.getRect(find.byType(InputDecorator));
      final inside = find.descendant(
        of: find.byType(InputDecorator),
        matching: find.text('رقم الهاتف'),
      );

      // Assert
      expect(inside, findsNothing);
      expect(label.bottom, lessThanOrEqualTo(box.top));
    });

    testWidgets('an action can share its line, at the far end', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(const AppTextField.password(labelAction: Text('نسيتها؟'))),
      );

      // Act
      final label = tester.getRect(find.text('كلمة المرور'));
      final action = tester.getRect(find.text('نسيتها؟'));
      final box = tester.getRect(find.byType(InputDecorator));

      // Assert — العنوان على اليمين حيث تبدأ القراءة، والإجراء على اليسار، وكلاهما فوق الصندوق.
      expect(action.right, lessThanOrEqualTo(label.left));
      expect(action.bottom, lessThanOrEqualTo(box.top));
      expect(label.bottom, lessThanOrEqualTo(box.top));
    });

    testWidgets('a field without one adds nothing above its box', (tester) async {
      // Arrange
      await tester.pumpWidget(host(const AppTextField(hint: 'اكتب ردك…')));

      // Act
      final field = tester.getRect(find.byType(AppTextField));
      final box = tester.getRect(find.byType(InputDecorator));

      // Assert
      expect(box.top, field.top);
    });
  });

  testWidgets('a password field carries no lock of its own, only the eye', (tester) async {
    // Arrange
    await tester.pumpWidget(host(const AppTextField.password()));

    // Act
    final lock = find.byIcon(AppIcons.password);
    final eye = find.byIcon(AppIcons.passwordVisible);

    // Assert
    expect(lock, findsNothing);
    expect(eye, findsOneWidget);
  });

  // صندوق الرسالة في محادثة الدعم: يبدأ بسطرٍ واحد كأي حقل، ويطول مع الكلام حتى سقفه ثم يمرّر.
  testWidgets('a message box starts one line tall and grows only to its cap', (tester) async {
    // Arrange
    final long = TextEditingController(text: List.filled(9, 'سطر').join('\n'));
    addTearDown(long.dispose);
    await tester.pumpWidget(
      host(
        Column(
          children: [
            const AppTextField(key: Key('single')),
            const AppTextField(key: Key('empty'), minLines: 1, maxLines: 4),
            AppTextField(key: const Key('long'), controller: long, minLines: 1, maxLines: 4),
          ],
        ),
      ),
    );

    // Act
    double heightOf(String key) => tester.getSize(find.byKey(Key(key))).height;
    final single = heightOf('single');
    final empty = heightOf('empty');
    final grown = heightOf('long');
    final cap = tester.widget<TextField>(
      find.descendant(of: find.byKey(const Key('long')), matching: find.byType(TextField)),
    );

    // Assert
    expect(empty, single);
    expect(grown, greaterThan(single));
    expect(cap.maxLines, 4);
  });
}
