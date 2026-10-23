import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/business_fields/models/business_field.dart';
import 'package:dayaa/features/business_fields/presentation/viewmodel/business_fields_cubit.dart';
import 'package:dayaa/features/business_fields/repositories/business_field_repository.dart';
import 'package:dayaa/features/business_fields/usecases/delete_business_field.dart';
import 'package:dayaa/features/business_fields/usecases/get_business_fields.dart';
import 'package:dayaa/features/business_fields/usecases/set_business_field_activation.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/models/new_customer.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/add_customer_cubit.dart';
import 'package:dayaa/features/customers/presentation/views/add_customer_page.dart';
import 'package:dayaa/features/customers/repositories/customer_repository.dart';
import 'package:dayaa/features/customers/usecases/create_customer.dart';
import 'package:dayaa/features/customers/usecases/update_customer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

/// «روابط التواصل» في نموذج العميل: سطرٌ لكلّ رابط باسم منصّته وشعارها، و«إضافة رابط» تحتها.
///
/// Cubit حقيقي وحالات استخدام حقيقية ومستودعٌ مزيّف — فما يُؤكَّد عليه هو ما يصل إلى الخادم.
///
/// Arrange - Act - Assert throughout.
class _MockCustomerRepository extends Mock implements CustomerRepository {}

class _MockBusinessFieldRepository extends Mock implements BusinessFieldRepository {}

