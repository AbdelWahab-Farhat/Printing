import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investor_portal/models/investor_portfolio.dart';
import 'package:dayaa/features/investor_portal/presentation/viewmodel/investor_portal_cubit.dart';
import 'package:dayaa/features/investor_portal/presentation/views/investor_portal_page.dart';
import 'package:dayaa/features/investor_portal/presentation/widgets/investor_deal_card.dart';
import 'package:dayaa/features/investor_portal/repositories/investor_portal_repository.dart';
import 'package:dayaa/features/investor_portal/usecases/get_investor_portfolio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// The investor's screen, and the one distinction it must never blur.
///
/// Arrange - Act - Assert throughout.
class _MockRepository extends Mock implements InvestorPortalRepository {}

void main() {
  late _MockRepository repository;
  late InvestorPortalCubit cubit;

  const dealLine = InvestorDealLine(
    id: 25,
    code: 'D25',
    status: 'open',
    statusLabel: 'مفتوحة',
    sharePercent: '60.0000',
    capital: '30000',
    profit: '1500',
  );

  const portfolio = InvestorPortfolio(
    investor: InvestorIdentity(id: 1, code: 'I1', name: 'أحمد'),
    capitalInWallet: '20000',
    capitalInDeals: '30000',
    capitalTotal: '50000',
    profitInDeals: '1500',
    profitAvailable: '0',
    profitWithdrawn: '0',
    deals: [dealLine],
  );

  setUp(() {
    repository = _MockRepository();
    cubit = InvestorPortalCubit(getPortfolio: GetInvestorPortfolio(repository));
  });

  tearDown(() async {
    await cubit.close();
    await Injector.reset();
  });

  void arrange(Either<Failure, InvestorPortfolio> result) {
    when(() => repository.portfolio()).thenAnswer((_) async => result);
  }

  group('the cubit', () {
    test('loads the portfolio', () async {
      // Arrange
      arrange(const Right(portfolio));

      // Act
      await cubit.load();

      // Assert
      expect(cubit.state, isA<InvestorPortalLoaded>());
      expect((cubit.state as InvestorPortalLoaded).portfolio.capitalInDeals, '30000');
    });

    test('a failed refresh keeps the figures already on screen', () async {
      // Arrange — a good load, then a server that stops answering.
      arrange(const Right(portfolio));
      await cubit.load();
      arrange(const Left(ServerFailure(message: 'انقطع الاتصال')));

      // Act
      await cubit.refresh();

      // Assert — throwing away figures somebody is reading because a refresh timed out is the
      // worst of the available answers.
      expect(cubit.state, isA<InvestorPortalLoaded>());
      expect((cubit.state as InvestorPortalLoaded).portfolio.profitInDeals, '1500');
    });
  });

  group('the screen', () {
    // The same design size the app itself is initialised at. Without it every `.w`/`.h` in a
    // widget under test throws a `LateInitializationError` rather than laying out.
    Widget host(Widget child) => ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp(
        locale: const Locale('ar'),
        home: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    );

    testWidgets('earned profit and withdrawable profit are two different figures', (tester) async {
      // Arrange — the whole screen, driven by the portfolio the server sent: 1,500 earned on a
      // deal that is still open, and nothing released. Built from the *portfolio* rather than
      // from two tiles handed the strings this test then looks for — that version passed by
      // asserting its own literals back, and would have gone on passing with the distinction it
      // is named after deleted.
      arrange(const Right(portfolio));

      // The screen builds its own Cubit out of the container, so the container is what the stub
      // repository is handed to.
      await Injector.reset();
      sl.registerFactory<InvestorPortalCubit>(
        () => InvestorPortalCubit(getPortfolio: GetInvestorPortfolio(repository)),
      );

      // Act
      await tester.pumpWidget(host(const InvestorPortalPage()));
      await tester.pumpAndSettle();

      // Assert — both figures are on the screen under their own headings, and the first says in
      // words why it is not the second. One number for both would either promise him money he
      // cannot have yet or hide money he has already made.
      expect(find.text('أرباحي حتى الآن'), findsOneWidget);
      expect(find.text('1,500 د.ل'), findsOneWidget);
      expect(find.text('أرباح متاحة للسحب'), findsOneWidget);
      expect(find.textContaining('تُصرف عند إقفالها'), findsOneWidget);
      // 0.00 twice: what is released and what has been withdrawn are both still nothing.
      expect(find.text('0 د.ل'), findsNWidgets(2));
    });

    testWidgets('a deal card shows his stake and his share, and no quantities', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(const Scaffold(body: InvestorDealCard(deal: dealLine))),
      );

      // Assert — what he financed, what it earned him, and the percentage it was split by.
      // Nothing about how many bags there are or what they cost a piece.
      expect(find.text('D25'), findsOneWidget);
      expect(find.textContaining('حصتي 60%'), findsOneWidget);
      expect(find.text('30,000 د.ل'), findsOneWidget);
      expect(find.text('1,500 د.ل'), findsOneWidget);
      expect(find.text('مفتوحة'), findsOneWidget);
    });

    testWidgets('a loss is named a loss rather than shown as a red profit', (tester) async {
      // Arrange
      const losing = InvestorDealLine(
        id: 26,
        code: 'D26',
        status: 'closed',
        statusLabel: 'مغلقة',
        sharePercent: '100.0000',
        capital: '0',
        profit: '-6500.00',
      );

      // Act
      await tester.pumpWidget(host(const Scaffold(body: InvestorDealCard(deal: losing))));

      // Assert — a colour is not a word, and somebody reading this needs to know which it is.
      expect(find.text('خسارتي'), findsOneWidget);
      expect(find.text('ربحي'), findsNothing);
      // And the word carries the sign on its own: «خسارتي -6,500» says it twice, which reads as
      // a negative loss.
      expect(find.text('6,500 د.ل'), findsOneWidget);
      expect(find.text('-6,500 د.ل'), findsNothing);
    });
  });
}
