import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:dayaa/features/shortages/presentation/viewmodel/shortage_detail_cubit.dart';
import 'package:dayaa/features/shortages/presentation/views/shortage_detail_page.dart';
import 'package:dayaa/features/shortages/repositories/shortage_repository.dart';
import 'package:dayaa/features/shortages/usecases/shortage_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

/// شاشة النقص — ويُخرَج منها.
///
/// **الخروج أولاً، لأنّ شاشةً لا تُغادَر تُغلق التطبيق كلّه.** الصفّ يُسلَّم إلى القائمة **بجانب**
/// المسار لا عبر `pop`، وهو سبب وجود [PopResult] أصلاً: `PopScope(canPop: false)` يُطفئ إيماءة
/// الحافة في iOS — `ModalRoute.popGestureEnabled` يردّ false لأي مسار يقول إنّه قد يعترض — فإن
/// لم يُخرِج الاعتراضُ الشاشةَ بنفسه لم يبقَ للمستخدم باب.
///
/// Arrange - Act - Assert throughout.
class _MockShortageRepository extends Mock implements ShortageRepository {}

void main() {
  late _MockShortageRepository repository;

  /// ما وصل الشاشةَ التي فتحت، بعد أن تُغادَر هذه.
  Shortage? handedBack;

  Shortage shortage({
    String statusLabel = 'جاري البحث',
    List<ShortageTransition> moves = const [],
    ShortageOrderRef? order,
    ShortagePerson? assignee,
  }) => Shortage(
    id: 41,
    code: 'N41',
    source: ShortageSource.manual,
    sourceLabel: 'يدوي',
    name: 'كيس شحن — 25*35',
    unit: 'piece',
    unitLabel: 'قطعة',
    requiredQuantity: '200.000',
    suppliedQuantity: '200.000',
    remainingQuantity: '0.000',
    totalPaid: '100.00',
    status: ShortageStatus.searching,
    statusLabel: statusLabel,
    availableTransitions: moves,
    order: order,
    orderId: order?.id,
    assignee: assignee,
  );

  Future<void> sign(
    List<Shortage> readings, {
    List<String> permissions = const ['shortages.view', 'shortages.manage'],
  }) async {
    await Injector.reset();

    repository = _MockShortageRepository();

    // كل كتابة تنتهي بقراءة جديدة — فالقراءات تُسلَّم بالترتيب، وآخرها يبقى.
    var read = 0;
    when(() => repository.shortage(41)).thenAnswer((_) async {
      final reading = readings[read < readings.length - 1 ? read++ : readings.length - 1];

      return Right(reading);
    });

    sl
      ..registerSingleton<Session>(
        Session()..adopt(
          AuthUser(
            id: 1,
            name: 'عبدالوهاب',
            phone: '0911234567',
            permissions: permissions,
          ),
        ),
      )
      ..registerFactoryParam<ShortageDetailCubit, int, void>(
        (shortageId, _) => ShortageDetailCubit(
          shortageId: shortageId,
          getShortage: GetShortage(repository),
          changeStatus: ChangeShortageStatus(repository),
          assignShortage: AssignShortage(repository),
          recordSupply: RecordShortageSupply(repository),
          reverseSupply: ReverseShortageSupply(repository),
          setWarehouseQuantity: SetShortageWarehouseQuantity(repository),
        ),
      );
  }

  Widget host() {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  handedBack = await context.pushForResult<Shortage>('/shortage');
                },
                child: const Text('افتح'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/shortage',
          builder: (context, state) => const ShortageDetailPage(shortageId: 41),
        ),
        GoRoute(
          path: '/orders/:id',
          builder: (context, state) =>
              Scaffold(body: Center(child: Text('طلبية ${state.pathParameters['id']}'))),
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

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
  }

  setUp(() => handedBack = null);
  tearDown(Injector.reset);

  testWidgets('the arrow leaves the screen', (tester) async {
    // Arrange
    await sign([shortage()]);
    await open(tester);
    expect(find.byType(ShortageDetailPage), findsOneWidget);

    // Act
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Assert — شاشةٌ تعترض الخروج ولا تُخرِج أحداً تحبس المستخدم فيها، ولا مخرج له إلا قتل
    // التطبيق: إيماءة الحافة مطفأةٌ بالاعتراض نفسه.
    expect(find.byType(ShortageDetailPage), findsNothing);
    expect(find.text('افتح'), findsOneWidget);
  });

  testWidgets('the Android back button leaves it too', (tester) async {
    // Arrange
    await sign([shortage()]);
    await open(tester);

    // Act
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(ShortageDetailPage), findsNothing);
  });

  testWidgets('what changed while it was open is handed back on the way out', (tester) async {
    // Arrange — قراءتان: ما فُتحت عليه، وما صارت إليه بعد نقل الحالة.
    final moved = shortage(statusLabel: 'تم الشراء');

    await sign([
      shortage(moves: const [ShortageTransition(value: 'purchased', label: 'تم الشراء')]),
      moved,
    ]);
    when(
      () => repository.changeStatus(41, status: any(named: 'status')),
    ).thenAnswer((_) async => Right(moved));

    await open(tester);

    // Act
    await tester.tap(find.text('تحويل إلى «تم الشراء»'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Assert — «القوائم تُرقَّع، ولا تُحدَّث»: الصفّ يُسلَّم بجانب المسار، فيصل مهما كان الباب
    // الذي خرج منه المستخدم.
    expect(handedBack, moved);
  });

  testWidgets('a screen nothing happened on hands back nothing', (tester) async {
    // Arrange
    await sign([shortage()]);
    await open(tester);

    // Act
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Assert — القائمة خلفها تعرض هذا الصفّ نفسه، فترقيعه بما لديها عمَلٌ بلا سبب.
    expect(handedBack, isNull);
  });

  testWidgets('the order it came from sits above the figures, and taps through', (tester) async {
    // Arrange
    await sign([
      shortage(order: const ShortageOrderRef(id: 1274, code: '1274')),
    ]);

    // Act
    await open(tester);

    // Assert — النقص وُلد من الطلبية، فهي سياق كل رقم تحتها: تُقرأ قبلها لا بعدها.
    expect(
      tester.getCenter(find.text('الطلبية #1274')).dy,
      lessThan(tester.getCenter(find.text('إجمالي المطلوب')).dy),
    );

    // Act — وهي باب، لا سطر يُقرأ.
    await tester.tap(find.text('الطلبية #1274'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('طلبية 1274'), findsOneWidget);
  });

  testWidgets('the assignee is a chip, and it says it can be tapped', (tester) async {
    // Arrange
    await sign(
      [shortage()],
      permissions: const ['shortages.view', 'shortages.manage', 'shortages.assign'],
    );

    // Act
    await open(tester);

    // Assert — «غير مُسنَد» بنصٍّ أبيض بين ثلاث وقائع لا يقول لأحدٍ إنّه يُضغط، وهو السؤال الذي
    // وصل: «كيف أعيّن مسؤولاً؟». فيُرسم شريحةً مثل الحالة فوقه.
    expect(find.byKey(const ValueKey('assign-shortage')), findsOneWidget);
    expect(find.text('غير مُسنَد'), findsOneWidget);
  });

  testWidgets('a reader who may not assign is told who has it, and nothing more', (tester) async {
    // Arrange — `shortages.assign` منفصلة عن `shortages.manage` عمداً: توجيه الشغل غير عمله.
    await sign(
      [shortage(assignee: const ShortagePerson(id: 9, name: 'أبو القاسم'))],
      permissions: const ['shortages.view', 'shortages.manage'],
    );

    // Act
    await open(tester);

    // Assert — الواقعة تبقى، والزرّ وحده يغيب.
    expect(find.text('أبو القاسم'), findsOneWidget);
    expect(find.byKey(const ValueKey('assign-shortage')), findsNothing);
  });
}
