import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/features/billboards/models/billboard.dart';
import 'package:dayaa_client/features/billboards/models/house_ad.dart';
import 'package:dayaa_client/features/billboards/presentation/viewmodel/billboard_cubit.dart';
import 'package:dayaa_client/features/billboards/presentation/views/billboard_carousel.dart';
import 'package:dayaa_client/features/billboards/repositories/billboard_repository.dart';
import 'package:dayaa_client/features/billboards/usecases/get_billboards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _StubBillboards implements BillboardRepository {
  _StubBillboards(this._answer);

  final Either<Failure, List<Billboard>> _answer;

  @override
  Future<Either<Failure, List<Billboard>>> showing() async => _answer;
}

/// شريط الإعلانات أعلى الرئيسية: إعلانات المتجر، أو إعلانات التطبيق حين لا يعرض المتجر شيئاً.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// تقليبةٌ واحدة: خمس ثوانٍ حتى يبدأ الانزلاق، ثم إطاراتٌ حتى يكتمل. **لا تُختصر في `pump`
  /// واحدة**: الساعة تقفز الثواني الخمس دفعةً واحدة، والانزلاق لا يبدأ عدّه إلا من أول إطارٍ بعدها.
  Future<void> turnOnce(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
  }

  Future<BillboardCubit> cubitAnswering(Either<Failure, List<Billboard>> answer) async {
    final cubit = BillboardCubit(get: GetBillboards(_StubBillboards(answer)));
    await cubit.load();

    return cubit;
  }

  Widget host(BillboardCubit cubit, {bool reduceMotion = false}) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (context, state) => Scaffold(
            body: ListView(children: const [BillboardCarousel()]),
          ),
        ),
        GoRoute(
          path: Routes.products,
          builder: (context, state) => const Scaffold(body: Text('الكتالوج')),
        ),
        GoRoute(
          path: Routes.bagPreview,
          builder: (context, state) => const Scaffold(body: Text('المعاينة')),
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => BlocProvider<BillboardCubit>.value(
        value: cubit,
        child: MaterialApp.router(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
        ),
      ),
    );
  }

  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(430, 932);
    view.devicePixelRatio = 1;
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('with no campaign running, the app\'s own ads fill the carousel', (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();
    final cubit = await cubitAnswering(const Right(<Billboard>[]));

    // Act
    await tester.pumpWidget(host(cubit));
    await tester.pump();

    // Assert
    expect(find.image(AssetImage(HouseAd.printedBags.asset)), findsWidgets);
    expect(find.bySemanticsLabel(HouseAd.printedBags.title), findsWidgets);
    expect(find.bySemanticsLabel('إعلان 1 من 3'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('a carousel that did not load shows the same ads, not an error', (tester) async {
    // Arrange
    final cubit = await cubitAnswering(const Left(NetworkFailure(message: 'لا يوجد اتصال')));

    // Act
    await tester.pumpWidget(host(cubit));
    await tester.pump();

    // Assert
    expect(find.image(AssetImage(HouseAd.printedBags.asset)), findsWidgets);
    expect(find.text('لا يوجد اتصال'), findsNothing);
  });

  /// الرئيسية لا تقفز حين يصل الجواب: مكان الشريط محجوزٌ بمقاسه من أول إطار.
  testWidgets('while the answer is on its way, the carousel already holds its height', (
    tester,
  ) async {
    // Arrange
    final loading = BillboardCubit(get: GetBillboards(_StubBillboards(const Right([]))));
    await tester.pumpWidget(host(loading));
    await tester.pump();
    final heightWhileLoading = tester.getSize(find.byType(BillboardCarousel)).height;
    final imagesWhileLoading = find.image(AssetImage(HouseAd.printedBags.asset)).evaluate().length;

    // Act
    await loading.load();
    await tester.pump();

    // Assert
    expect(imagesWhileLoading, 0);
    expect(tester.getSize(find.byType(BillboardCarousel)).height, heightWhileLoading);
  });

  testWidgets('it turns to the next ad by itself', (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();
    final cubit = await cubitAnswering(const Right(<Billboard>[]));
    await tester.pumpWidget(host(cubit));
    await tester.pump();

    // Act
    await turnOnce(tester);

    // Assert
    expect(find.bySemanticsLabel('إعلان 2 من 3'), findsOneWidget);

    semantics.dispose();
  });

  /// «تقليل الحركة» إعداد إمكانية وصول لا ذوق (RULES §7): الشريط يقف، ويُقلَّب بالإصبع فقط.
  testWidgets('it stands still for someone who turned motion off', (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();
    final cubit = await cubitAnswering(const Right(<Billboard>[]));
    await tester.pumpWidget(host(cubit, reduceMotion: true));
    await tester.pump();

    // Act
    await turnOnce(tester);
    await turnOnce(tester);

    // Assert
    expect(find.bySemanticsLabel('إعلان 1 من 3'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('tapping the printed-bags ad opens the catalogue', (tester) async {
    // Arrange
    final cubit = await cubitAnswering(const Right(<Billboard>[]));
    await tester.pumpWidget(host(cubit, reduceMotion: true));
    await tester.pump();

    // Act
    await tester.tap(find.byType(BillboardCarousel));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('الكتالوج'), findsOneWidget);
  });

  testWidgets('tapping the preview ad opens the bag-preview tool, with a way back', (
    tester,
  ) async {
    // Arrange — the third ad, reached the way a customer would: by letting it turn twice.
    final cubit = await cubitAnswering(const Right(<Billboard>[]));
    await tester.pumpWidget(host(cubit));
    await tester.pump();
    await turnOnce(tester);
    await turnOnce(tester);

    // Act
    await tester.tap(find.byType(BillboardCarousel));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('المعاينة'), findsOneWidget);
    expect(GoRouter.of(tester.element(find.text('المعاينة'))).canPop(), isTrue);
  });
}
