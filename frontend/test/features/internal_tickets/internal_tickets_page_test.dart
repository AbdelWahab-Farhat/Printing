import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket_query.dart';
import 'package:dayaa/features/internal_tickets/presentation/viewmodel/internal_tickets_cubit.dart';
import 'package:dayaa/features/internal_tickets/presentation/views/internal_tickets_page.dart';
import 'package:dayaa/features/internal_tickets/repositories/internal_tickets_repository.dart';
import 'package:dayaa/features/internal_tickets/usecases/internal_tickets_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements InternalTicketsRepository {}

/// قائمة «الموظفين» كما طلبها المالك ٢٠٢٦-١٠-٢٣: **الحالتان وحدهما على الصفحة**، وكلُّ ما سواهما —
/// «تذاكري / الكل» للمدير وحده، و«غير المقروءة»، ونوعُ المشكلة، والترتيب — خلف زرّ التصفية في
/// ورقةٍ سفلية. والمديرُ يفتح على «تذاكري».
///
/// **ولا «تذكرة جديدة» فيها، والصفحةُ كلُّها تُمرَّر** — البحثُ والرقاقتان مع الصفوف (٢٠٢٦-١٠-٢٣):
/// التذكرةُ الجديدة من بطاقة الموظف في الرئيسية.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockRepository repository;

  setUpAll(() => registerFallbackValue(const InternalTicketQuery()));

  Future<void> arrange({required bool admin}) async {
    await Injector.reset();
    repository = _MockRepository();

    when(
      () => repository.tickets(
        query: any(named: 'query'),
        search: any(named: 'search'),
        page: any(named: 'page'),
      ),
    ).thenAnswer(
      (_) async => const Right(
        Paginated<InternalTicket>(
          items: [],
          meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 0),
        ),
      ),
    );
    when(() => repository.categories()).thenAnswer(
      (_) async => const Right([
        InternalCategory(id: 3, name: 'مخزون'),
        InternalCategory(id: 4, name: 'توصيل'),
      ]),
    );
    when(() => repository.watchMine(any())).thenAnswer((_) => const Stream<int>.empty());
    when(() => repository.liveResumed).thenAnswer((_) => const Stream<void>.empty());

    sl
      ..registerSingleton<Session>(
        Session()
          ..adopt(
            AuthUser(
              id: 7,
              name: 'فرحات',
              phone: '0911234567',
              isAdmin: admin,
              permissions: const [],
            ),
          ),
      )
      ..registerLazySingleton<GetInternalCategories>(() => GetInternalCategories(repository))
      ..registerFactoryParam<InternalTicketsCubit, InternalTicketQuery, void>(
        (query, _) => InternalTicketsCubit(
          browse: BrowseInternalTickets(repository),
          watch: WatchInternalTickets(repository),
          me: 7,
          query: query,
          catchUpDelay: Duration.zero,
        ),
      );
  }

  Widget host() => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => const MaterialApp(
      locale: Locale('ar'),
      supportedLocales: [Locale('ar')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: InternalTicketsPage(),
    ),
  );

  Future<void> openFilters(WidgetTester tester) async {
    await tester.tap(find.byTooltip('تصفية التذاكر'));
    await tester.pumpAndSettle();
  }

  bool isSelected(WidgetTester tester, String label) =>
      tester.widget<FilterOptionChip>(find.widgetWithText(FilterOptionChip, label)).isSelected;

  /// السؤالُ الأخير الذي ذهب إلى الخادم.
  InternalTicketQuery lastQuery() =>
      verify(
            () => repository.tickets(
              query: captureAny(named: 'query'),
              search: any(named: 'search'),
              page: any(named: 'page'),
            ),
          ).captured.last
          as InternalTicketQuery;

  tearDown(Injector.reset);

  testWidgets('only the two statuses sit on the page; the rest wait behind the filter button', (
    tester,
  ) async {
    // Arrange
    await arrange(admin: true);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('قيد المعالجة'), findsOneWidget);
    expect(find.text('مغلقة'), findsOneWidget);
    expect(find.text('تذاكري'), findsNothing);
    expect(find.text('الكل'), findsNothing);
    expect(find.text('غير المقروءة'), findsNothing);
    expect(find.text('الأقدم نشاطاً'), findsNothing);
    expect(find.byTooltip('تصفية التذاكر'), findsOneWidget);
  });

  testWidgets('the list offers no «تذكرة جديدة» of its own', (tester) async {
    // Arrange
    await arrange(admin: false);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('تذكرة جديدة'), findsNothing);
  });

  testWidgets('the search and the status chips scroll with the rows', (tester) async {
    // Arrange
    await arrange(admin: false);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    final scroller = find.byType(CustomScrollView);
    expect(find.descendant(of: scroller, matching: find.byType(SearchField)), findsOneWidget);
    expect(find.descendant(of: scroller, matching: find.text('قيد المعالجة')), findsOneWidget);
  });

  testWidgets('an administrator lands on «تذاكري» and may widen it to «الكل»', (tester) async {
    // Arrange
    await arrange(admin: true);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    final first = lastQuery();

    // Act
    await openFilters(tester);
    final openedOnMine = isSelected(tester, 'تذاكري');
    await tester.tap(find.text('الكل'));
    await tester.pump();
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    // Assert
    expect(first.allTickets, isFalse);
    expect(openedOnMine, isTrue);
    expect(lastQuery().allTickets, isTrue);
  });

  testWidgets('a colleague who is not an administrator is never offered «الكل»', (tester) async {
    // Arrange
    await arrange(admin: false);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await openFilters(tester);

    // Assert
    expect(find.text('تذاكري'), findsNothing);
    expect(find.text('الكل'), findsNothing);
    expect(find.text('غير المقروءة'), findsOneWidget);
  });

  testWidgets('unread, a kind of problem and the oldest first are asked for on «تطبيق»', (
    tester,
  ) async {
    // Arrange
    await arrange(admin: false);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await openFilters(tester);
    await tester.tap(find.text('غير المقروءة'));
    await tester.tap(find.text('مخزون'));
    await tester.tap(find.text('الأقدم نشاطاً'));
    await tester.pump();
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    // Assert
    final asked = lastQuery();
    expect(asked.unreadOnly, isTrue);
    expect(asked.categoryId, 3);
    expect(asked.oldestFirst, isTrue);
    expect(asked.status, InternalTicketStatus.inProgress);
  });

  testWidgets('swiping the sheet away changes nothing', (tester) async {
    // Arrange
    await arrange(admin: false);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await openFilters(tester);
    await tester.tap(find.text('غير المقروءة'));
    await tester.pump();

    // Act
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    // Assert
    expect(lastQuery().unreadOnly, isFalse);
  });
}
