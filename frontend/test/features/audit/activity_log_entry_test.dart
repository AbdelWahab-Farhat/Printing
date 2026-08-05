import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/audit/models/activity_log_entry.dart';
import 'package:printing/features/audit/models/audit_event.dart';

/// The seam between `ActivityLogResource` and the history screen.
///
/// Arrange - Act - Assert throughout.
void main() {
  test('parses an edit, both halves of it', () {
    // Arrange — the `data` block of GET /customers/7/logs.
    final json = <String, dynamic>{
      'id': 41,
      'event': 'updated',
      'event_label': 'تعديل',
      'description': 'تم تعديل عميل',
      'subject_type': 'customer',
      'subject_type_label': 'عميل',
      'subject_id': 7,
      'causer': {'id': 1, 'name': 'المدير'},
      'changes': {
        'old': {'phone': '0917775555'},
        'attributes': {'phone': '0913334444'},
      },
      'attribute_labels': {'phone': 'رقم الهاتف'},
      'created_at': '2026-08-02T09:15:00+00:00',
    };

    // Act
    final entry = ActivityLogEntry.fromJson(json);

    // Assert
    expect(entry.kind, AuditEvent.updated);
    expect(entry.byWhom, 'المدير');
    expect(entry.changes!.isMovement, isTrue);
    expect(entry.changes!.fields, [('phone', '0917775555', '0913334444')]);
    expect(entry.labelFor('phone'), 'رقم الهاتف');
  });

  test('a column the server has no label for keeps its own name', () {
    // Arrange — the fallback is the whole reason the dictionary lives on the server. A column
    // added tomorrow is unlabelled everywhere at once, which is what gets it labelled; a guess
    // made here would look right and be wrong.
    final entry = ActivityLogEntry.fromJson(<String, dynamic>{
      'id': 1,
      'event': 'updated',
      'attribute_labels': {'phone': 'رقم الهاتف'},
    });

    // Act & Assert
    expect(entry.labelFor('phone'), 'رقم الهاتف');
    expect(entry.labelFor('some_new_column'), 'some_new_column');
  });

  test('an entry with no labels at all still renders its columns', () {
    // Arrange — an older server, or a build of it without the dictionary.
    final entry = ActivityLogEntry.fromJson(<String, dynamic>{'id': 1, 'event': 'created'});

    // Act & Assert
    expect(entry.attributeLabels, isNull);
    expect(entry.labelFor('page_url'), 'page_url');
  });

  test('a creation states its values and is not a movement', () {
    // Arrange — there is no "from" here, and an arrow drawn on a creation would invent a value
    // that never existed.
    final entry = ActivityLogEntry.fromJson(<String, dynamic>{
      'id': 2,
      'event': 'created',
      'changes': {
        'old': null,
        'attributes': {'name': 'مطبعة النور', 'is_active': true},
      },
    });

    // Act
    final changes = entry.changes!;

    // Assert
    expect(entry.isCreation, isTrue);
    expect(changes.isMovement, isFalse);
    expect(changes.statedValues, [('name', 'مطبعة النور'), ('is_active', true)]);
  });

  test('a deletion restates what the record last was', () {
    // Arrange — the row is gone from every list, so this entry is the only place those values
    // still exist. `fields` is driven by `attributes` and would be empty here, which is exactly
    // the case that used to render a card with nothing under its heading.
    final entry = ActivityLogEntry.fromJson(<String, dynamic>{
      'id': 3,
      'event': 'deleted',
      'changes': {
        'old': {'name': 'فرع سوق الجمعة'},
        'attributes': null,
      },
    });

    // Act
    final changes = entry.changes!;

    // Assert
    expect(changes.isMovement, isFalse);
    expect(changes.fields, isEmpty);
    expect(changes.statedValues, [('name', 'فرع سوق الجمعة')]);
  });

  test('an entry that moved nothing says so, rather than drawing an empty box', () {
    // Arrange
    final entry = ActivityLogEntry.fromJson(<String, dynamic>{
      'id': 4,
      'event': 'restored',
      'changes': {'old': null, 'attributes': null},
    });

    // Act & Assert
    expect(entry.changes!.isEmpty, isTrue);
  });

  test('an event this build has never heard of is inert, not a crash', () {
    // Arrange — the server may learn a fifth event, and an app already on a phone has to keep
    // listing the other four.
    final entry = ActivityLogEntry.fromJson(<String, dynamic>{
      'id': 5,
      'event': 'archived',
      'event_label': 'أرشفة',
    });

    // Act & Assert — no case for it, and the server's own word still names it on screen.
    expect(entry.kind, isNull);
    expect(entry.eventLabel, 'أرشفة');
  });

  test('a change nobody signed in made is named, not left blank', () {
    // Arrange — a seeder, a console command, a queued job.
    final entry = ActivityLogEntry.fromJson(<String, dynamic>{'id': 6, 'event': 'created'});

    // Act & Assert
    expect(entry.byWhom, 'النظام');
  });
}