void main() {
  late _MockCustomerRepository customers;
  late _MockBusinessFieldRepository businessFields;

  const existing = Customer(
    id: 7,
    code: 'C7',
    name: 'مطبعة النور',
    phone: '0913334444',
    isActive: true,
    shops: [],
    socialLinks: [
      CustomerSocialLink(id: 4, url: 'https://facebook.com/alnoor.print'),
      CustomerSocialLink(id: 9, url: 'https://instagram.com/alnoor.print'),
    ],
  );

  setUpAll(() => registerFallbackValue(const NewCustomer(name: '', phone: '')));

  setUp(() async {
    await Injector.reset();

    customers = _MockCustomerRepository();
    businessFields = _MockBusinessFieldRepository();

    when(() => customers.create(any())).thenAnswer((_) async => const Right(existing));
    when(() => customers.update(any(), any())).thenAnswer((_) async => const Right(existing));
    when(
      () => businessFields.fields(
        search: any(named: 'search'),
        isActive: any(named: 'isActive'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => const Right(
        Paginated<BusinessField>(
          items: [],
          meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 0),
        ),
      ),
    );

    sl
      ..registerFactory<AddCustomerCubit>(
        () => AddCustomerCubit(
          createCustomer: CreateCustomer(customers),
          updateCustomer: UpdateCustomer(customers),
        ),
      )
      ..registerFactory<BusinessFieldsCubit>(
        () => BusinessFieldsCubit(
          getBusinessFields: GetBusinessFields(businessFields),
          setActivation: SetBusinessFieldActivation(businessFields),
          deleteBusinessField: DeleteBusinessField(businessFields),
        )..isActive = true,
        instanceName: 'active-only',
      );
  });

  tearDown(Injector.reset);

  /// موجّهٌ لا `home:` — الشاشة تخرج بـ`context.canPop()` بعد الحفظ.
  Future<void> open(WidgetTester tester, {Customer? customer}) async {
    tester.view
      ..physicalSize = const Size(430 * 3, 1600 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/form',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('الرئيسية'))),
        GoRoute(path: '/form', builder: (_, _) => AddCustomerPage(customer: customer)),
      ],
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => MaterialApp.router(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// خانة الرابط رقم [index]: بعد الاسم والهاتف.
  Finder linkField(int index) => find.byType(TextFormField).at(2 + index);

  /// يضغط الحفظ ويترك رسالة النجاح تنتهي، فلا يبقى مؤقّتها معلّقاً بعد الاختبار.
  Future<void> save(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  }

  NewCustomer sentUpdate() =>
      verify(() => customers.update(7, captureAny())).captured.last as NewCustomer;

  testWidgets('an existing customer\'s links open as rows named by their platform', (tester) async {
    // Arrange & Act
    await open(tester, customer: existing);

    // Assert
    expect(find.text('روابط التواصل'), findsOneWidget);
    expect(find.text('فيسبوك'), findsOneWidget);
    expect(find.text('إنستغرام'), findsOneWidget);
    expect(find.text('https://facebook.com/alnoor.print'), findsOneWidget);
  });

  testWidgets('the label follows what is typed, from «رابط» to the platform', (tester) async {
    // Arrange
    await open(tester);
    await tester.tap(find.text('إضافة رابط'));
    await tester.pumpAndSettle();
    final labelBefore = find.text('رابط');

    // Act
    await tester.enterText(linkField(0), 'tiktok.com/@alnoor');
    await tester.pump();

    // Assert
    expect(labelBefore, findsNothing);
    expect(find.text('تيك توك'), findsOneWidget);
  });

  testWidgets('a removed row is left out of the save, and the kept one keeps its id', (tester) async {
    // Arrange
    await open(tester, customer: existing);

    // Act
    await tester.tap(find.byTooltip('حذف الرابط').first);
    await tester.pumpAndSettle();
    await save(tester, 'حفظ التعديلات');

    // Assert
    expect(sentUpdate().socialLinks, const [
      NewCustomerSocialLink(id: 9, url: 'https://instagram.com/alnoor.print'),
    ]);
  });

  testWidgets('a link typed without https is saved with it', (tester) async {
    // Arrange
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'مطبعة النور');
    await tester.enterText(find.byType(TextFormField).at(1), '0913334444');
    await tester.tap(find.text('إضافة رابط'));
    await tester.pumpAndSettle();
    await tester.enterText(linkField(0), 'instagram.com/alnoor');

    // Act
    await save(tester, 'إضافة العميل');

    // Assert
    final sent = verify(() => customers.create(captureAny())).captured.last as NewCustomer;
    expect(sent.socialLinks, const [NewCustomerSocialLink(url: 'https://instagram.com/alnoor')]);
  });

  testWidgets('an empty row refuses to be saved', (tester) async {
    // Arrange — سطرٌ بدأه المستخدم يُكمَل أو يُحذف، كسطر المحل.
    await open(tester, customer: existing);
    await tester.tap(find.text('إضافة رابط'));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('حفظ التعديلات'));
    await tester.pumpAndSettle();

    // Assert
    verifyNever(() => customers.update(any(), any()));
  });

  testWidgets('words that are not a link are refused before a request', (tester) async {
    // Arrange
    await open(tester, customer: existing);
    await tester.enterText(linkField(0), 'alnoor print');

    // Act
    await tester.tap(find.text('حفظ التعديلات'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('الرابط غير صحيح'), findsOneWidget);
    verifyNever(() => customers.update(any(), any()));
  });

  testWidgets('the server\'s complaint lands under the row it named', (tester) async {
    // Arrange
    when(() => customers.update(any(), any())).thenAnswer(
      (_) async => const Left(
        ServerFailure(
          message: 'الرابط مكرر',
          statusCode: 422,
          fieldErrors: {
            'social_links.1.url': ['الرابط مكرر'],
          },
        ),
      ),
    );
    await open(tester, customer: existing);

    // Act
    await save(tester, 'حفظ التعديلات');

    // Assert — تحت السطر الثاني، فخانته هي التي تحمل الخطأ.
    final second = tester.widget<TextField>(
      find.descendant(of: linkField(1), matching: find.byType(TextField)),
    );
    expect(second.decoration?.errorText, 'الرابط مكرر');
  });

  testWidgets('no more than ten rows can be added', (tester) async {
    // Arrange
    await open(tester);

    // Act
    for (var i = 0; i < 10; i++) {
      await tester.ensureVisible(find.text('إضافة رابط'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إضافة رابط'));
      await tester.pumpAndSettle();
    }

    // Assert — حدُّ الخادم نفسه، فالزرّ يتوقّف بدل أن يُردّ الحفظ.
    final button = tester.widget<AppButton>(find.widgetWithText(AppButton, 'إضافة رابط'));
    expect(button.onPressed, isNull);
  });

  testWidgets('no sentence explains the address or the shops any more', (tester) async {
    // Arrange & Act
    await open(tester);

    // Assert
    expect(
      find.text('تبدأ منه الطلبيات الجديدة حين لا يُختار محل، ويبقى قابلاً للتعديل في كل طلبية.'),
      findsNothing,
    );
    expect(find.text('المكان الذي يبيع منه العميل، ومدينته والمنطقة التي يقع فيها.'), findsNothing);
  });
}
