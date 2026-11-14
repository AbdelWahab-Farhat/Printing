import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/customer_messages/models/customer_messages.dart';
import 'package:dayaa/features/customer_messages/presentation/views/customer_messages_page.dart';
import 'package:dayaa/features/customer_messages/repositories/customer_messages_repository.dart';
import 'package:dayaa/features/customer_messages/usecases/customer_messages_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «رسائل الزبائن» — the admin words the ready and return messages.
///
/// What is pinned here: the fields open on the server's wording, a text left equal to the
/// built-in one is sent as null (so it keeps following the default), an edited text is sent as
/// typed, and a reader without `settings.manage` gets no way to save.
///
/// Arrange - Act - Assert throughout.
class _FakeRepository implements CustomerMessagesRepository {
  _FakeRepository([this.stored = _stored]);

  final CustomerMessages stored;

  Map<String, String?>? sent;

  @override
  Future<Either<Failure, CustomerMessages>> messages() async => Right(stored);

  @override
  Future<Either<Failure, CustomerMessages>> update(Map<String, String?> bodies) async {
    sent = bodies;

    return const Right(_stored);
  }
}

const _stored = CustomerMessages(
  placeholder: '{رقم_الفاتورة}',
  messages: [
    CustomerMessageTemplate(
      key: 'ready_pickup',
      label: 'رسالة الجاهزية — استلام مكتب',
      body: 'جاهزة {رقم_الفاتورة}',
      defaultBody: 'جاهزة {رقم_الفاتورة}',
      isCustomised: false,
    ),
    CustomerMessageTemplate(
      key: 'return_courier',
      label: 'رسالة الراجع — راجع لدى المندوب',
      body: 'نصّ المدير',
      defaultBody: 'راجع {رقم_الفاتورة}',
      isCustomised: true,
    ),
  ],
);

/// The vendor text carries a second token, `{الأصناف}`, and its field says where it goes.
const _withVendor = CustomerMessages(
  placeholder: '{رقم_الفاتورة}',
  messages: [
    CustomerMessageTemplate(
      key: 'vendor_request',
      label: 'رسالة المورد — طلبيات التصنيع',
      body: 'طلبية {رقم_الفاتورة}\n{الأصناف}',
      defaultBody: 'طلبية {رقم_الفاتورة}\n{الأصناف}',
      isCustomised: false,
      placeholders: ['{رقم_الفاتورة}', '{الأصناف}'],
    ),
  ],
);

void main() {
  late _FakeRepository repository;

  Future<void> register(List<String> permissions, [CustomerMessages stored = _stored]) async {
    await sl.reset();
    repository = _FakeRepository(stored);
    sl
      ..registerSingleton<Session>(
        Session()..adopt(
          AuthUser(id: 1, name: 'المدير', phone: '0911234567', permissions: permissions),
        ),
      )
      ..registerLazySingleton<GetCustomerMessages>(() => GetCustomerMessages(repository))
      ..registerLazySingleton<UpdateCustomerMessages>(() => UpdateCustomerMessages(repository));
  }

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
      home: CustomerMessagesPage(),
    ),
  );

  tearDown(sl.reset);

  testWidgets('each message opens on the wording in force', (tester) async {
    // Arrange
    await register(['settings.view', 'settings.manage']);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('رسالة الجاهزية — استلام مكتب'), findsOneWidget);
    expect(find.text('رسالة الراجع — راجع لدى المندوب'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'جاهزة {رقم_الفاتورة}'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'نصّ المدير'), findsOneWidget);
  });

  testWidgets('an untouched default is sent as null and an edit as typed', (tester) async {
    // Arrange
    await register(['settings.view', 'settings.manage']);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.enterText(find.widgetWithText(TextField, 'نصّ المدير'), 'نصّ جديد');
    await tester.ensureVisible(find.text('حفظ'));
    await tester.tap(find.text('حفظ'));
    await tester.pump();

    // Assert
    expect(repository.sent, {'ready_pickup': null, 'return_courier': 'نصّ جديد'});

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('«استعادة النص الافتراضي» puts the built-in text back', (tester) async {
    // Arrange
    await register(['settings.view', 'settings.manage']);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act — the second message's reset button.
    await tester.tap(find.text('استعادة النص الافتراضي').last);
    await tester.pump();

    // Assert
    expect(find.widgetWithText(TextField, 'راجع {رقم_الفاتورة}'), findsOneWidget);
  });

  testWidgets('the screen is called «نصوص الرسائل»', (tester) async {
    // Arrange
    await register(['settings.view']);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('نصوص الرسائل'), findsOneWidget);
  });

  testWidgets('only the vendor text says where the lines go', (tester) async {
    // Arrange
    await register(['settings.view', 'settings.manage'], _withVendor);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('رسالة المورد — طلبيات التصنيع'), findsOneWidget);
    expect(find.textContaining('حيث تريد أن تظهر الأصناف'), findsOneWidget);
  });

  testWidgets('a customer text carries no lines hint', (tester) async {
    // Arrange
    await register(['settings.view', 'settings.manage']);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.textContaining('حيث تريد أن تظهر الأصناف'), findsNothing);
  });

  testWidgets('a reader without settings.manage cannot save', (tester) async {
    // Arrange
    await register(['settings.view']);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('حفظ'), findsNothing);
    expect(find.text('استعادة النص الافتراضي'), findsNothing);
  });
}
