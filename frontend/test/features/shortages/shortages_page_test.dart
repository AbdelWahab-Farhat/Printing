import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:dayaa/features/shortages/models/shortage_counts.dart';
import 'package:dayaa/features/shortages/presentation/viewmodel/shortages_cubit.dart';
import 'package:dayaa/features/shortages/presentation/views/shortages_page.dart';
import 'package:dayaa/features/shortages/repositories/shortage_repository.dart';
import 'package:dayaa/features/shortages/usecases/shortage_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// قائمة النواقص، وتبويبات الإسناد فوقها.
///
/// **الإسناد سؤالٌ يُقلَّب، لا سؤالٌ يُضبَط مرّة.** «مَن يلاحق ماذا» هو ما يفتح المشرف الشاشةَ
/// لأجله، فصار تبويباً فوق القائمة بدل قسمٍ داخل ورقة التصفية — والورقة تبقى لما يُضبط ويُنسى:
/// حالة النقص.
///
/// Arrange - Act - Assert throughout.
class _MockShortageRepository extends Mock implements ShortageRepository {}

void main() {
  late _MockShortageRepository repository;

  Shortage shortage(int id) => Shortage(
    id: id,
    code: 'N$id',
    source: ShortageSource.manual,
    sourceLabel: 'يدوي',
    name: 'كيس شحن — 25*35',
    unit: 'piece',
    unitLabel: 'قطعة',
    requiredQuantity: '200.000',
    suppliedQuantity: '0.000',
    remainingQuantity: '200.000',
    totalPaid: '0.00',
    status: ShortageStatus.fresh,
    statusLabel: 'جديد',
  );

  Future<void> sign() async {
    await Injector.reset();

    repository = _MockShortageRepository();

    when(
      () => repository.shortages(
        statuses: any(named: 'statuses'),
        assignedTo: any(named: 'assignedTo'),
        productId: any(named: 'productId'),
        orderId: any(named: 'orderId'),
        customerId: any(named: 'customerId'),
        source: any(named: 'source'),
        search: any(named: 'search'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => Right(
        Paginated<Shortage>(
          items: [shortage(41)],
          meta: const PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 1),
        ),
      ),
    );

    when(
      () => repository.statusCounts(
        assignedTo: any(named: 'assignedTo'),
        productId: any(named: 'productId'),
        orderId: any(named: 'orderId'),
        customerId: any(named: 'customerId'),
        source: any(named: 'source'),
        search: any(named: 'search'),
      ),
    ).thenAnswer((_) async => const Right(ShortageCounts.empty()));

    sl
      ..registerSingleton<Session>(
        Session()..adopt(
          const AuthUser(
            id: 1,
            name: 'عبدالوهاب',
            phone: '0911234567',
            permissions: ['shortages.view'],
          ),
        ),
      )
      ..registerFactory<ShortagesCubit>(
        () => ShortagesCubit(
          getShortages: GetShortages(repository),
          getCounts: GetShortageCounts(repository),
        ),
      );
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
      home: ShortagesPage(),
    ),
  );

  /// What the list was last asked for, on the assignment axis alone.
  String? lastAsked() {
    final call = verify(
      () => repository.shortages(
        statuses: any(named: 'statuses'),
        assignedTo: captureAny(named: 'assignedTo'),
        productId: any(named: 'productId'),
        orderId: any(named: 'orderId'),
        customerId: any(named: 'customerId'),
        source: any(named: 'source'),
        search: any(named: 'search'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    );

    return call.captured.last as String?;
  }

  tearDown(Injector.reset);

  testWidgets('three tabs sit above the list', (tester) async {
    // Arrange - Act
    await sign();
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — وتُفتح الشاشة على «الكل»، وهي كلّ ما في القسم.
    expect(find.widgetWithText(Tab, 'الكل'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'مسندة'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'غير مسندة'), findsOneWidget);
    expect(lastAsked(), isNull);
  });

  testWidgets('«غير مسندة» asks the server for the queue', (tester) async {
    // Arrange
    await sign();
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.widgetWithText(Tab, 'غير مسندة'));
    await tester.pumpAndSettle();

    // Assert — «غير مُسنَد» طابورٌ يُشتغل منه، لا غيابُ جواب: الخادم يأخذ له كلمة «none».
    expect(lastAsked(), 'none');
  });

  testWidgets('«مسندة» is the reader\'s own work', (tester) async {
    // Arrange
    await sign();
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.widgetWithText(Tab, 'مسندة'));
    await tester.pumpAndSettle();

    // Assert — «إليّ أنا» لا تُعرف إلا من الرمز على الخادم، ولهذا تسافر كلمةً لا رقماً.
    expect(lastAsked(), 'me');
  });

  testWidgets('going back to «الكل» widens it again', (tester) async {
    // Arrange
    await sign();
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, 'غير مسندة'));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.widgetWithText(Tab, 'الكل'));
    await tester.pumpAndSettle();

    // Assert
    expect(lastAsked(), isNull);
  });
}
