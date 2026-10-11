import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/pagination/paged_state.dart';
import 'package:dayaa_client/features/wallet/models/wallet_models.dart';
import 'package:dayaa_client/features/wallet/presentation/viewmodel/wallet_entries_cubit.dart';
import 'package:dayaa_client/features/wallet/repositories/wallet_repository.dart';
import 'package:dayaa_client/features/wallet/usecases/wallet_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockWalletRepository extends Mock implements WalletRepository {}

/// «محفظتي» — Docs/payments/CUSTOMER-WALLET.md: ما يُقرأ من السلك، والرصيدُ من `meta` الصفحة.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockWalletRepository repository;

  setUp(() => repository = _MockWalletRepository());

  test('a row reads its direction from the server, never a sign on the amount', () {
    // Arrange
    final json = <String, dynamic>{
      'id': 4,
      'type': 'order_payment',
      'type_label': 'دفع طلبية',
      'direction': 'out',
      'amount': '80.00',
      'order_id': 1304,
      'description': 'الطلبية 1304',
      'is_reversed': false,
      'occurred_at': '2026-10-11T10:00:00Z',
    };

    // Act
    final entry = MyWalletEntry.fromJson(json);

    // Assert
    expect(entry.isIn, isFalse);
    expect(entry.amount, '80.00');
    expect(entry.orderId, 1304);
    expect(entry.description, 'الطلبية 1304');
  });

  test('the balance comes with the page — no second request for the header', () async {
    // Arrange
    when(() => repository.entries(page: 1)).thenAnswer(
      (_) async => const Right(
        Paginated<MyWalletEntry>(
          items: [],
          meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 0),
          extraMeta: {'balance': '120.00'},
        ),
      ),
    );
    final cubit = WalletEntriesCubit(getEntries: GetWalletEntries(repository));

    // Act
    await cubit.load();

    // Assert
    expect(cubit.state, isA<PagedLoaded<MyWalletEntry>>());
    expect(cubit.balance, '120.00');
    verifyNever(() => repository.balance());

    await cubit.close();
  });

  test('a filter asks the server for that type alone', () async {
    // Arrange
    when(() => repository.entries(page: 1, filter: MyWalletFilter.topup)).thenAnswer(
      (_) async => const Left(Failure.network(message: FailureMessages.noConnection)),
    );
    final cubit = WalletEntriesCubit(getEntries: GetWalletEntries(repository));

    // Act
    await cubit.narrowTo(MyWalletFilter.topup);

    // Assert
    verify(() => repository.entries(page: 1, filter: MyWalletFilter.topup)).called(1);
    expect(cubit.balance, isNull);

    await cubit.close();
  });
}
