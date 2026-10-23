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

/// «روابط التواصل» في صفحة العميل: شعار المنصّة واسمها والرابط مختصراً. لمسةُ السطر تفتحه،
/// والأيقونة في آخره تنسخه.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockCustomerRepository repository;

  const withLinks = Customer(
    id: 7,
    code: 'C10',
    name: 'مطبعة النور',
    phone: '0944909850',
    isActive: true,
    shops: [],
    socialLinks: [
      CustomerSocialLink(id: 4, url: 'https://www.facebook.com/alnoor.print/'),
      CustomerSocialLink(id: 9, url: 'https://wa.me/218912345678'),
    ],
  );

  setUp(() async {
    await Injector.reset();

    repository = _MockCustomerRepository();
    final session = Session();

    sl
      ..registerSingleton<Session>(session)
      ..registerFactoryParam<CustomerDetailCubit, int, void>(
        (customerId, _) => CustomerDetailCubit(
          customerId: customerId,
          getCustomer: GetCustomer(repository),
          setActivation: SetCustomerActivation(repository),
        ),
      );

    session.adopt(
      const AuthUser(id: 1, name: 'عبدالوهاب', phone: '0911234567', permissions: ['customers.view']),
    );
  });

  tearDown(Injector.reset);

  Future<void> open(WidgetTester tester, Customer customer) async {
    when(() => repository.customer(7)).thenAnswer((_) async => Right(customer));

    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
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
      ),
    );
    await tester.pumpAndSettle();
  }

  /// الرسالة المنبثقة تملك مؤقّتاً؛ يُترك ينتهي قبل أن يُهدم الاختبار.
  Future<void> letTheToastGo(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  testWidgets('each link is named by its platform and shown without https', (tester) async {
    // Arrange & Act
    await open(tester, withLinks);

    // Assert
    expect(find.text('روابط التواصل'), findsOneWidget);
    expect(find.text('فيسبوك'), findsOneWidget);
    expect(find.text('facebook.com/alnoor.print'), findsOneWidget);
    expect(find.text('واتساب'), findsOneWidget);
    expect(find.text('wa.me/218912345678'), findsOneWidget);
  });

  testWidgets('a customer with no links has no section at all', (tester) async {
    // Arrange
    final without = withLinks.copyWith(socialLinks: const []);

    // Act
    await open(tester, without);

    // Assert — كالعنوان: جملة «لا توجد روابط» على كلّ عميلٍ قديم لا يعمل بها أحد.
    expect(find.text('روابط التواصل'), findsNothing);
  });

  testWidgets('tapping a link opens it in the platform\'s app', (tester) async {
    // Arrange
    final launched = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (call) async {
        if (call.method == 'launch') launched.add((call.arguments as Map)['url'] as String);

        return true;
      },
    );
    await open(tester, withLinks);

    // Act
    await tester.tap(find.text('wa.me/218912345678'));
    await tester.pumpAndSettle();

    // Assert — الرابط كاملاً كما حُفظ، لا كما يُعرض.
    expect(launched, ['https://wa.me/218912345678']);
  });

  testWidgets('the icon at the end copies the whole link', (tester) async {
    // Arrange
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;

      return null;
    });
    await open(tester, withLinks);

    // Act
    await tester.tap(find.byTooltip('نسخ الرابط').first);
    await tester.pump();

    // Assert
    expect(copied, 'https://www.facebook.com/alnoor.print/');
    expect(find.text('تم نسخ الرابط'), findsOneWidget);
    await letTheToastGo(tester);
  });
}
