import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/treasury_settings_cubit.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'treasury_fixtures.dart';

/// «إعدادات المالية» — ما يبقى على الشاشة حين تفشل القراءة، وما تُعيده الصفحة حين تُغلق.
/// TREASURY-DESIGN §١٦.
///
/// Arrange - Act - Assert throughout.
void main() {
  late MockTreasuryRepository repository;

  const offline = Failure.network(message: FailureMessages.noConnection);

  const settings = TreasurySettings(
    ownAccountFirst: true,
    blockOverdraft: true,
    withdrawalNeedsReason: true,
    askCarrierFee: true,
  );

  const rent = ExpenseCategory(
    id: 3,
    name: 'إيجار',
    requiresEmployee: false,
    isActive: true,
    isSystem: false,
  );

  const loaded = TreasurySettingsLoaded(
    settings: settings,
    accounts: [cashBox, bank, nawris],
    categories: [rent],
  );

  TreasurySettingsCubit build() => TreasurySettingsCubit(
    getSettings: GetTreasurySettings(repository),
    saveSettings: SaveTreasurySettings(repository),
    getAccounts: GetTreasuryAccounts(repository),
    saveAccount: SaveTreasuryAccount(repository),
    setSettlesInto: SetSettlesInto(repository),
    getCategories: GetExpenseCategories(repository),
    saveCategory: SaveExpenseCategory(repository),
  );

  void answerReads({Either<Failure, TreasurySettings> read = const Right(settings)}) {
    when(() => repository.settings()).thenAnswer((_) async => read);
    when(() => repository.accounts()).thenAnswer((_) async => const Right(everyAccount));
    when(
      () => repository.expenseCategories(activeOnly: false),
    ).thenAnswer((_) async => const Right([rent]));
  }

  setUp(() {
    repository = MockTreasuryRepository();
  });

  blocTest<TreasurySettingsCubit, TreasurySettingsState>(
    'يقرأ الإعدادات والحسابات والتصنيفات معاً',
    // Arrange
    setUp: answerReads,
    build: build,
    // Act
    act: (cubit) => cubit.load(),
    // Assert
    expect: () => [
      isA<TreasurySettingsLoaded>()
          .having((s) => s.settings, 'settings', settings)
          .having((s) => s.accounts, 'accounts', everyAccount.accounts)
          .having((s) => s.categories, 'categories', [rent])
          .having((s) => s.refreshFailure, 'refreshFailure', isNull),
    ],
  );

  blocTest<TreasurySettingsCubit, TreasurySettingsState>(
    'فشلُ أول تحميلٍ يُظهر الخطأ',
    // Arrange
    setUp: () => answerReads(read: const Left(offline)),
    build: build,
    // Act
    act: (cubit) => cubit.load(),
    // Assert
    expect: () => [isA<TreasurySettingsFailed>().having((s) => s.failure, 'failure', offline)],
  );

  blocTest<TreasurySettingsCubit, TreasurySettingsState>(
    'إعادةُ قراءةٍ فشلت تُبقي الصفحة على ما كانت وتحمل الفشل للتوست',
    // Arrange
    setUp: () => answerReads(read: const Left(offline)),
    build: build,
    seed: () => loaded,
    // Act
    act: (cubit) => cubit.load(),
    // Assert
    expect: () => [
      isA<TreasurySettingsLoaded>()
          .having((s) => s.settings, 'settings', settings)
          .having((s) => s.accounts, 'accounts', loaded.accounts)
          .having((s) => s.refreshFailure, 'refreshFailure', offline),
    ],
  );

  blocTest<TreasurySettingsCubit, TreasurySettingsState>(
    'حفظٌ نجح يُعلَّم، فتقرأ اللوحة حساباتها حين تُغلق الصفحة',
    // Arrange
    setUp: () {
      answerReads();
      when(
        () => repository.saveSettings(blockOverdraft: false),
      ).thenAnswer((_) async => const Right(settings));
    },
    build: build,
    seed: () => loaded,
    // Act
    act: (cubit) => cubit.saveSettings(blockOverdraft: false),
    // Assert
    verify: (cubit) => expect(cubit.changed, isTrue),
  );

  Failure? refused;

  blocTest<TreasurySettingsCubit, TreasurySettingsState>(
    'حفظٌ رُفض يعود برفضه، ولا شيء تغيّر',
    // Arrange
    setUp: () => when(
      () => repository.saveSettings(blockOverdraft: false),
    ).thenAnswer((_) async => const Left(Failure.server(message: 'لا تملك الصلاحية'))),
    build: build,
    seed: () => loaded,
    // Act
    act: (cubit) async {
      refused = await cubit.saveSettings(blockOverdraft: false);
    },
    // Assert
    expect: () => <TreasurySettingsState>[],
    verify: (cubit) {
      expect(refused?.message, 'لا تملك الصلاحية');
      expect(cubit.changed, isFalse);
    },
  );
}
