import 'package:dartz/dartz.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/investors/models/investor_deal.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/deals_cubit.dart';
import 'package:dayaa/features/investors/repositories/investor_repository.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Two things about an investor's money that a screen cannot be trusted to get right on its own.
///
/// Arrange - Act - Assert throughout.
class _MockRepository extends Mock implements InvestorRepository {}

void main() {
  late _MockRepository repository;

  InvestorDeal dealWith({required int id, required String status}) => InvestorDeal(
    id: id,
    code: 'D$id',
    status: status,
    statusLabel: status == 'draft' ? 'مسودة' : 'مفتوحة',
    investorProfitSharePercent: '50.0000',
  );

  Paginated<InvestorDeal> page(List<InvestorDeal> items) => Paginated(
    items: items,
    meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: items.length),
  );

  setUp(() {
    repository = _MockRepository();

    when(
      () => repository.recordWalletEntry(
        investorId: any(named: 'investorId'),
        type: any(named: 'type'),
        amount: any(named: 'amount'),
        investorDealId: any(named: 'investorDealId'),
        method: any(named: 'method'),
        reference: any(named: 'reference'),
        notes: any(named: 'notes'),
      ),
    ).thenAnswer((_) async => const Right(unit));
  });

  group('recording a movement', () {
    test('an amount typed on an Arabic keyboard reaches the API as digits it can read', () async {
      // Arrange — ٢٥٠٠٫٥٠ is what the keyboard under a Libyan thumb produces. Sent as typed, the
      // server's `numeric` rule refuses it and the person is told «المبلغ يجب أن يكون رقماً»
      // about a number they can see on the screen.
      final record = RecordWalletEntry(repository);

      // Act
      await record(investorId: 1, type: 'deposit', amount: ' ٢٥٠٠٫٥٠ ', method: 'cash');

      // Assert
      verify(
        () => repository.recordWalletEntry(
          investorId: 1,
          type: 'deposit',
          amount: '2500.50',
          investorDealId: null,
          method: 'cash',
          reference: null,
          notes: null,
        ),
      ).called(1);
    });

    test('a western amount is passed through untouched, decimals and all', () async {
      // Arrange — never parsed to a double: a decimal round-tripped through binary floating
      // point is how 50.05 becomes 50.049999999999997.
      final record = RecordWalletEntry(repository);

      // Act
      await record(investorId: 1, type: 'withdrawal', amount: '50.05', method: 'cash');

      // Assert
      verify(
        () => repository.recordWalletEntry(
          investorId: 1,
          type: 'withdrawal',
          amount: '50.05',
          investorDealId: null,
          method: 'cash',
          reference: null,
          notes: null,
        ),
      ).called(1);
    });
  });

  group('a filtered deals list', () {
    Future<DealsCubit> loadedOn(String? status, List<InvestorDeal> items) async {
      when(
        () => repository.deals(
          search: any(named: 'search'),
          status: any(named: 'status'),
          investorId: any(named: 'investorId'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => Right(page(items)));

      final cubit = DealsCubit(getDeals: GetInvestorDeals(repository))..filter(status: status);
      await Future<void>.delayed(Duration.zero);

      return cubit;
    }

    test('does not take a draft the filter excludes', () async {
      // Arrange — «مفتوحة» is selected, and a deal is born a draft.
      final cubit = await loadedOn('open', [dealWith(id: 1, status: 'open')]);

      // Act
      final moved = cubit.insert(dealWith(id: 2, status: 'draft'));

      // Assert — the row would have sat there until the next read and then vanished with nothing
      // to explain it, and the filter would have been a lie in the meantime.
      expect(moved, isFalse);
      expect((cubit.state as PagedLoaded<InvestorDeal>).page.items, hasLength(1));

      await cubit.close();
    });

    test('takes one the filter asked for', () async {
      // Arrange
      final cubit = await loadedOn('open', [dealWith(id: 1, status: 'open')]);

      // Act
      final moved = cubit.insert(dealWith(id: 2, status: 'open'));

      // Assert
      expect(moved, isTrue);
      expect((cubit.state as PagedLoaded<InvestorDeal>).page.items.first.id, 2);

      await cubit.close();
    });

    test('an unfiltered list takes anything, which is what «الكل» means', () async {
      // Arrange
      final cubit = await loadedOn(null, [dealWith(id: 1, status: 'open')]);

      // Act
      final moved = cubit.insert(dealWith(id: 2, status: 'draft'));

      // Assert
      expect(moved, isTrue);

      await cubit.close();
    });
  });
}
