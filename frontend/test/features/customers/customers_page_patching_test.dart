import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/models/customers_filter.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customers_cubit.dart';
import 'package:dayaa/features/customers/presentation/views/customers_page.dart';
import 'package:dayaa/features/customers/repositories/customer_repository.dart';
import 'package:dayaa/features/customers/usecases/get_customers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

/// Coming back from a customer's own screen, and what the list does about it.
///
/// **The complaint this answers, in the user's words: «كل ما ادخل لصفحة تفاصيل ثم ارجع يتم
/// تحديث الصفحة».** The list used to call `refresh()` on every return — a skeleton over the
/// whole page, page one re-fetched, and a list scrolled halfway down thrown back to the top, all
/// to redraw one card whose new contents the screen that just closed was holding.
///
/// So the detail screen hands the customer back and the row is patched in place. A screen that
/// was only read hands back nothing, and nothing moves.
///
/// Arrange - Act - Assert throughout.
class _MockCustomerRepository extends Mock implements CustomerRepository {}

void main() {
  late _MockCustomerRepository repository;

  /// What the stub detail screen answers with — a changed customer, or nothing.
  Customer? detailAnswers;

  const nour = Customer(
    id: 7,
    code: 'C7',
    name: 'مطبعة النور',
    phone: '0912345678',
    isActive: true,
  );

  const registered = Customer(
    id: 8,
    code: 'C8',
    name: 'مكتبة الأمل',
    phone: '0913456789',
    isActive: true,
  );

  Paginated<Customer> page(List<Customer> items) => Paginated(
    items: items,
    meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: items.length),
  );

  setUpAll(() => registerFallbackValue(CustomersSort.newest));

  setUp(() async {
    await Injector.reset();

    detailAnswers = null;
    repository = _MockCustomerRepository();

    when(
      () => repository.customers(
        search: any(named: 'search'),
        isActive: any(named: 'isActive'),
        hasOrders: any(named: 'hasOrders'),
        sort: any(named: 'sort'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(page([nour])));

    sl.registerFactory<CustomersCubit>(
      () => CustomersCubit(getCustomers: GetCustomers(repository)),
    );

    // A reader who may not see orders, so the filter button stays out of the way: it is not what
    // is being asserted here, and it asks the server questions of its own.
    sl.registerSingleton<Session>(
      Session()
        ..adopt(
          const AuthUser(id: 1, name: 'عبدالوهاب', phone: '0911234567', permissions: []),
        ),
    );
  });

  tearDown(Injector.reset);

  /// The tab, with stubs standing in for the two screens it opens.
  Widget host() {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const CustomersPage()),
        // Before `/customers/:id`, or «new» is read as an id.
        GoRoute(
          path: Routes.addCustomer,
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.pop(detailAnswers),
                child: const Text('أغلق'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/customers/:id',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.pop(detailAnswers),
                child: const Text('أغلق'),
              ),
            ),
          ),
        ),
      ],
    );

    return ScreenUtilInit(
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
    );
  }

  /// How many times the list has been asked for. The first is the one that filled the screen.
  int reads() => verify(
    () => repository.customers(
      search: any(named: 'search'),
      isActive: any(named: 'isActive'),
      hasOrders: any(named: 'hasOrders'),
      sort: any(named: 'sort'),
      page: any(named: 'page'),
      perPage: any(named: 'perPage'),
    ),
  ).callCount;

  Future<void> openAndCloseTheDetail(WidgetTester tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('مطبعة النور'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('أغلق'));
    await tester.pumpAndSettle();
  }

  testWidgets('a screen that was only read costs the list nothing', (tester) async {
    // Arrange — the detail screen changed nothing, so it hands back nothing.
    detailAnswers = null;

    // Act
    await openAndCloseTheDetail(tester);

    // Assert — one read, the one that filled the screen in the first place.
    expect(reads(), 1);
    expect(find.text('مطبعة النور'), findsOneWidget);
  });

  testWidgets('a renamed customer is redrawn in place, with no request', (tester) async {
    // Arrange — the detail screen hands back the customer as the server now has them.
    detailAnswers = nour.copyWith(name: 'مطبعة النور الحديثة');

    // Act
    await openAndCloseTheDetail(tester);

    // Assert
    expect(find.text('مطبعة النور الحديثة'), findsOneWidget);
    expect(find.text('مطبعة النور'), findsNothing);
    expect(reads(), 1, reason: 'the row that changed came back with the screen that changed it');
  });

  testWidgets('a registered customer goes to the top of the list', (tester) async {
    // Arrange — the register is newest-first, which is exactly where the form's answer belongs.
    detailAnswers = registered;

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('عميل جديد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أغلق'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('مكتبة الأمل'), findsOneWidget);
    expect(find.text('مطبعة النور'), findsOneWidget);
    expect(reads(), 1);
  });
}
