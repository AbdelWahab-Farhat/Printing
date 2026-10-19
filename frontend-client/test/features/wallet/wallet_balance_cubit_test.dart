import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/wallet/presentation/viewmodel/wallet_balance_cubit.dart';
import 'package:dayaa_client/features/wallet/repositories/wallet_repository.dart';
import 'package:dayaa_client/features/wallet/usecases/wallet_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockWalletRepository extends Mock implements WalletRepository {}

/// رصيد «محفظتي» الذي تقرؤه الحبّة في الشريط العلوي.
///
/// **ثلاثة أشياء يثبتها هذا الملف:** أن سؤالاً فشل لا يمحو رصيداً معروفاً، وأن جواباً عرفته شاشةٌ
/// يصل إلى الحبّة بلا سؤالٍ ثانٍ، وأن دخولاً جديداً يبدأ من لا شيء — فلا يُرى رصيد من خرج على
/// حساب من دخل.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockWalletRepository repository;

  WalletBalanceCubit build() => WalletBalanceCubit(getBalance: GetWalletBalance(repository));

  void stub(String balance) =>
      when(() => repository.balance()).thenAnswer((_) async => Right(balance));

  setUp(() => repository = _MockWalletRepository());

  blocTest<WalletBalanceCubit, String?>(
    'holds what the server said',
    setUp: () => stub('200.00'),
    build: build,
    act: (cubit) => cubit.refresh(),
    expect: () => ['200.00'],
  );

  blocTest<WalletBalanceCubit, String?>(
    'a failed refresh keeps the last balance rather than blanking it',
    setUp: () => stub('200.00'),
    build: build,
    act: (cubit) async {
      await cubit.refresh();
      when(() => repository.balance()).thenAnswer(
        (_) async => const Left(Failure.network(message: FailureMessages.noConnection)),
      );

      await cubit.refresh();
    },
    // Assert — حالةٌ واحدة: الفشل لا يُصدر شيئاً.
    expect: () => ['200.00'],
  );

  blocTest<WalletBalanceCubit, String?>(
    'a balance a screen already knows reaches the chip without asking the server',
    build: build,
    act: (cubit) => cubit.patch('80.00'),
    expect: () => ['80.00'],
    verify: (_) => verifyNever(() => repository.balance()),
  );

  blocTest<WalletBalanceCubit, String?>(
    'a new session starts blank, so one account never shows another its balance',
    setUp: () => stub('35.00'),
    build: build,
    seed: () => '200.00',
    act: (cubit) => cubit.load(),
    expect: () => [null, '35.00'],
  );
}
