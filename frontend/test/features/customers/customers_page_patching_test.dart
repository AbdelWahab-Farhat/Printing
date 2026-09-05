import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/models/customers_filter.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customers_cubit.dart';
import 'package:dayaa/features/customers/repositories/customer_repository.dart';
import 'package:dayaa/features/customers/usecases/get_customers.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/investors_cubit.dart';
import 'package:dayaa/features/investors/repositories/investor_repository.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:dayaa/features/root/presentation/views/parties_page.dart';
import 'package:dayaa/features/vendors/models/vendor.dart';
import 'package:dayaa/features/vendors/presentation/viewmodel/vendors_cubit.dart';
import 'package:dayaa/features/vendors/repositories/vendor_repository.dart';
import 'package:dayaa/features/vendors/usecases/get_vendors.dart';
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

/// The two registers this screen shows beside the customers, stubbed to nothing: the tabs are
/// there because [PartiesPage] hosts all three, and neither is what these tests assert.
class _MockVendorRepository extends Mock implements VendorRepository {}

class _MockInvestorRepository extends Mock implements InvestorRepository {}

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

    final vendors = _MockVendorRepository();
    when(
      () => vendors.vendors(
        search: any(named: 'search'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => const Right(
        Paginated<Vendor>(
          items: [],
          meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 0),
        ),
      ),
    );
    sl.registerFactory<VendorsCubit>(() => VendorsCubit(getVendors: GetVendors(vendors)));

    final investors = _MockInvestorRepository();
    when(
      () => investors.investors(
        search: any(named: 'search'),
        isActive: any(named: 'isActive'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => const Right(
        Paginated<Investor>(
          items: [],
          meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 0),
        ),
      ),
    );
    sl.registerFactory<InvestorsCubit>(
      () => InvestorsCubit(getInvestors: GetInvestors(investors)),
    );

    // A reader who may see and register customers and nothing else — so no filter button (it
    // asks the server questions of its own), one tab rather than three, and a dial that
    // collapses to the single «إضافة عميل» button.
    sl.registerSingleton<Session>(
      Session()
        ..adopt(
          const AuthUser(
            id: 1,
            name: 'عبدالوهاب',
            phone: '0911234567',
            permissions: ['customers.view', 'customers.manage'],
          ),
        ),
    );
  });

  tearDown(Injector.reset);

  /// The tab, with stubs standing in for the two screens it opens.
  Widget host() {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const PartiesPage()),
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
    await tester.tap(find.text('إضافة عميل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أغلق'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('مكتبة الأمل'), findsOneWidget);
    expect(find.text('مطبعة النور'), findsOneWidget);
    expect(reads(), 1);
  });
}
