import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/badges/models/customer_badge.dart';
import 'package:dayaa_client/features/badges/presentation/viewmodel/badges_cubit.dart';
import 'package:dayaa_client/features/badges/presentation/views/badge_count.dart';
import 'package:dayaa_client/features/badges/repositories/badge_repository.dart';
import 'package:dayaa_client/features/badges/usecases/get_badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// A badge must not change the size of what it is pinned to.
///
/// **A regression test for a tile that visibly shrank.** «الدعم» sat in a row of three equal
/// tiles and came out narrower than its neighbours the moment it was badged: a `Stack` hands its
/// non-positioned children *loose* constraints by default, and these tiles carry no width of
/// their own — they fill what they are given. `StackFit.passthrough` is the fix, and this is
/// what stops somebody removing it.
///
/// **Measured rather than eyeballed**, because the failure is a layout one: nothing threw,
/// nothing was red, and every other test stayed green while the screen was plainly wrong.
///
/// Arrange - Act - Assert throughout.
class _StubRepository implements BadgeRepository {
  _StubRepository(this._counts);

  final Map<CustomerBadge, int> _counts;

  @override
  Future<Either<Failure, Map<CustomerBadge, int>>> badges() async => Right(_counts);
}

void main() {
  /// Three tiles in a row, the middle one badged — the shape «الرئيسية» actually draws.
  Widget host({required int count}) {
    final cubit = BadgesCubit(
      getBadges: GetBadges(_StubRepository({CustomerBadge.support: count})),
    );

    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: BlocProvider<BadgesCubit>.value(
          value: cubit..refresh(),
          child: Scaffold(
            body: Row(
              children: [
                const Expanded(child: _Tile(key: ValueKey('plain-start'))),
                SizedBox(width: 12.w),
                const Expanded(
                  child: BadgedTile(
                    badge: CustomerBadge.support,
                    child: _Tile(key: ValueKey('badged')),
                  ),
                ),
                SizedBox(width: 12.w),
                const Expanded(child: _Tile(key: ValueKey('plain-end'))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a badged tile is exactly as wide as its unbadged neighbours', (tester) async {
    // Arrange — a count high enough that the pill is genuinely drawn.
    await tester.pumpWidget(host(count: 3));
    await tester.pumpAndSettle();

    // Act
    final start = tester.getSize(find.byKey(const ValueKey('plain-start')));
    final badged = tester.getSize(find.byKey(const ValueKey('badged')));
    final end = tester.getSize(find.byKey(const ValueKey('plain-end')));

    // Assert — **width is the one that broke.** Under the default `StackFit.loose` the badged
    // tile collapsed to its intrinsic width while the other two filled their third of the row.
    expect(badged.width, start.width);
    expect(badged.width, end.width);
    expect(badged.height, start.height);
  });

  testWidgets('and is unchanged when the badge is empty', (tester) async {
    // Arrange — zero, so `BadgeCount` draws nothing at all.
    await tester.pumpWidget(host(count: 0));
    await tester.pumpAndSettle();

    // Act
    final plain = tester.getSize(find.byKey(const ValueKey('plain-start')));
    final badged = tester.getSize(find.byKey(const ValueKey('badged')));

    // Assert — the wrapper costs nothing when there is nothing to show, so a tile does not
    // shift about as counts come and go.
    expect(badged.width, plain.width);
    expect(badged.height, plain.height);
  });

  testWidgets('the pill appears only when something is waiting', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(host(count: 0));
    await tester.pumpAndSettle();

    // Assert — «٠» taking up the space of a real answer is worse than no badge.
    expect(find.text('0'), findsNothing);

    await tester.pumpWidget(host(count: 4));
    await tester.pumpAndSettle();

    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('a large count is shortened rather than stretching the pill', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(host(count: 250));
    await tester.pumpAndSettle();

    // Assert — past ninety-nine nobody reads the digits and the pill stops fitting the corner.
    expect(find.text('+٩٩'), findsOneWidget);
    expect(find.text('250'), findsNothing);
  });
}

/// Stands in for `_ServiceTile`: **carries no width of its own**, which is the property that
/// made the original bug possible. A fixed-size stub would pass under either `StackFit`.
class _Tile extends StatelessWidget {
  const _Tile({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
    color: const Color(0xFF123456),
    child: const Column(
      children: [Icon(Icons.chat), SizedBox(height: 8), Text('الدعم')],
    ),
  );
}
