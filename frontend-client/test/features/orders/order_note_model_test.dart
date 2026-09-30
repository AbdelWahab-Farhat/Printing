import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/models/order_note.dart';
import 'package:flutter_test/flutter_test.dart';

/// ملاحظةٌ على الطلبية كما يرسلها `GET client/orders/{id}/notes`، وعدّاد ما لم يُقرأ منها في
/// الطلبية المفتوحة.
///
/// Arrange - Act - Assert throughout.
void main() {
  test('a note reads its stage, its words and when they were written', () {
    // Arrange
    final json = <String, dynamic>{
      'id': 41,
      'stage': 'rejected',
      'stage_label': 'مرفوضة',
      'text': 'التصميم غير واضح',
      'written_at': '2026-09-25T14:51:00+02:00',
    };

    // Act
    final note = OrderNote.fromJson(json);

    // Assert
    expect(note.id, 41);
    expect(note.stage, OrderStage.rejected);
    expect(note.stageLabel, 'مرفوضة');
    expect(note.text, 'التصميم غير واضح');
    expect(note.writtenAt, DateTime.parse('2026-09-25T14:51:00+02:00'));
  });

  test('a stage this build has not heard of reads as unknown, with the server’s word', () {
    // Arrange
    final json = <String, dynamic>{
      'id': 42,
      'stage': 'on_hold',
      'stage_label': 'معلّقة',
      'text': 'ننتظر ردّك',
      'written_at': null,
    };

    // Act
    final note = OrderNote.fromJson(json);

    // Assert
    expect(note.stage, OrderStage.unknown);
    expect(note.stageLabel, 'معلّقة');
    expect(note.writtenAt, isNull);
  });

  test('an opened order carries how many notes are still unread', () {
    // Arrange
    final json = <String, dynamic>{
      'id': 1309,
      'code': '1309',
      'stage': 'under_review',
      'stage_label': 'بانتظار المراجعة',
      'unread_notes_count': 2,
    };

    // Act
    final order = CustomerOrderDetail.fromJson(json);

    // Assert
    expect(order.unreadNotesCount, 2);
  });

  /// خادمٌ أقدم لا يرسل العدّاد: لا شارة، لا خطأ.
  test('an older server that sends no count reads as nothing unread', () {
    // Arrange
    final json = <String, dynamic>{
      'id': 1309,
      'code': '1309',
      'stage': 'under_review',
      'stage_label': 'بانتظار المراجعة',
    };

    // Act
    final order = CustomerOrderDetail.fromJson(json);

    // Assert
    expect(order.unreadNotesCount, 0);
  });
}
