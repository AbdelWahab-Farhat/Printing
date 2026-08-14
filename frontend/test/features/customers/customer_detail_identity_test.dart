import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customer_detail_cubit.dart';
import 'package:dayaa/features/customers/presentation/views/customer_detail_page.dart';
import 'package:dayaa/features/customers/repositories/customer_repository.dart';
import 'package:dayaa/features/customers/usecases/get_customer.dart';
import 'package:dayaa/features/customers/usecases/set_customer_activation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCustomerRepository extends Mock implements CustomerRepository {}

/// Who the customer is, in the one row at the top of their screen.
///
/// **The «معلومات الاتصال» card is gone and these are what replaced it.** A titled card with a
/// border and two labelled rows was wrapping two values one line long each; the phone reads
/// under the name and the code sits in the corner, and both still copy. What is worth pinning is
/// the arrangement — a phone that drifts back below the fold, or a code that stops copying, is
/// exactly the regression that card was removed to avoid re-introducing.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockCustomerRepository repository;
  late Session session;

  const customer = Customer(
    id: 7,
    code: 'C10',
    name: 'مطبعة النور',
    phone: '0944909850',
    isActive: true,
    shops: [],
  );

  setUp(() async {
    await Injector.reset();

    repository = _MockCustomerRepository();
    session = Session();

    when(() => repository.customer(7)).thenAnswer((_) async => const Right(customer));

    sl
      ..registerSingleton<Session>(session)
      ..registerFactoryParam<CustomerDetailCubit, int, void>(
        (customerId, _) => CustomerDetailCubit(
          customerId: customerId,
          getCustomer: GetCustomer(repository),
          setActivation: SetCustomerActivation(repository),
        ),
      );

    // Customers only: the orders section has a screen of its own to be proved on, and leaving
    // it out here keeps this file about the identity row.
    session.adopt(
      const AuthUser(
        id: 1,
        name: 'عبدالوهاب',
        phone: '0911234567',
        permissions: ['customers.view'],
      ),
    );
  });

  tearDown(Injector.reset);

  Widget host() => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => const MaterialApp(
      locale: Locale('ar'),
      supportedLocales: [Locale('ar')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: CustomerDetailPage(customerId: 7),
    ),
  );

  /// Opens the screen on a phone-shaped surface — see the note in
  /// `customer_detail_orders_test.dart`.
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
  }

  /// The name as the *page* draws it. The app bar prints it too — it says whose screen this is
  /// the moment the name is known — so an unscoped finder matches twice.
  final nameInBody = find.descendant(
    of: find.byType(ListView),
    matching: find.text('مطبعة النور'),
  );

  testWidgets('there is no contact card any more', (tester) async {
    // Arrange & Act
    await open(tester);

    // Assert — the frame is gone, and so are the row labels it needed to explain itself.
    expect(find.text('معلومات الاتصال'), findsNothing);
    expect(find.text('رقم الهاتف'), findsNothing);
    expect(find.text('رمز العميل'), findsNothing);
  });

  testWidgets('the phone sits directly under the name', (tester) async {
    // Arrange
    await open(tester);

    // Act
    final name = tester.getCenter(nameInBody);
    final phone = tester.getCenter(find.text('0944909850'));

    // Assert — under it, and starting from the same edge: this is one block about one person,
    // not two rows that happen to be near each other.
    expect(phone.dy, greaterThan(name.dy));
    expect(tester.getTopLeft(find.text('0944909850')).dx, closeTo(
      tester.getTopLeft(nameInBody).dx,
      24,
    ));
  });

  testWidgets('the code sits in the far corner, past the name', (tester) async {
    // Arrange
    await open(tester);

    // Act
    final code = tester.getCenter(find.text('C10'));
    final name = tester.getCenter(nameInBody);

    // Assert — position, not alignment: the badge is the last child of an RTL row, which is what
    // stops it drifting when a long name grows.
    expect(code.dx, lessThan(name.dx));
  });

  testWidgets('the code is drawn once, and big', (tester) async {
    // Arrange
    await open(tester);

    // Act
    final code = find.text('C10');

    // Assert — once: it used to be a line under the name *and* a row in the contact card, and a
    // value repeated on one screen makes the reader check whether the two agree.
    expect(code, findsOneWidget);
    expect(
      tester.widget<Text>(code).style?.fontSize,
      greaterThan(tester.widget<Text>(nameInBody).style!.fontSize!),
      reason: 'the code is what this customer is quoted by — it should not read as a caption',
    );
  });

  testWidgets('tapping the phone copies it', (tester) async {
    // Arrange
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;

      return null;
    });
    await open(tester);

    // Act
    await tester.tap(find.text('0944909850'));
    await tester.pump();

    // Assert — the errand this screen exists for on a phone: the number gets pasted into
    // WhatsApp.
    expect(copied, '0944909850');
    expect(find.text('تم نسخ رقم الهاتف'), findsOneWidget);

    // The toast owns an animation and a dismissal timer; left running they outlive this test.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('tapping the code copies it', (tester) async {
    // Arrange
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;

      return null;
    });
    await open(tester);

    // Act
    await tester.tap(find.text('C10'));
    await tester.pump();

    // Assert
    expect(copied, 'C10');
    expect(find.text('تم نسخ رمز العميل'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
