import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/home/presentation/widgets/employee_card.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:dayaa/features/internal_tickets/presentation/viewmodel/internal_tickets_home_cubit.dart';
import 'package:dayaa/features/internal_tickets/presentation/widgets/internal_tickets_card_section.dart';
import 'package:dayaa/features/internal_tickets/repositories/internal_tickets_repository.dart';
import 'package:dayaa/features/internal_tickets/usecases/internal_tickets_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements InternalTicketsRepository {}

/// تذاكرُ الموظفين **داخل بطاقة الموظف** في الرئيسية، كبطاقة بريمولا تماماً — طلبُ المالك
/// ٢٠٢٦-١٠-٢٣: ما ينتظر ردّي تحت الاسم والكود، كلُّ صفٍّ بـ«بانتظار ردّك» وآخرِ كلام الزميل وزرِّ
/// «رد» يفتح حقلاً تحته يُردّ منه بلا فتح المحادثة. ثم «عرض كل التذاكر» و«تذكرة جديدة». **بلا عدّادات.**
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockRepository repository;

  setUpAll(() => registerFallbackValue(const OutgoingInternalMessage(clientToken: 'x')));

  InternalTicket waiting(int id, String title) => InternalTicket(
    id: id,
    code: 'T$id',
    title: title,
    status: InternalTicketStatus.inProgress,
    statusLabel: 'قيد المعالجة',
    counterpart: const InternalPerson(id: 9, name: 'هدى'),
    awaitingMyReply: true,
    lastMessage: InternalLastMessage(
      id: id * 10,
      authorId: 9,
      authorName: 'هدى',
      preview: 'هل وصلت الأكياس؟',
      sentAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  );

  Future<InternalTicketsHomeCubit> arrange(List<InternalTicket> tickets) async {
    await Injector.reset();
    sl.registerSingleton<Session>(
      Session()
        ..adopt(
          const AuthUser(id: 7, name: 'فرحات', phone: '0911234567', permissions: []),
        ),
    );
    repository = _MockRepository();
    when(() => repository.home()).thenAnswer(
      (_) async => Right(
        InternalTicketsHome(
          tickets: tickets,
          awaitingMyReply: tickets.length,
          totalOpen: tickets.length + 2,
          unreadTickets: 1,
        ),
      ),
    );
    when(() => repository.send(any(), any())).thenAnswer((_) async => Right(waiting(1, 'x')));
    when(() => repository.watchMine(any())).thenAnswer((_) => const Stream<int>.empty());
    when(() => repository.liveResumed).thenAnswer((_) => const Stream<void>.empty());

    final cubit = InternalTicketsHomeCubit(
      get: GetInternalTicketsHome(repository),
      send: SendInternalMessage(repository),
      watch: WatchInternalTickets(repository),
      me: 7,
      newToken: () => 'token',
    );
    await cubit.load();

    return cubit;
  }

  Widget host(InternalTicketsHomeCubit cubit) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: BlocProvider<InternalTicketsHomeCubit>.value(
          value: cubit,
          child: const SingleChildScrollView(
            child: EmployeeCard(
              user: AuthUser(id: 7, name: 'فرحات', phone: '0911234567', employeeCode: '1013'),
              bottom: InternalTicketsCardSection(),
            ),
          ),
        ),
      ),
    ),
  );

  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
      ..physicalSize = const Size(430, 1600)
      ..devicePixelRatio = 1;
    addTearDown(view.reset);
  });

  tearDown(Injector.reset);

  Finder inCard(Finder finder) => find.descendant(of: find.byType(EmployeeCard), matching: finder);

  testWidgets('what waits on me sits in the employee card, with no counters', (tester) async {
    // Arrange
    final cubit = await arrange([waiting(1, 'الأكياس'), waiting(2, 'فاتورة المطبعة')]);

    // Act
    await tester.pumpWidget(host(cubit));
    await tester.pumpAndSettle();

    // Assert
    expect(inCard(find.text('فرحات')), findsOneWidget);
    expect(inCard(find.text('الأكياس')), findsOneWidget);
    expect(inCard(find.text('فاتورة المطبعة')), findsOneWidget);
    expect(inCard(find.text('بانتظار ردّك')), findsNWidgets(2));
    expect(inCard(find.text('رد')), findsNWidgets(2));
    expect(inCard(find.text('عرض كل التذاكر')), findsOneWidget);
    expect(inCard(find.byTooltip('تذكرة جديدة')), findsOneWidget);
    expect(find.text('تنتظر ردّك'), findsNothing);
    expect(find.text('غير مقروءة'), findsNothing);
    expect(find.text('مفتوحة'), findsNothing);
  });

  testWidgets('the card holds four rows at most', (tester) async {
    // Arrange
    final cubit = await arrange([for (var id = 1; id <= 6; id++) waiting(id, 'تذكرة $id')]);

    // Act
    await tester.pumpWidget(host(cubit));
    await tester.pumpAndSettle();

    // Assert
    expect(inCard(find.text('بانتظار ردّك')), findsNWidgets(4));
    expect(find.text('تذكرة 5'), findsNothing);
  });

  testWidgets('each row says who waits and what they said last', (tester) async {
    // Arrange
    final cubit = await arrange([waiting(1, 'الأكياس')]);

    // Act
    await tester.pumpWidget(host(cubit));
    await tester.pumpAndSettle();

    // Assert
    expect(inCard(find.text('هدى')), findsOneWidget);
    expect(inCard(find.text('هدى:')), findsOneWidget);
    expect(inCard(find.text('هل وصلت الأكياس؟')), findsOneWidget);
    expect(inCard(find.text('منذ 3 ساعات')), findsOneWidget);
    expect(inCard(find.text('قيد المعالجة')), findsOneWidget);
  });

  testWidgets('«رد» opens a field under its row, and the reply goes without opening the thread', (
    tester,
  ) async {
    // Arrange
    final cubit = await arrange([waiting(1, 'الأكياس')]);
    await tester.pumpWidget(host(cubit));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('رد'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'وصلت الصبح');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('إرسال الرد'));
    await tester.pumpAndSettle();
    // «أُرسل الردّ» يغيب بمؤقّته وحركته، ولا يبقى شيءٌ منهما بعد الاختبار.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Assert
    final sent =
        verify(() => repository.send(1, captureAny())).captured.single as OutgoingInternalMessage;
    expect(sent.body, 'وصلت الصبح');
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('one reply is open at a time', (tester) async {
    // Arrange
    final cubit = await arrange([waiting(1, 'الأكياس'), waiting(2, 'فاتورة المطبعة')]);
    await tester.pumpWidget(host(cubit));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('رد').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('رد').last);
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('nothing waiting says so, and still offers all tickets and a new one', (
    tester,
  ) async {
    // Arrange
    final cubit = await arrange(const []);

    // Act
    await tester.pumpWidget(host(cubit));
    await tester.pumpAndSettle();

    // Assert
    expect(inCard(find.text('لا تذاكر بانتظار ردّك')), findsOneWidget);
    expect(inCard(find.text('عرض كل التذاكر')), findsOneWidget);
    expect(inCard(find.byTooltip('تذكرة جديدة')), findsOneWidget);
  });
}
