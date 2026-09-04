import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investor_portal/models/investor_portfolio.dart';
import 'package:dayaa/features/investor_portal/presentation/viewmodel/investor_portal_cubit.dart';
import 'package:dayaa/features/investor_portal/presentation/widgets/investor_deal_card.dart';
import 'package:dayaa/features/investor_portal/presentation/widgets/investor_money_tile.dart';
import 'package:dayaa/features/investor_portal/repositories/investor_portal_repository.dart';
import 'package:dayaa/features/investor_portal/usecases/get_investor_portfolio.dart';
import 'package:flutter/material.dart';
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
    name: 'أكياس شحن أبيض',
    status: 'open',
    statusLabel: 'مفتوحة',
    sharePercent: '60.0000',
    capital: '30000.00',
    profit: '1500.00',
  );

  const portfolio = InvestorPortfolio(
    investor: InvestorIdentity(id: 1, code: 'I1', name: 'أحمد'),
    capitalInWallet: '20000.00',
    capitalInDeals: '30000.00',
    capitalTotal: '50000.00',
    profitInDeals: '1500.00',
    profitAvailable: '0.00',
    profitWithdrawn: '0.00',
    deals: [dealLine],
  );

  setUp(() {
    repository = _MockRepository();
    cubit = InvestorPortalCubit(getPortfolio: GetInvestorPortfolio(repository));
  });

  tearDown(() => cubit.close());

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
      expect((cubit.state as InvestorPortalLoaded).portfolio.capitalInDeals, '30000.00');
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
      expect((cubit.state as InvestorPortalLoaded).portfolio.profitInDeals, '1500.00');
    });
  });

  group('the screen', () {
    Widget host(Widget child) => MaterialApp(
      locale: const Locale('ar'),
      home: Directionality(textDirection: TextDirection.rtl, child: child),
    );

    testWidgets('earned profit and withdrawable profit are two different figures', (tester) async {
      // Arrange — 1,500 earned on a deal that is still open, and nothing released.
      await tester.pumpWidget(
        host(
          const Scaffold(
            body: Column(
              children: [
                InvestorMoneyTile(
                  label: 'أرباحي حتى الآن',
                  amount: '1500.00',
                  caption: 'من صفقات ما زالت مفتوحة — تُصرف عند إقفالها',
                ),
                InvestorMoneyTile(label: 'أرباح متاحة للسحب', amount: '0.00'),
              ],
            ),
          ),
        ),
      );

      // Assert — both are shown, and the first says in words why it is not the second. One
      // number for both would either promise him money he cannot have yet or hide money he has
      // already made.
      expect(find.text('1,500.00 د.ل'), findsOneWidget);
      expect(find.text('0.00 د.ل'), findsOneWidget);
      expect(find.textContaining('تُصرف عند إقفالها'), findsOneWidget);
    });

    testWidgets('a deal card shows his stake and his share, and no quantities', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(const Scaffold(body: InvestorDealCard(deal: dealLine))),
      );

      // Assert — what he financed, what it earned him, and the percentage it was split by.
      // Nothing about how many bags there are or what they cost a piece.
      expect(find.text('أكياس شحن أبيض'), findsOneWidget);
      expect(find.textContaining('حصتي 60%'), findsOneWidget);
      expect(find.text('30,000.00 د.ل'), findsOneWidget);
      expect(find.text('1,500.00 د.ل'), findsOneWidget);
      expect(find.text('مفتوحة'), findsOneWidget);
    });

    testWidgets('a loss is named a loss rather than shown as a red profit', (tester) async {
      // Arrange
      const losing = InvestorDealLine(
        id: 26,
        code: 'D26',
        name: 'صفقة خاسرة',
        status: 'closed',
        statusLabel: 'مغلقة',
        sharePercent: '100.0000',
        capital: '0.00',
        profit: '-6500.00',
      );

      // Act
      await tester.pumpWidget(host(const Scaffold(body: InvestorDealCard(deal: losing))));

      // Assert — a colour is not a word, and somebody reading this needs to know which it is.
      expect(find.text('خسارتي'), findsOneWidget);
      expect(find.text('ربحي'), findsNothing);
    });
  });
}
