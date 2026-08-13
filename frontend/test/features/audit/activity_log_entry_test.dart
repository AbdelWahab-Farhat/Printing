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

  test('a value the server translated is read in arabic', () {
    // Arrange — the labels named «الحالة» and the screen went on saying `printing` beside it.
    final entry = ActivityLogEntry.fromJson(<String, dynamic>{
      'id': 10,
      'event': 'updated',
      'subject_type': 'order',
      'changes': {
        'old': {'status': 'new'},
        'attributes': {'status': 'printing'},
      },
      'attribute_labels': {'status': 'الحالة'},
      'value_labels': {
        'old': {'status': 'جديدة'},
        'attributes': {'status': 'قيد الطباعة'},
      },
    });

    // Act & Assert — both halves, because «من جديدة» is half the sentence.
    expect(entry.valueLabelFor('status', old: true), 'جديدة');
    expect(entry.valueLabelFor('status', old: false), 'قيد الطباعة');
  });

  test('a value with no translation has none invented for it', () {
    // Arrange — a name is already Arabic and a total is a number, so the server sends neither.
    final entry = ActivityLogEntry.fromJson(<String, dynamic>{
      'id': 11,
      'event': 'created',
      'subject_type': 'customer',
      'changes': {
        'attributes': {'name': 'مطبعة النور'},
      },
      'value_labels': {'old': <String, dynamic>{}, 'attributes': <String, dynamic>{}},
    });

    // Act & Assert — null, and the screen falls back to the raw value exactly as it falls back
    // to a raw column name.
    expect(entry.valueLabelFor('name', old: false), isNull);
  });

  test('an older server that sends no translations at all still renders', () {
    // Arrange — the app ships before the API does, or after somebody rolls it back.
    final entry = ActivityLogEntry.fromJson(<String, dynamic>{
      'id': 12,
      'event': 'updated',
      'changes': {
        'attributes': {'status': 'printing'},
      },
    });

    // Act & Assert
    expect(entry.valueLabels, isNull);
    expect(entry.valueLabelFor('status', old: false), isNull);
  });

  test('the permissions a role gained are read in arabic', () {
    // Arrange — the edit that reads worst: a list of `products.view` strings.
    final entry = ActivityLogEntry.fromJson(<String, dynamic>{
      'id': 13,
      'event': 'updated',
      'subject_type': 'role',
      'properties': {
        'permissions': {
          'granted': ['products.view'],
          'revoked': <String>[],
        },
      },
      'property_labels': {
        'permissions': {'products.view': 'عرض المنتجات'},
      },
    });

    // Act & Assert
    expect(entry.permissionLabelFor('products.view'), 'عرض المنتجات');
    expect(entry.permissionLabelFor('a.permission.this.build.lacks'), isNull);
  });

}
