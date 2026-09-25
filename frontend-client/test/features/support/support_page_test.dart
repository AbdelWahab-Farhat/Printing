import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/models/ticket_change.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/support_cubit.dart';
import 'package:dayaa_client/features/support/presentation/views/support_page.dart';
import 'package:dayaa_client/features/support/repositories/support_repository.dart';
import 'package:dayaa_client/features/support/usecases/browse_tickets.dart';
import 'package:dayaa_client/features/support/usecases/open_ticket.dart';
import 'package:dayaa_client/features/support/usecases/watch_ticket_changes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSupport extends Mock implements SupportRepository {}

/// «الدعم»: تبويبان في الأعلى — «المفتوحة» و«المغلقة» — لكلٍّ قائمته (طلب المستخدم،
/// 2026-09-25).
///
/// Arrange - Act - Assert في كل حالة.
void main() {
  late _MockSupport support;

  final live = SupportTicket(
    id: 41,
    subject: 'الطلبية #1228 تأخرت',
    status: TicketStatus.inProgress,
    statusLabel: 'قيد المعالجة',
    unreadCount: 2,
    preview: 'خرجت مع المندوب اليوم',
    lastMessageAt: DateTime.now(),
  );

  const done = SupportTicket(
    id: 30,
    subject: 'سؤال قديم',
    status: TicketStatus.closed,
    statusLabel: 'مغلقة',
    isOpen: false,
    preview: 'شكراً',
  );

  Paginated<SupportTicket> page(List<SupportTicket> items) => Paginated<SupportTicket>(
    items: items,
    meta: PageMeta(currentPage: 1, perPage: 15, lastPage: 1, total: items.length),
  );

  setUp(() {
    support = _MockSupport();

    when(
      () => support.tickets(page: any(named: 'page'), openOnly: true),
    ).thenAnswer((_) async => Right(page([live])));
    when(
      () => support.tickets(page: any(named: 'page'), openOnly: false),
    ).thenAnswer((_) async => Right(page(const [done])));
    when(() => support.watchChanges()).thenAnswer((_) => const Stream<TicketChange>.empty());
    when(() => support.liveResumed).thenAnswer((_) => const Stream<void>.empty());

    sl.registerFactory(
      () => SupportCubit(
        browse: BrowseTickets(support),
        open: OpenTicket(support),
        watch: WatchTicketChanges(support),
      ),
    );

    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(430, 932);
    view.devicePixelRatio = 1;
  });

  tearDown(() async {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
    await sl.reset();
  });

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
      home: SupportPage(),
    ),
  );

  testWidgets('two tabs at the top, and the open one is shown first', (tester) async {
    // Arrange
    await tester.pumpWidget(host());

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(TabBar), findsOne);
    expect(find.text('المفتوحة'), findsOne);
    expect(find.text('المغلقة'), findsOne);
    expect(find.text('الطلبية #1228 تأخرت'), findsOne);
    expect(find.text('سؤال قديم'), findsNothing);
  });

  /// الرقم وحده، بلا «طلبية» ولا «#» (طلب صاحب العمل، ٢٠٢٦-٠٩-٢٥).
  testWidgets('a ticket about an order is tagged with its number alone', (tester) async {
    // Arrange
    when(() => support.tickets(page: any(named: 'page'), openOnly: true)).thenAnswer(
      (_) async =>
          Right(page([live.copyWith(order: const TicketOrderRef(id: 7, code: '1228'))])),
    );
    await tester.pumpWidget(host());

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('1228'), findsOne);
    expect(find.text('طلبية #1228'), findsNothing);
  });

  testWidgets('«الكل» is gone — the question is always open or closed', (tester) async {
    // Arrange
    await tester.pumpWidget(host());

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('الكل'), findsNothing);
    verifyNever(() => support.tickets(page: any(named: 'page')));
  });

  testWidgets('the closed tab is asked for only when it is opened', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    verifyNever(() => support.tickets(page: any(named: 'page'), openOnly: false));

    // Act
    await tester.tap(find.text('المغلقة'));
    await tester.pumpAndSettle();

    // Assert
    verify(() => support.tickets(page: 1, openOnly: false)).called(1);
    expect(find.text('سؤال قديم'), findsOne);
  });

  testWidgets('going back to the open tab does not ask again', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.text('المغلقة'));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('المفتوحة'));
    await tester.pumpAndSettle();

    // Assert — كلُّ تبويبٍ يبقى حيّاً بقائمته وتمريرها.
    verify(() => support.tickets(page: 1, openOnly: true)).called(1);
    expect(find.text('الطلبية #1228 تأخرت'), findsOne);
  });

  testWidgets('a ticket with replies not yet read shows how many', (tester) async {
    // Arrange
    await tester.pumpWidget(host());

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('2'), findsOne);
    expect(find.text('خرجت مع المندوب اليوم'), findsOne);
  });
}
