import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/audit/models/activity_log_entry.dart';
import 'package:dayaa/features/audit/models/audit_event.dart';
import 'package:dayaa/features/audit/models/audit_subject.dart';
import 'package:dayaa/features/audit/presentation/views/activity_log_page.dart';
import 'package:dayaa/features/audit/repositories/audit_repository.dart';
import 'package:dayaa/features/audit/usecases/get_activity_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
      attributes: {
        'name': 'فرع الظهرة',
        'page_url': 'fb.com/dhahra',
        // Never filled in. Present in the payload and absent from the screen — see the test
        // about values that say nothing.
        'notes': null,
        'latitude': 32.8701,
      },
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

  testWidgets('a value that was never set gets no row at all', (tester) async {
    // Arrange — a creation that lists «ملاحظات —» buries the facts worth reading under the
    // columns that happened to be null.
    whenAsking(null, page([creation()]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — neither the dash nor the label that would have sat beside it.
    expect(find.text('—'), findsNothing);
    expect(find.text('ملاحظات'), findsNothing);
    // And the columns that *were* filled in are all still there.
    expect(find.text('اسم المحل'), findsOneWidget);
  });

  testWidgets('a field somebody cleared still shows what it held', (tester) async {
    // Arrange — the mirror of the test above, and the reason it is not «hide every null»: on a
    // *change*, «نص ← —» is somebody emptying a field, which is exactly what a trail records.
    whenAsking(
      null,
      page([
        ActivityLogEntry(
          id: 9,
          event: 'updated',
          eventLabel: 'تعديل',
          subjectType: 'customer_shop',
          causer: const AuditCauser(id: 1, name: 'المدير'),
          changes: const AuditChanges(
            old: {'page_url': 'fb.com/dhahra'},
            attributes: {'page_url': null},
          ),
          attributeLabels: const {'page_url': 'رابط الصفحة'},
          createdAt: DateTime(2026, 1, 15, 9),
        ),
      ]),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — the two halves live in one RichText, so the finder has to look inside it.
    expect(find.text('رابط الصفحة'), findsOneWidget);
    expect(find.textContaining('fb.com/dhahra', findRichText: true), findsOneWidget);
    expect(find.textContaining('—', findRichText: true), findsOneWidget);
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
    // Arrange — a flat run of cards each stamped `15 يناير 2026 · 9:09 م` makes the reader do the
    // grouping in their head.
    whenAsking(null, page([creation(), edit()]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — one heading for the two of them, and Arabic counts its own way.
    // The heading a person reads, not the key the entries are grouped by — see `AppDates`.
    expect(find.text('15 يناير 2026'), findsOneWidget);
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

  group('a creation or a deletion', () {
    /// An entry stating [values], each labelled «حقل <column>».
    ActivityLogEntry stating(
      Map<String, dynamic> values, {
      bool deleted = false,
      bool restored = false,
    }) => ActivityLogEntry(
          id: 40,
          event: deleted ? 'deleted' : (restored ? 'restored' : 'created'),
          eventLabel: deleted ? 'حذف' : (restored ? 'استرجاع' : 'إنشاء'),
          description: deleted ? 'تم حذف طلبية' : 'تم إنشاء طلبية',
          subjectType: 'order',
          changes: deleted ? AuditChanges(old: values) : AuditChanges(attributes: values),
          attributeLabels: {for (final column in values.keys) column: 'حقل $column'},
          createdAt: DateTime(2026, 1, 15, 9),
        );

    testWidgets('a creation leaves out the zeros and «لا» it merely started with', (
      tester,
    ) async {
      // Arrange — what somebody chose, beside what every new order starts at.
      whenAsking(
        null,
        page([
          stating({
            'grand_total': '450.00',
            'written_off_amount': '0.00',
            'delivery_price': 0,
            'is_archived': false,
            'city_id': 0,
          }),
        ]),
      );

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('حقل grand_total'), findsOneWidget);
      expect(find.text('حقل written_off_amount'), findsNothing);
      expect(find.text('حقل delivery_price'), findsNothing);
      expect(find.text('حقل is_archived'), findsNothing);
    });

    testWidgets('a deletion shows no fields until asked, and then keeps its zeros', (
      tester,
    ) async {
      // Arrange — who deleted it and when is the story; the heading already tells it.
      whenAsking(
        null,
        page([
          stating({'grand_total': '450.00', 'paid_amount': '0.00'}, deleted: true),
        ]),
      );
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert — closed.
      expect(find.text('تم حذف طلبية'), findsOneWidget);
      expect(find.text('حقل grand_total'), findsNothing);
      expect(find.text('عرض الحقول (2)'), findsOneWidget);

      // Act
      await tester.tap(find.byKey(const ValueKey('show-all-fields')));
      await tester.pumpAndSettle();

      // Assert — the zero is the state it was deleted in, so it stays.
      expect(find.text('حقل grand_total'), findsOneWidget);
      expect(find.text('حقل paid_amount'), findsOneWidget);
    });

    testWidgets('a restore shows no fields until asked either', (tester) async {
      // Arrange — it brings back what the deletion recorded; listing it again says nothing.
      whenAsking(
        null,
        page([
          stating({'grand_total': '450.00', 'written_off_amount': '0.00'}, restored: true),
        ]),
      );

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('حقل grand_total'), findsNothing);
      expect(find.text('عرض الحقول (2)'), findsOneWidget);
    });

    testWidgets('a long card shows five lines and a way to the rest', (tester) async {
      // Arrange — nine values worth reading.
      whenAsking(
        null,
        page([
          stating({for (var i = 1; i <= 9; i++) 'column_$i': 'قيمة $i'}),
        ]),
      );
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert — collapsed.
      expect(find.text('حقل column_5'), findsOneWidget);
      expect(find.text('حقل column_6'), findsNothing);
      expect(find.text('عرض كل الحقول (9)'), findsOneWidget);

      // Act
      await tester.tap(find.byKey(const ValueKey('show-all-fields')));
      await tester.pumpAndSettle();

      // Assert — everything, and the way back.
      expect(find.text('حقل column_9'), findsOneWidget);
      expect(find.text('عرض أقل'), findsOneWidget);
    });

    testWidgets('one line over the limit is shown rather than hidden behind a button', (
      tester,
    ) async {
      // Arrange — six: a button revealing one line would take the room of the line.
      whenAsking(
        null,
        page([
          stating({for (var i = 1; i <= 6; i++) 'column_$i': 'قيمة $i'}),
        ]),
      );

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('حقل column_6'), findsOneWidget);
      expect(find.byKey(const ValueKey('show-all-fields')), findsNothing);
    });
  });

  group('the field search', () {
    Paginated<ActivityLogEntry> withFields(List<ActivityLogEntry> items) =>
        Paginated<ActivityLogEntry>(
          items: items,
          meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: items.length),
          extraMeta: const {
            'fields': [
              {'key': 'order_item:unit_price', 'label': 'سعر الوحدة', 'subject_label': 'بند الطلبية'},
              {'key': 'order:delivery_price', 'label': 'سعر التوصيل', 'subject_label': 'الطلبية'},
              {'key': 'customer:phone', 'label': 'رقم الهاتف', 'subject_label': 'العميل'},
            ],
          },
        );

    void whenAskingField(String? field, Paginated<ActivityLogEntry> answer) {
      when(
        () => repository.logs(
          any(),
          any(),
          event: any(named: 'event'),
          field: field,
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => Right(answer));
    }

    Finder box() => find.descendant(
      of: find.byKey(const ValueKey('field-search')),
      matching: find.byType(EditableText),
    );

    testWidgets('typing part of a name suggests the fields that carry it', (tester) async {
      // Arrange — a creation alone, so no card on screen already reads «رقم الهاتف».
      whenAskingField(null, withFields([creation()]));
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act — «سعر», the way somebody looking for a price would start.
      await tester.enterText(box(), 'سعر');
      await tester.pumpAndSettle();

      // Assert — both prices, with whose each is; not the phone.
      expect(find.text('سعر الوحدة'), findsOneWidget);
      expect(find.text('بند الطلبية'), findsOneWidget);
      expect(find.text('سعر التوصيل'), findsOneWidget);
      expect(find.text('رقم الهاتف'), findsNothing);
    });

    testWidgets('nothing is suggested before anything is typed', (tester) async {
      // Arrange
      whenAskingField(null, withFields([creation()]));
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(box());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('سعر الوحدة'), findsNothing);
    });

    testWidgets('picking a suggestion filters the history and says so', (tester) async {
      // Arrange
      whenAskingField(null, withFields([creation(), edit()]));
      whenAskingField('order_item:unit_price', page([edit()]));
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      // «وحده» with a ha, as typed, for «الوحدة» with a ta marbuta.
      await tester.enterText(box(), 'وحده');
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('سعر الوحدة'));
      await tester.pumpAndSettle();

      // Assert — asked of the server, and the box has become a chip naming the filter.
      verify(
        () => repository.logs(
          any(),
          any(),
          event: any(named: 'event'),
          field: 'order_item:unit_price',
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).called(1);
      expect(find.byKey(const ValueKey('field-filter')), findsOneWidget);
      expect(find.text('الحقل: سعر الوحدة · بند الطلبية'), findsOneWidget);
      expect(find.byType(AppTextField), findsNothing);
      expect(find.text('تم إنشاء محل عميل'), findsNothing);
    });

    testWidgets('removing the chip brings the whole history and the box back', (tester) async {
      // Arrange
      whenAskingField(null, withFields([creation(), edit()]));
      whenAskingField('order_item:unit_price', page([edit()]));
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      await tester.enterText(box(), 'وحده');
      await tester.pumpAndSettle();
      await tester.tap(find.text('سعر الوحدة'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byTooltip('إلغاء البحث بالحقل'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const ValueKey('field-filter')), findsNothing);
      expect(box(), findsOneWidget);
      expect(find.text('تم إنشاء محل عميل'), findsOneWidget);
    });

    testWidgets('an empty field search says which field found nothing', (tester) async {
      // Arrange
      whenAskingField(null, withFields([creation()]));
      whenAskingField('customer:phone', page([]));
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      await tester.enterText(box(), 'هاتف');
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('رقم الهاتف'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('تخص «رقم الهاتف»'), findsOneWidget);
    });

    /// تعديلٌ على [subjectType] غيّر الهاتف والاسم معاً.
    ActivityLogEntry phoneAndName({required int id, required String subjectType}) =>
        ActivityLogEntry(
          id: id,
          event: 'updated',
          eventLabel: 'تعديل',
          description: 'تعديل $subjectType',
          subjectType: subjectType,
          changes: const AuditChanges(
            old: {'phone': '0917775555', 'name': 'سالم'},
            attributes: {'phone': '0913334444', 'name': 'سالم علي'},
          ),
          attributeLabels: const {'phone': 'رقم الهاتف', 'name': 'الاسم'},
          createdAt: DateTime(2026, 1, 15, 10, 5),
        );

    Finder highlighted(String label) => find.descendant(
      of: find.byKey(const ValueKey('highlighted-field')),
      matching: find.text(label),
    );

    Future<void> pickPhone(WidgetTester tester) async {
      await tester.enterText(box(), 'هاتف');
      await tester.pumpAndSettle();
      await tester.tap(find.text('رقم الهاتف'));
      await tester.pumpAndSettle();
    }

    testWidgets('the picked field is highlighted on the card, and only it', (tester) async {
      // Arrange — the card changed two things; the search was for one of them.
      whenAskingField(null, withFields([creation()]));
      whenAskingField('customer:phone', page([phoneAndName(id: 50, subjectType: 'customer')]));
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act
      await pickPhone(tester);

      // Assert
      expect(highlighted('رقم الهاتف'), findsOneWidget);
      expect(highlighted('الاسم'), findsNothing);
    });

    testWidgets('the same column on another kind of record is not highlighted', (tester) async {
      // Arrange — «رقم الهاتف» on a shop is not the customer's phone the search named.
      whenAskingField(null, withFields([creation()]));
      whenAskingField(
        'customer:phone',
        page([
          phoneAndName(id: 51, subjectType: 'customer'),
          phoneAndName(id: 52, subjectType: 'customer_shop'),
        ]),
      );
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act
      await pickPhone(tester);

      // Assert — two cards carry the label, one line is lit.
      expect(find.text('رقم الهاتف'), findsNWidgets(2));
      expect(find.byKey(const ValueKey('highlighted-field')), findsOneWidget);
    });

    testWidgets('a closed deletion still shows the picked field', (tester) async {
      // Arrange — a deletion hides its values behind a button; the one searched for is the
      // reason the card is on screen at all, so it cannot be one of the hidden ones.
      whenAskingField(null, withFields([creation()]));
      whenAskingField(
        'customer:phone',
        page([
          ActivityLogEntry(
            id: 53,
            event: 'deleted',
            eventLabel: 'حذف',
            description: 'تم حذف عميل',
            subjectType: 'customer',
            changes: const AuditChanges(old: {'name': 'سالم', 'phone': '0917775555'}),
            attributeLabels: const {'phone': 'رقم الهاتف', 'name': 'الاسم'},
            createdAt: DateTime(2026, 1, 15, 9),
          ),
        ]),
      );
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act
      await pickPhone(tester);

      // Assert — the phone shows and is lit; the name waits behind the button as before.
      expect(highlighted('رقم الهاتف'), findsOneWidget);
      expect(find.text('الاسم'), findsNothing);
      expect(find.text('عرض الحقول (2)'), findsOneWidget);
    });

    testWidgets('a history with nothing to search by has no box', (tester) async {
      // Arrange — an older server, or a trail with no fields at all.
      whenAskingField(null, page([creation()]));

      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const ValueKey('field-search')), findsNothing);
    });
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
    // Arrange — `2026-01-15T08:30:00+00:00` is a full line of ISO inside a two-line box, and
    // «15 يناير 2026» is what somebody would say out loud.
    whenAsking(null, page([statusChange()]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — formatted on the device, because only the device knows its time zone.
    expect(find.textContaining('T08:30:00'), findsNothing);
    expect(find.textContaining('15 يناير 2026'), findsWidgets);
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
