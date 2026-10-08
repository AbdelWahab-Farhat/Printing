import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The infinite list, and the one case where it used to stop being infinite.
///
/// **A page that does not fill the screen can never be scrolled**, and scrolling is the only
/// thing that asks for the next page — so the list stops at the end of page one with more
/// waiting behind it. It was unreachable while every row was one API row and fifteen of them
/// were taller than a phone; grouping made it reachable, because fifteen shelves of one bag are
/// now two cards.
///
/// Arrange - Act - Assert throughout.
void main() {
  Paginated<int> page({required int items, required int lastPage}) => Paginated<int>(
    items: [for (var i = 0; i < items; i++) i],
    meta: PageMeta(currentPage: 1, perPage: 15, lastPage: lastPage, total: items * lastPage),
  );

  Widget host(Paginated<int> content, {required VoidCallback onLoadMore}) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      home: Scaffold(
        body: PagedListView<int>(
          state: PagedState<int>.loaded(page: content),
          itemBuilder: (context, item, index) => SizedBox(height: 40, child: Text('$item')),
          onLoadMore: () async => onLoadMore(),
          onRefresh: () async {},
        ),
      ),
    ),
  );

  testWidgets('a page too short to scroll asks for the next one anyway', (tester) async {
    // Arrange — two rows on a phone-sized screen: nothing to scroll, three pages to go
    var asked = 0;
    await tester.pumpWidget(host(page(items: 2, lastPage: 3), onLoadMore: () => asked++));

    // Act
    await tester.pump();

    // Assert
    expect(asked, 1);
  });

  testWidgets('the last page asks for nothing', (tester) async {
    // Arrange
    var asked = 0;
    await tester.pumpWidget(host(page(items: 2, lastPage: 1), onLoadMore: () => asked++));

    // Act
    await tester.pump();

    // Assert
    expect(asked, 0);
  });

  testWidgets('a page that fills the screen waits to be scrolled', (tester) async {
    // Arrange — taller than the viewport, so the reader's own scroll is what asks
    var asked = 0;
    await tester.pumpWidget(host(page(items: 40, lastPage: 3), onLoadMore: () => asked++));

    // Act
    await tester.pump();

    // Assert
    expect(asked, 0);
  });

  group('a header above the rows', () {
    Widget withHeader(PagedState<int> state, {Key? fieldKey}) => ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: PagedListView<int>(
            state: state,
            header: SizedBox(height: 120, child: TextField(key: fieldKey ?? const Key('filters'))),
            itemBuilder: (context, item, index) => SizedBox(height: 60, child: Text('row $item')),
            onLoadMore: () async {},
            onRefresh: () async {},
          ),
        ),
      ),
    );

    testWidgets('it is drawn while loading, when empty and when the page failed', (tester) async {
      for (final state in [
        const PagedState<int>.loading(),
        PagedState<int>.loaded(page: page(items: 0, lastPage: 1)),
        const PagedState<int>.failure(Failure.server(message: 'تعذّر', statusCode: 500)),
      ]) {
        // Act
        await tester.pumpWidget(withHeader(state));

        // Assert — فترةٌ لا تطابق شيئاً تبقى قابلةً للتغيير.
        expect(find.byKey(const Key('filters')), findsOneWidget, reason: '$state');
      }
    });

    testWidgets('what is typed in it survives the rows reloading beneath it', (tester) async {
      // Arrange
      await tester.pumpWidget(withHeader(PagedState<int>.loaded(page: page(items: 3, lastPage: 1))));
      await tester.enterText(find.byKey(const Key('filters')), 'النورس');
      await tester.pump();

      // Act — كلُّ حرفٍ في البحث يعيد تحميل الصفوف.
      await tester.pumpWidget(withHeader(const PagedState<int>.loading()));
      await tester.pumpWidget(withHeader(PagedState<int>.loaded(page: page(items: 1, lastPage: 1))));

      // Assert
      expect(find.text('النورس'), findsOneWidget);
    });

    testWidgets('it scrolls away with the rows instead of holding the top of the screen', (tester) async {
      // Arrange
      await tester.pumpWidget(withHeader(PagedState<int>.loaded(page: page(items: 40, lastPage: 1))));
      final before = tester.getTopLeft(find.byKey(const Key('filters'))).dy;

      // Act
      await tester.drag(find.text('row 3'), const Offset(0, -400));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('filters')).hitTestable(), findsNothing);
      expect(before, greaterThanOrEqualTo(0));
    });
  });
}
