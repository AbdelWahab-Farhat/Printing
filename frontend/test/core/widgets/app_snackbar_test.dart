import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/app_snackbar.dart';

/// The toast, and the one thing it must never do: **lose a refusal.**
///
/// Only one toast is on screen at a time, which is right — three stacked messages are three
/// messages nobody reads. But "only one" was enforced by dropping whichever arrived second, and
/// the second one is routinely the one that mattered: «تم الحفظ» would still be sliding out when
/// the server's «ليس لديك صلاحية» arrived, and the user was left with a screen that had told them
/// the opposite of the truth.
///
/// Arrange - Act - Assert throughout.
void main() {
  // The toast's bookkeeping is library-level — deliberately, so "only one" holds across the whole
  // app rather than per widget. That makes it shared state between tests, and a toast left
  // standing at the end of one test would silence the next. A safety net only: every test below
  // ends with `clear`, because by the time a `tearDown` runs the widget tree has already been
  // finalised and the animation's ticker still belongs to the Navigator being torn down.
  tearDown(resetSnackBars);

  late BuildContext ctx;

  Future<void> clear(WidgetTester tester) async {
    resetSnackBars();
    await tester.pump();
  }

  Widget host() {
    return MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) {
          ctx = context;

          return const Scaffold(body: SizedBox.expand());
        },
      ),
    );
  }

  testWidgets('a refusal replaces whatever is already on screen', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    ctx.showSuccess('تم الحفظ');
    await tester.pump(const Duration(milliseconds: 300));

    // Act — the failure arrives a moment later, while the first toast is still up.
    ctx.showError('ليس لديك صلاحية لتنفيذ هذا الإجراء');
    await tester.pump(const Duration(milliseconds: 600));

    // Assert
    expect(find.text('ليس لديك صلاحية لتنفيذ هذا الإجراء'), findsOneWidget);
    expect(find.text('تم الحفظ'), findsNothing);
    await clear(tester);
  });

  testWidgets('a success does not push a refusal off the screen', (tester) async {
    // Arrange — the other direction, which must not be symmetric: losing «تم الحفظ» costs the
    // user nothing, and losing the reason something failed costs them the work.
    await tester.pumpWidget(host());
    ctx.showError('تعذّر حفظ الطلبية');
    await tester.pump(const Duration(milliseconds: 300));

    // Act
    ctx.showSuccess('تم الحفظ');
    await tester.pump(const Duration(milliseconds: 600));

    // Assert
    expect(find.text('تعذّر حفظ الطلبية'), findsOneWidget);
    expect(find.text('تم الحفظ'), findsNothing);
    await clear(tester);
  });

  testWidgets('the same message twice does not stack, it stays up longer', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    ctx.showError('تعذّر الاتصال');
    await tester.pump(const Duration(milliseconds: 300));

    // Act
    ctx.showError('تعذّر الاتصال');
    await tester.pump(const Duration(milliseconds: 300));

    // Assert
    expect(find.text('تعذّر الاتصال'), findsOneWidget);
    await clear(tester);
  });

  testWidgets('a 422 arrives with the server\'s field messages, not just «غير صحيحة»', (
    tester,
  ) async {
    // Arrange — «البيانات المدخلة غير صحيحة» tells the user only that something is wrong. The
    // sentence they can act on is in `errors`, and it used to end its life in the debug console.
    await tester.pumpWidget(host());

    // Act
    ctx.showFailure(
      const ServerFailure(
        message: 'البيانات المدخلة غير صحيحة',
        statusCode: 422,
        fieldErrors: {
          'name': ['اسم الدور يجب أن يكون أحرفاً إنجليزية صغيرة وأرقاماً وشرطات فقط'],
          'permissions.0': ['الصلاحية المحددة غير معروفة في النظام'],
        },
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    // Assert
    expect(find.text('البيانات المدخلة غير صحيحة'), findsOneWidget);
    expect(
      find.textContaining('اسم الدور يجب أن يكون أحرفاً إنجليزية صغيرة'),
      findsOneWidget,
    );
    expect(find.textContaining('الصلاحية المحددة غير معروفة'), findsOneWidget);
    await clear(tester);
  });

  testWidgets('a failure that repeats its own field error does not say it twice', (tester) async {
    // Arrange — some endpoints send no `message`, and the mapper falls back to flattening
    // `errors` into one. Printing that as both the title and the detail is a stutter.
    await tester.pumpWidget(host());

    // Act
    ctx.showFailure(
      const ServerFailure(
        message: 'اسم الدور مستخدم مسبقاً',
        statusCode: 422,
        fieldErrors: {
          'name': ['اسم الدور مستخدم مسبقاً'],
        },
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    // Assert
    expect(find.text('اسم الدور مستخدم مسبقاً'), findsOneWidget);
    await clear(tester);
  });

  testWidgets('a dropped connection reads as a warning, not as a refusal', (tester) async {
    // Arrange — the tone is the difference between "try again" and "this will not work".
    await tester.pumpWidget(host());

    // Act
    ctx.showFailure(const NetworkFailure(message: FailureMessages.noConnection));
    await tester.pump(const Duration(milliseconds: 400));

    // Assert
    expect(find.text(FailureMessages.noConnection), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    await clear(tester);
  });
}
