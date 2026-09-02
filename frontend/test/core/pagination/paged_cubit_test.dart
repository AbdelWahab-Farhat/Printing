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

  @override
  Object identityOf(String item) => item;

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

/// A row with an identity of its own, which is what patching needs: a `String`'s identity *is*
/// its content, so replacing one could never be told apart from removing it and adding another.
typedef _Row = ({int id, String label});

/// The same fake, over rows that can change without becoming a different row.
class _RowCubit extends PagedCubit<_Row> {
  _RowCubit(this.page);

  final Paginated<_Row> page;

  /// What the screen is narrowed to, if anything — the filter a patched row has to still match
  /// to stay on the list. Settable, so one test can narrow what another leaves open.
  bool Function(_Row row)? filter;

  int requests = 0;

  @override
  Object identityOf(_Row item) => item.id;

  @override
  bool belongs(_Row item) => filter?.call(item) ?? true;

  @override
  Future<Either<Failure, Paginated<_Row>>> fetchPage({String? search, required int page}) async {
    requests++;

    return right(this.page);
  }
}

/// A page whose `lastPage` follows its `total`, so a test that wants a second page only has to
/// say the set is bigger than the page.
Paginated<_Row> _rowPage(List<_Row> rows, {int total = 0}) => Paginated<_Row>(
  items: rows,
  meta: PageMeta(
    currentPage: 1,
    perPage: 20,
    lastPage: (total == 0 ? rows.length : total) > rows.length ? 2 : 1,
    total: total == 0 ? rows.length : total,
  ),
  extraMeta: const {'event_counts': 3},
);

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

    test('drops a row the page on screen already shows', () async {
      // Arrange — a row inserted locally slides the server's page window down by one, so page
      // two hands back a row page one already ended with. Offset paging cannot avoid it; the
      // list can refuse to show it twice.
      final cubit = _RowCubit(_rowPage([(id: 1, label: 'أ'), (id: 2, label: 'ب')], total: 40));
      await cubit.load();
      cubit.insert((id: 9, label: 'الجديدة'));

      // Act
      await cubit.loadMore();

      // Assert
      expect(
        (cubit.state as PagedLoaded<_Row>).page.items,
        [(id: 9, label: 'الجديدة'), (id: 1, label: 'أ'), (id: 2, label: 'ب')],
      );

      await cubit.close();
    });

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

  /// Coming back from a detail screen must not cost a request.
  ///
  /// The three shapes a change takes — a row edited, a row created, a row gone — patched into
  /// the page that is already on screen, so the list keeps its scroll position and never blinks
  /// through a skeleton to show what the caller already knows.
  group('patching', () {
    test('replace swaps the row in place, with no request', () async {
      // Arrange
      final cubit = _RowCubit(_rowPage([(id: 1, label: 'أ'), (id: 2, label: 'ب')]));
      await cubit.load();
      final before = cubit.requests;

      // Act
      cubit.replace((id: 2, label: 'ب المعدلة'));

      // Assert
      expect(
        (cubit.state as PagedLoaded<_Row>).page.items,
        [(id: 1, label: 'أ'), (id: 2, label: 'ب المعدلة')],
      );
      expect(cubit.requests, before, reason: 'the caller already has the row');

      await cubit.close();
    });

    test('replace drops a row that no longer belongs to the narrowed list', () async {
      // Arrange — «أ» only, the way a status filter narrows a queue.
      final cubit = _RowCubit(_rowPage([(id: 1, label: 'أ'), (id: 2, label: 'أ')]))
        ..filter = (row) => row.label == 'أ';
      await cubit.load();

      // Act
      cubit.replace((id: 2, label: 'ب'));

      // Assert — leaving it there would make the filter a lie until the next refresh.
      expect((cubit.state as PagedLoaded<_Row>).page.items, [(id: 1, label: 'أ')]);
      expect((cubit.state as PagedLoaded<_Row>).page.meta.total, 1);

      await cubit.close();
    });

    test('replace leaves the page alone when the row is not on it', () async {
      // Arrange
      final cubit = _RowCubit(_rowPage([(id: 1, label: 'أ')]));
      await cubit.load();
      final before = cubit.state;

      // Act — a row from page four, patched while page one is showing.
      cubit.replace((id: 9, label: 'ط'));

      // Assert
      expect(cubit.state, before);

      await cubit.close();
    });

    test('insert puts a created row at the top and counts it', () async {
      // Arrange
      final cubit = _RowCubit(_rowPage([(id: 1, label: 'أ')], total: 7));
      await cubit.load();

      // Act
      cubit.insert((id: 2, label: 'الجديدة'));

      // Assert — where the user just put it, without waiting for the list to agree.
      final page = (cubit.state as PagedLoaded<_Row>).page;
      expect(page.items, [(id: 2, label: 'الجديدة'), (id: 1, label: 'أ')]);
      expect(page.meta.total, 8);

      await cubit.close();
    });

    test('insert ignores a row the narrowed list would not show', () async {
      // Arrange
      final cubit = _RowCubit(_rowPage([(id: 1, label: 'أ')]))..filter = (row) => row.label == 'أ';
      await cubit.load();

      // Act
      cubit.insert((id: 2, label: 'ب'));

      // Assert
      expect((cubit.state as PagedLoaded<_Row>).page.items, [(id: 1, label: 'أ')]);

      await cubit.close();
    });

    test('remove drops the row and the count with it', () async {
      // Arrange
      final cubit = _RowCubit(_rowPage([(id: 1, label: 'أ'), (id: 2, label: 'ب')], total: 5));
      await cubit.load();

      // Act
      cubit.removeById(2);

      // Assert
      final page = (cubit.state as PagedLoaded<_Row>).page;
      expect(page.items, [(id: 1, label: 'أ')]);
      expect(page.meta.total, 4);

      await cubit.close();
    });

    test('a patch keeps whatever else the endpoint sent in meta', () async {
      // Arrange — the history screens' `event_counts` fills the filter chips; a patched page
      // that dropped it would empty them.
      final cubit = _RowCubit(_rowPage([(id: 1, label: 'أ')]));
      await cubit.load();

      // Act
      cubit.replace((id: 1, label: 'أ المعدلة'));

      // Assert
      expect((cubit.state as PagedLoaded<_Row>).page.extraMeta, {'event_counts': 3});

      await cubit.close();
    });

    test('says whether it actually changed anything', () async {
      // Arrange — the answer a screen with counts beside its list needs: those are only stale
      // when a row really moved, and re-reading them for a patch that matched nothing is the
      // request this whole exercise is about.
      final cubit = _RowCubit(_rowPage([(id: 1, label: 'أ')]));
      await cubit.load();

      // Act + Assert
      expect(cubit.replace((id: 1, label: 'أ المعدلة')), isTrue);
      expect(cubit.replace((id: 9, label: 'ليست هنا')), isFalse);
      expect(cubit.insert((id: 2, label: 'الجديدة')), isTrue);
      expect(cubit.insert((id: 2, label: 'الجديدة')), isFalse, reason: 'already on the list');
      expect(cubit.removeById(2), isTrue);
      expect(cubit.removeById(2), isFalse);

      await cubit.close();
    });

    test('patching before the first load is a no-op, not a crash', () async {
      // Arrange
      final cubit = _RowCubit(_rowPage([]));

      // Act
      cubit
        ..replace((id: 1, label: 'أ'))
        ..insert((id: 2, label: 'ب'))
        ..removeById(3);

      // Assert
      expect(cubit.state, isA<PagedInitial<_Row>>());

      await cubit.close();
    });
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
