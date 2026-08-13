import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/audit/models/activity_log_entry.dart';
import 'package:printing/features/audit/models/audit_event.dart';
import 'package:printing/features/audit/models/audit_subject.dart';
import 'package:printing/features/audit/presentation/views/activity_log_page.dart';
import 'package:printing/features/audit/repositories/audit_repository.dart';
import 'package:printing/features/audit/usecases/get_activity_log.dart';

/// The one history screen every model shares.
///
/// Each test below stands for something that was on the screen and unreadable: raw column
/// names, an undifferentiated run of stamped cards, and an edit written out as a list of new
/// values with no sign of what they replaced.
///
/// Arrange - Act - Assert throughout.
class _MockAuditRepository extends Mock implements AuditRepository {}

void main() {
  late _MockAuditRepository repository;

  /// A creation with Arabic column names attached, as the server sends them.
  ActivityLogEntry creation({DateTime? at}) => ActivityLogEntry(
    id: 1,
    event: 'created',
    eventLabel: 'إنشاء',
    description: 'تم إنشاء محل عميل',
    subjectType: 'customer_shop',
    causer: const AuditCauser(id: 1, name: 'المدير'),
    changes: const AuditChanges(
      attributes: {'name': 'فرع الظهرة', 'page_url': null, 'latitude': 32.8701},
    ),
    attributeLabels: const {
      'name': 'اسم المحل',
      'page_url': 'رابط الصفحة',
      'latitude': 'خط العرض',
    },
    createdAt: at ?? DateTime(2026, 1, 15, 21, 9),
  );

  ActivityLogEntry edit({DateTime? at}) => ActivityLogEntry(
    id: 2,
    event: 'updated',
    eventLabel: 'تعديل',
    description: 'تم تعديل عميل',
    causer: const AuditCauser(id: 2, name: 'سالم'),
    changes: const AuditChanges(
      old: {'phone': '0917775555'},
      attributes: {'phone': '0913334444'},
    ),
    attributeLabels: const {'phone': 'رقم الهاتف'},
    createdAt: at ?? DateTime(2026, 1, 15, 10, 5),
  );

  /// A status change, with the Arabic for both halves attached — as the server now sends it.
  ActivityLogEntry statusChange({DateTime? at}) => ActivityLogEntry(
    id: 3,
    event: 'updated',
    eventLabel: 'تعديل',
    description: 'تم تعديل طلبية',
    subjectType: 'order',
    causer: const AuditCauser(id: 2, name: 'سالم'),
    changes: const AuditChanges(
      old: {'status': 'new', 'placed_at': null},
      attributes: {'status': 'printing', 'placed_at': '2026-01-15T08:30:00+00:00'},
    ),
    attributeLabels: const {'status': 'الحالة', 'placed_at': 'تاريخ الطلب'},
    valueLabels: const AuditValueLabels(
      old: {'status': 'جديدة'},
      attributes: {'status': 'قيد الطباعة'},
    ),
    createdAt: at ?? DateTime(2026, 1, 15, 11, 20),
  );

  Paginated<ActivityLogEntry> page(
    List<ActivityLogEntry> items, {
    Map<String, dynamic>? counts,
  }) => Paginated<ActivityLogEntry>(
    items: items,
    meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: items.length),
    extraMeta: counts == null ? const {} : {'event_counts': counts},
  );

  void whenAsking(AuditEvent? event, Paginated<ActivityLogEntry> answer) {
    when(
      () => repository.logs(
        any(),
        any(),
        event: event,
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(answer));
  }

  setUpAll(() => registerFallbackValue(AuditSubject.customer));

  setUp(() async {
    await Injector.reset();
    repository = _MockAuditRepository();
    sl.registerLazySingleton<GetActivityLog>(() => GetActivityLog(repository));
  });

  tearDown(Injector.reset);

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
      home: ActivityLogPage(subject: AuditSubject.customer, recordId: 7, title: 'مطبعة النور'),
    ),
  );

  testWidgets('every column is named in Arabic, not by its database key', (tester) async {
    // Arrange — this is the defect the screen was rebuilt for: it read `name`, `page_url`,
    // `latitude` to people who have never seen this schema.
    whenAsking(null, page([creation()]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('اسم المحل'), findsOneWidget);
    expect(find.text('رابط الصفحة'), findsOneWidget);
    expect(find.text('خط العرض'), findsOneWidget);
    expect(find.text('page_url'), findsNothing);
    expect(find.text('latitude'), findsNothing);
  });

  testWidgets('a value that was never set reads as a dash, not as a blank', (tester) async {
    // Arrange — an empty cell beside a label looks like a rendering fault.
    whenAsking(null, page([creation()]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('an edit shows what it replaced, struck through, beside what it became', (
    tester,
  ) async {
    // Arrange — the old screen listed only the new value, so «رقم الهاتف 0913334444» said
    // nothing about what the number had been.
    whenAsking(null, page([edit()]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — one rich span carrying both, and the arrow between them.
    expect(find.textContaining('0917775555', findRichText: true), findsOneWidget);
    expect(find.textContaining('0913334444', findRichText: true), findsOneWidget);
    expect(find.textContaining('←', findRichText: true), findsOneWidget);
    // …under its Arabic name, not under `phone`.
    expect(find.text('رقم الهاتف'), findsOneWidget);
  });

  testWidgets('entries are gathered under the day they happened', (tester) async {
    // Arrange — a flat run of cards each stamped `2026/1/15 — 21:09` makes the reader do the
    // grouping in their head.
    whenAsking(null, page([creation(), edit()]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — one heading for the two of them, and Arabic counts its own way.
    expect(find.text('2026/1/15'), findsOneWidget);
    expect(find.text('حدثان'), findsOneWidget);
  });

  testWidgets('the day something happened today is called today', (tester) async {
    // Arrange — on the screen somebody opens right after making a change, the top heading is
    // the one they are looking for.
    final now = DateTime.now();
    whenAsking(null, page([creation(at: now)]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('اليوم'), findsOneWidget);
    expect(find.text('حدث واحد'), findsOneWidget);
  });

  testWidgets('the filter chips carry the whole trail’s counts, not this page’s', (
    tester,
  ) async {
    // Arrange — one entry on screen, seventeen in the history.
    whenAsking(
      null,
      page([creation()], counts: {'created': 12, 'updated': 5, 'deleted': 0, 'restored': 0}),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — the totals, and «الكل» agreeing with the sum of the four beside it.
    expect(find.text('12'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('17'), findsOneWidget);
  });

  testWidgets('tapping a chip asks the server for that kind alone', (tester) async {
    // Arrange — narrowing the page already downloaded would show a fraction of the history
    // and present it as all of it.
    whenAsking(null, page([creation(), edit()], counts: {'created': 1, 'updated': 1}));
    whenAsking(AuditEvent.created, page([creation()], counts: {'created': 1, 'updated': 1}));

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act — the chip, keyed: «إنشاء» is also the badge on the creation card below it.
    await tester.tap(find.byKey(const ValueKey('event-filter-created')));
    await tester.pumpAndSettle();

    // Assert
    verify(
      () => repository.logs(
        AuditSubject.customer,
        7,
        event: AuditEvent.created,
        page: 1,
        perPage: any(named: 'perPage'),
      ),
    ).called(1);
    expect(find.text('تم تعديل عميل'), findsNothing);
  });

  testWidgets('the chips stay put while the list under them reloads', (tester) async {
    // Arrange — a filter row that vanishes into a skeleton the moment it is used is a filter
    // row the thumb loses.
    whenAsking(null, page([creation(), edit()], counts: {'created': 1, 'updated': 1}));
    when(
      () => repository.logs(
        any(),
        any(),
        event: AuditEvent.deleted,
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) => Future.delayed(const Duration(milliseconds: 60), () => Right(page([]))),
    );

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act — mid-flight.
    await tester.tap(find.byKey(const ValueKey('event-filter-deleted')));
    await tester.pump();

    // Assert — the chips and their numbers are still there.
    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('إنشاء'), findsOneWidget);
    expect(find.text('2'), findsOneWidget, reason: 'the «الكل» total must not blink out');

    await tester.pumpAndSettle();
  });

  testWidgets('an empty filter says which filter found nothing', (tester) async {
    // Arrange — «لا توجد تعديلات» under an active «حذف» chip reads as "this record has no
    // history", which is a different and wrong statement.
    whenAsking(null, page([creation()], counts: {'created': 1, 'deleted': 0}));
    whenAsking(AuditEvent.deleted, page([], counts: {'created': 1, 'deleted': 0}));

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byKey(const ValueKey('event-filter-deleted')));
    await tester.pumpAndSettle();

    // Assert
    expect(find.textContaining('من نوع «حذف»'), findsOneWidget);
  });

  testWidgets('the bar says whose history this is', (tester) async {
    // Arrange
    whenAsking(null, page([creation()]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('سجل العميل'), findsOneWidget);
    expect(find.text('مطبعة النور'), findsOneWidget);
  });

  testWidgets('a value is read in Arabic too, not just the column it sits in', (tester) async {
    // Arrange — the half the labels left behind: «الحالة» in Arabic, `printing` in English,
    // on the same line, while the order card three taps away says «قيد الطباعة».
    whenAsking(null, page([statusChange()]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — and the English is gone, which is the part that was on the screen.
    expect(find.textContaining('جديدة'), findsOneWidget);
    expect(find.textContaining('قيد الطباعة'), findsOneWidget);
    expect(find.textContaining('printing'), findsNothing);
    expect(find.textContaining('new'), findsNothing);
  });

  testWidgets('a timestamp is read as a date, not as the line the server stored', (tester) async {
    // Arrange — `2026-01-15T08:30:00+00:00` is a full line of ISO inside a two-line box.
    whenAsking(null, page([statusChange()]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — formatted on the device, because only the device knows its time zone.
    expect(find.textContaining('T08:30:00'), findsNothing);
    expect(find.textContaining('2026-01-15'), findsWidgets);
  });

  testWidgets('a value the server did not translate is still drawn', (tester) async {
    // Arrange — a name is already Arabic, so no translation is sent for it. The fallback is
    // the whole reason the dictionary lives on the server.
    whenAsking(null, page([creation()]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('فرع الظهرة'), findsOneWidget);
  });

}
