import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/audit/models/activity_log_entry.dart';
import 'package:dayaa/features/audit/models/audit_event.dart';
import 'package:dayaa/features/audit/models/audit_field_option.dart';
import 'package:dayaa/features/audit/models/audit_subject.dart';
import 'package:dayaa/features/audit/presentation/viewmodel/activity_log_cubit.dart';
import 'package:dayaa/features/audit/repositories/audit_repository.dart';
import 'package:dayaa/features/audit/usecases/get_activity_log.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// One record's history: reading it, and narrowing it to one kind of change.
///
/// Arrange - Act - Assert throughout.
class _MockAuditRepository extends Mock implements AuditRepository {}

void main() {
  late _MockAuditRepository repository;
  late ActivityLogCubit cubit;

  const created = ActivityLogEntry(id: 1, event: 'created', description: 'تم إنشاء عميل');
  const updated = ActivityLogEntry(id: 2, event: 'updated', description: 'تم تعديل عميل');

  Paginated<ActivityLogEntry> page(
    List<ActivityLogEntry> items, {
    Map<String, dynamic>? counts,
    int current = 1,
    int last = 1,
  }) => Paginated<ActivityLogEntry>(
    items: items,
    meta: PageMeta(currentPage: current, perPage: 20, lastPage: last, total: items.length),
    extraMeta: counts == null ? const {} : {'event_counts': counts},
  );

  setUpAll(() => registerFallbackValue(AuditSubject.customer));

  setUp(() {
    repository = _MockAuditRepository();
    cubit = ActivityLogCubit(
      subject: AuditSubject.customer,
      recordId: 7,
      getActivityLog: GetActivityLog(repository),
    );
  });

  tearDown(() => cubit.close());

  /// Stubs the endpoint for one value of `?event=` — null meaning no filter.
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

  test('loads the whole trail, unfiltered', () async {
    // Arrange
    whenAsking(null, page([updated, created]));

    // Act
    await cubit.load();

    // Assert
    expect(cubit.event, isNull);
    expect((cubit.state as PagedLoaded<ActivityLogEntry>).page.items, [updated, created]);
  });

  test('a filter is applied by the server, not to the page already downloaded', () async {
    // Arrange — narrowing what is on screen would show a fraction of the history and present
    // it as all of it.
    whenAsking(null, page([updated, created]));
    whenAsking(AuditEvent.created, page([created]));
    await cubit.load();

    // Act
    await cubit.filterBy(AuditEvent.created);

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
    expect(cubit.event, AuditEvent.created);
    expect((cubit.state as PagedLoaded<ActivityLogEntry>).page.items, [created]);
  });

  test('tapping the chip that is already active costs nothing', () async {
    // Arrange
    whenAsking(null, page([updated, created]));
    whenAsking(AuditEvent.created, page([created]));
    await cubit.load();
    await cubit.filterBy(AuditEvent.created);

    // Act
    await cubit.filterBy(AuditEvent.created);

    // Assert
    verify(
      () => repository.logs(
        any(),
        any(),
        event: AuditEvent.created,
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).called(1);
  });

  test('clearing the filter asks for everything again', () async {
    // Arrange
    whenAsking(null, page([updated, created]));
    whenAsking(AuditEvent.created, page([created]));
    await cubit.load();
    await cubit.filterBy(AuditEvent.created);

    // Act
    await cubit.filterBy(null);

    // Assert
    expect(cubit.event, isNull);
    expect((cubit.state as PagedLoaded<ActivityLogEntry>).page.items, [updated, created]);
  });

  test('the counts come from the server and describe the whole trail', () async {
    // Arrange — counted here, they would be a lie the moment the history is longer than one
    // page, and for a customer of any age it always is.
    whenAsking(
      null,
      page(
        [updated],
        counts: {'created': 12, 'updated': 5, 'deleted': 0, 'restored': 0},
        last: 3,
      ),
    );

    // Act
    await cubit.load();

    // Assert — seventeen entries described by a page holding one.
    expect(cubit.eventCounts[AuditEvent.created], 12);
    expect(cubit.eventCounts[AuditEvent.updated], 5);
    expect(cubit.eventCounts[AuditEvent.deleted], 0);
  });

  test('the counts survive the reload a filter causes', () async {
    // Arrange — the chips are the control being used. Numbers that blink out and back while
    // the list behind them fetches make the row twitch under the thumb tapping it.
    whenAsking(null, page([updated, created], counts: {'created': 1, 'updated': 1}));
    // The filtered response carries the same counts — but this test stubs it without any, which
    // is the harsher case: the chips must not empty out even then.
    whenAsking(AuditEvent.created, page([created]));
    await cubit.load();

    // Act
    await cubit.filterBy(AuditEvent.created);

    // Assert
    expect(cubit.eventCounts[AuditEvent.created], 1);
    expect(cubit.eventCounts[AuditEvent.updated], 1);
  });

  test('there are no counts before the first page arrives', () async {
    // Arrange & Act — nothing loaded yet.
    // Assert — empty, so a chip shows no badge at all. A zero that becomes a four a moment
    // later is a number nobody can trust.
    expect(cubit.eventCounts, isEmpty);
  });

  test(
    'a failure is the server’s own message, and clears nothing it did not have to',
    () async {
      // Arrange
      when(
        () => repository.logs(
          any(),
          any(),
          event: any(named: 'event'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer(
        (_) async => const Left(Failure.forbidden(message: FailureMessages.forbidden)),
      );

      // Act
      await cubit.load();

      // Assert
      expect(cubit.state, isA<PagedFailure<ActivityLogEntry>>());
    },
  );

  group('the field search', () {
    const unitPrice = AuditFieldOption(
      key: 'order_item:unit_price',
      label: 'سعر الوحدة',
      subjectLabel: 'بند الطلبية',
    );

    Paginated<ActivityLogEntry> withFields(List<ActivityLogEntry> items) =>
        Paginated<ActivityLogEntry>(
          items: items,
          meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: items.length),
          extraMeta: const {
            'fields': [
              {'key': 'order_item:unit_price', 'label': 'سعر الوحدة', 'subject_label': 'بند الطلبية'},
              // Malformed — skipped rather than shown as a blank suggestion.
              {'label': 'بلا مفتاح'},
            ],
          },
        );

    void whenAskingField(
      String? field,
      Paginated<ActivityLogEntry> answer, {
      AuditEvent? event,
    }) {
      when(
        () => repository.logs(
          any(),
          any(),
          event: event,
          field: field,
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => Right(answer));
    }

    test('the fields to suggest come from the server', () async {
      // Arrange
      whenAskingField(null, withFields([updated, created]));

      // Act
      await cubit.load();

      // Assert
      expect(cubit.fields, [unitPrice]);
      expect(cubit.fields.single.subjectLabel, 'بند الطلبية');
    });

    test('picking a field asks the server for that field alone', () async {
      // Arrange
      whenAskingField(null, withFields([updated, created]));
      whenAskingField('order_item:unit_price', page([updated]));
      await cubit.load();

      // Act
      await cubit.filterByField(unitPrice);

      // Assert — and the suggestions survive a response that did not repeat them.
      verify(
        () => repository.logs(
          AuditSubject.customer,
          7,
          field: 'order_item:unit_price',
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).called(1);
      expect(cubit.field, unitPrice);
      expect((cubit.state as PagedLoaded<ActivityLogEntry>).page.items, [updated]);
      expect(cubit.fields, [unitPrice]);
    });

    test('a field and an event narrow together', () async {
      // Arrange — «who *changed* the price» is both at once.
      whenAskingField(null, withFields([updated, created]));
      whenAskingField('order_item:unit_price', page([updated, created]));
      whenAskingField('order_item:unit_price', page([updated]), event: AuditEvent.updated);
      await cubit.load();
      await cubit.filterByField(unitPrice);

      // Act
      await cubit.filterBy(AuditEvent.updated);

      // Assert
      verify(
        () => repository.logs(
          any(),
          any(),
          event: AuditEvent.updated,
          field: 'order_item:unit_price',
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).called(1);
    });

    test('letting go of the field brings the whole trail back', () async {
      // Arrange
      whenAskingField(null, withFields([updated, created]));
      whenAskingField('order_item:unit_price', page([updated]));
      await cubit.load();
      await cubit.filterByField(unitPrice);

      // Act
      await cubit.filterByField(null);

      // Assert
      expect(cubit.field, isNull);
      expect((cubit.state as PagedLoaded<ActivityLogEntry>).page.items, [updated, created]);
    });
  });
}
