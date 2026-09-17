import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/badges/models/customer_badge.dart';
import 'package:dayaa_client/features/badges/presentation/viewmodel/badges_cubit.dart';
import 'package:dayaa_client/features/badges/repositories/badge_repository.dart';
import 'package:dayaa_client/features/badges/usecases/get_badges.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// What the badge holds on to, and what it refuses to throw away.
///
/// **The property this file exists for is the failed refresh.** A badge is fetched on launch, on
/// resume and on a pull — every one of those happens on a connection that drops. Clearing the
/// count because a request failed would tell the customer their unread replies had been dealt
/// with, which is the one thing a badge must never say: it is the only signal that the shop has
/// answered at all.
///
/// Arrange - Act - Assert throughout.
class _MockBadgeRepository extends Mock implements BadgeRepository {}

void main() {
  late _MockBadgeRepository repository;

  BadgesCubit build() => BadgesCubit(getBadges: GetBadges(repository));

  void stub(Map<CustomerBadge, int> counts) {
    when(() => repository.badges()).thenAnswer((_) async => Right(counts));
  }

  setUp(() => repository = _MockBadgeRepository());

  group('fetching', () {
    blocTest<BadgesCubit, Map<CustomerBadge, int>>(
      'holds what the server sent',
      setUp: () => stub({CustomerBadge.support: 3}),
      build: build,
      act: (cubit) => cubit.refresh(),
      expect: () => [
        {CustomerBadge.support: 3},
      ],
    );

    blocTest<BadgesCubit, Map<CustomerBadge, int>>(
      'a zero arrives as a state, because it has to clear the tile',
      setUp: () => stub({CustomerBadge.support: 0}),
      build: build,
      act: (cubit) async {
        await cubit.refresh();
        stub({CustomerBadge.support: 0});
      },
      // Assert — the count dropping to nothing is news. An endpoint that omitted empty badges,
      // or a cubit that ignored them, would leave the last number on the tile forever.
      expect: () => [
        {CustomerBadge.support: 0},
      ],
    );
  });

  group('when the request fails', () {
    blocTest<BadgesCubit, Map<CustomerBadge, int>>(
      'keeps the last known counts rather than clearing them',
      setUp: () => stub({CustomerBadge.support: 2}),
      build: build,
      act: (cubit) async {
        await cubit.refresh();

        when(() => repository.badges()).thenAnswer(
          (_) async => const Left(Failure.network(message: 'لا يوجد اتصال')),
        );

        await cubit.refresh();
      },
      // Assert — **one state, not two.** The failed second fetch emits nothing at all, so the
      // tile keeps its 2. Blanking it would say «قرأتَ كل شيء» on the strength of a dropped
      // connection.
      verify: (cubit) => expect(cubit.state, {CustomerBadge.support: 2}),
      expect: () => [
        {CustomerBadge.support: 2},
      ],
    );

    blocTest<BadgesCubit, Map<CustomerBadge, int>>(
      'a first fetch that fails simply draws no badge',
      setUp: () {
        when(() => repository.badges()).thenAnswer(
          (_) async => const Left(Failure.network(message: 'لا يوجد اتصال')),
        );
      },
      build: build,
      act: (cubit) => cubit.refresh(),
      // Assert — nothing is emitted and nothing is reported. A badge is decoration on a screen
      // that is already useful; an error where a number goes would be worse than no number.
      expect: () => <Map<CustomerBadge, int>>[],
    );
  });

  group('clearing one by hand', () {
    blocTest<BadgesCubit, Map<CustomerBadge, int>>(
      'takes it to zero without asking the server',
      setUp: () => stub({CustomerBadge.support: 4}),
      build: build,
      act: (cubit) async {
        await cubit.refresh();
        clearInteractions(repository);

        // Act — the thread screen has just been opened, which marks it read server-side.
        cubit.clear(CustomerBadge.support);
      },
      verify: (cubit) {
        // Assert — no round trip to learn something the app itself caused.
        verifyNever(() => repository.badges());

        expect(cubit.state[CustomerBadge.support], 0);
      },
      expect: () => [
        {CustomerBadge.support: 4},
        {CustomerBadge.support: 0},
      ],
    );

    blocTest<BadgesCubit, Map<CustomerBadge, int>>(
      'clearing one that is already empty emits nothing',
      setUp: () => stub({CustomerBadge.support: 0}),
      build: build,
      act: (cubit) async {
        await cubit.refresh();
        cubit.clear(CustomerBadge.support);
      },
      // Assert — opening a thread with nothing unread in it must not repaint every badged tile
      // in the app for a change that did not happen.
      expect: () => [
        {CustomerBadge.support: 0},
      ],
    );
  });
}
