import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// The five behaviours every list screen inherits, tested once here rather than re-tested in
/// each feature: the debounce, the out-of-order guard, appending pages, surviving a failed extra
/// page, and refreshing the current term.
///
/// Arrange - Act - Assert throughout.
///
/// The subject is a fake subclass rather than a real feature's Cubit, so a change to products or
/// customers can never make these pass or fail for the wrong reason.
class _TestCubit extends PagedCubit<String> {
  _TestCubit(this.responses);

  /// Page number → what the "server" answers with. A function, so a test can change the answer
  /// between calls.
  final Either<Failure, Paginated<String>> Function(int page, String? search) responses;

  final List<({int page, String? search})> requests = [];

  /// When on, every request hangs until the test completes its gate — which is what lets two
  /// be in flight at once, and finish in the wrong order on purpose.
  bool holdRequests = false;
  final List<Completer<void>> gates = [];

  @override
  Future<Either<Failure, Paginated<String>>> fetchPage({
    String? search,
    required int page,
  }) async {
    requests.add((page: page, search: search));

    if (holdRequests) {
      final gate = Completer<void>();
      gates.add(gate);
      await gate.future;
    }

    return responses(page, search);
  }
}

Paginated<String> pageOf(
  List<String> items, {
  int current = 1,
  int last = 1,
}) => Paginated<String>(
  items: items,
  meta: PageMeta(currentPage: current, perPage: 20, lastPage: last, total: items.length),
);

void main() {
  group('load', () {
    blocTest<_TestCubit, PagedState<String>>(
      'goes loading then loaded',
      build: () => _TestCubit((page, search) => right(pageOf(['أ']))),
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => [
        const PagedState<String>.loading(),
        PagedState<String>.loaded(page: pageOf(['أ'])),
      ],
    );

    blocTest<_TestCubit, PagedState<String>>(
      'carries the failure through untouched',
      build: () => _TestCubit(
        (page, search) => left(const Failure.server(message: 'رسالة الخادم')),
      ),
      // Act
      act: (cubit) => cubit.load(),
      // Assert — the server's own words, not a generic apology.
      expect: () => const [
        PagedState<String>.loading(),
        PagedState<String>.failure(Failure.server(message: 'رسالة الخادم')),
      ],
    );
  });

  group('search', () {
    blocTest<_TestCubit, PagedState<String>>(
      'four keystrokes make one request, for the last term',
      build: () => _TestCubit((page, search) => right(pageOf(['نتيجة']))),
      // Act
      act: (cubit) => cubit
        ..search('أ')
        ..search('أك')
        ..search('أكي')
        ..search('أكياس'),
      wait: const Duration(milliseconds: 500),
      // Assert
      verify: (cubit) {
        expect(cubit.requests, hasLength(1));
        expect(cubit.requests.single.search, 'أكياس');
      },
    );

    blocTest<_TestCubit, PagedState<String>>(
      'an emptied box asks for everything, not for an empty string',
      build: () => _TestCubit((page, search) => right(pageOf(['نتيجة']))),
      // Act
      act: (cubit) => cubit.search('   '),
      wait: const Duration(milliseconds: 500),
      // Assert — `''` would filter on an empty string server-side.
      verify: (cubit) => expect(cubit.requests.single.search, isNull),
    );

    test('a slow answer for an old term never overwrites a newer one', () async {
      // Arrange — two requests in flight, finishing in the opposite order to the one they
      // started in. This is the bug the request counter exists to prevent.
      final cubit = _TestCubit((page, search) => right(pageOf(['نتيجة $search'])))
        ..holdRequests = true;

      // Act
      final slow = cubit.load(search: 'أك');
      await Future<void>.delayed(Duration.zero);
      final fast = cubit.load(search: 'أكياس');
      await Future<void>.delayed(Duration.zero);

      cubit.gates[1].complete(); // the newer term answers first…
      await fast;
      cubit.gates[0].complete(); // …and the older one lands afterwards.
      await slow;

      // Assert
      expect(
        (cubit.state as PagedLoaded<String>).search,
        'أكياس',
        reason: 'a reply to a question nobody is asking any more must be dropped',
      );

      await cubit.close();
    });
  });

  group('loadMore', () {
    blocTest<_TestCubit, PagedState<String>>(
      'appends the next page and keeps what is on screen',
      build: () => _TestCubit(
        (page, search) => right(
          page == 1 ? pageOf(['الأول'], last: 2) : pageOf(['الثاني'], current: 2, last: 2),
        ),
      ),
      // Act
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
      },
      // Assert
      expect: () => [
        const PagedState<String>.loading(),
        isA<PagedLoaded<String>>().having((s) => s.page.items, 'first page', ['الأول']),
        isA<PagedLoaded<String>>().having((s) => s.isLoadingMore, 'loading more', isTrue),
        isA<PagedLoaded<String>>()
            .having((s) => s.page.items, 'both pages', ['الأول', 'الثاني'])
            .having((s) => s.isLoadingMore, 'loading more', isFalse),
      ],
    );

    blocTest<_TestCubit, PagedState<String>>(
      'a failed extra page leaves the list exactly as it was',
      build: () => _TestCubit(
        (page, search) => page == 1
            ? right(pageOf(['الأول'], last: 2))
            : left(const Failure.network(message: 'لا يوجد اتصال')),
      ),
      // Act
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
      },
      // Assert — losing a working list to a failed page four is the worse answer.
      expect: () => [
        const PagedState<String>.loading(),
        isA<PagedLoaded<String>>().having((s) => s.page.items, 'first page', ['الأول']),
        isA<PagedLoaded<String>>().having((s) => s.isLoadingMore, 'loading more', isTrue),
        isA<PagedLoaded<String>>()
            .having((s) => s.page.items, 'still there', ['الأول'])
            .having((s) => s.isLoadingMore, 'loading more', isFalse),
      ],
    );

    blocTest<_TestCubit, PagedState<String>>(
      'asks for nothing once the last page has been reached',
      build: () => _TestCubit((page, search) => right(pageOf(['الوحيد']))),
      // Act — an infinite list fires this on every scroll frame.
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
        await cubit.loadMore();
        await cubit.loadMore();
      },
      // Assert
      verify: (cubit) => expect(cubit.requests, hasLength(1)),
    );

    blocTest<_TestCubit, PagedState<String>>(
      'does nothing at all before the first load',
      build: () => _TestCubit((page, search) => right(pageOf(['أ']))),
      // Act
      act: (cubit) => cubit.loadMore(),
      // Assert
      expect: () => const <PagedState<String>>[],
      verify: (cubit) => expect(cubit.requests, isEmpty),
    );
  });

  blocTest<_TestCubit, PagedState<String>>(
    'refresh re-runs the current term, not a blank one',
    build: () => _TestCubit((page, search) => right(pageOf(['نتيجة']))),
    // Act
    act: (cubit) async {
      await cubit.load(search: 'أكياس');
      await cubit.refresh();
    },
    // Assert
    verify: (cubit) {
      expect(cubit.requests.map((request) => request.search), ['أكياس', 'أكياس']);
      expect(cubit.currentSearch, 'أكياس');
    },
  );
}
