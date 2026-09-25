import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:flutter_test/flutter_test.dart';

/// ما تقوله الرسالة عن نفسها: نصّها أو ملفّها، وهل قرأها المحل.
///
/// Arrange - Act - Assert في كل حالة.
void main() {
  group('قراءة الرسالة من الخادم', () {
    test('رسالةٌ هي ملفٌّ بلا تعليق تصل بنصٍّ فارغ، لا بخطأ', () {
      // Arrange
      final json = <String, dynamic>{
        'id': 4,
        'from': 'me',
        'body': null,
        'attachment': {
          'kind': 'image',
          'kind_label': 'صورة',
          'name': 'receipt.jpg',
          'mime_type': 'image/jpeg',
          'size_bytes': 245760,
          'width_px': 800,
          'height_px': 600,
          'url': 'https://api.example/storage/x?signature=y',
        },
        'client_token': 'abc',
        'sent_at': '2026-09-25T10:00:00+00:00',
      };

      // Act
      final message = TicketMessage.fromJson(json);

      // Assert
      expect(message.body, '');
      expect(message.hasText, isFalse);
      expect(message.attachment?.kind, AttachmentKind.image);
      expect(message.attachment?.aspectRatio, closeTo(800 / 600, 0.0001));
      expect(message.clientToken, 'abc');
    });

    test('صنفُ ملفٍّ لا يعرفه هذا البناء لا يكسر المحادثة', () {
      // Arrange
      final json = <String, dynamic>{
        'id': 5,
        'from': 'support',
        'body': 'انظر المرفق',
        'attachment': {'kind': 'video', 'name': 'clip.mp4'},
      };

      // Act
      final message = TicketMessage.fromJson(json);

      // Assert
      expect(message.attachment?.kind, AttachmentKind.unknown);
    });

    test('تذكرةٌ لم يفتحها المحل بعد تصل بلا حدّ قراءة', () {
      // Arrange
      final json = <String, dynamic>{
        'id': 1,
        'subject': 'سؤال',
        'status': 'open',
        'status_label': 'مفتوحة',
        'support_read_up_to': null,
      };

      // Act
      final ticket = SupportTicket.fromJson(json);

      // Assert
      expect(ticket.supportReadUpTo, isNull);
    });
  });

  group('سطر المعاينة', () {
    test('نصُّ الرسالة حين يكون لها نص', () {
      // Arrange
      const message = TicketMessage(id: 1, from: MessageAuthor.me, body: 'هل وصلت؟');

      // Act
      final preview = message.previewText;

      // Assert
      expect(preview, 'هل وصلت؟');
    });

    test('«صورة» لصورةٍ بلا تعليق', () {
      // Arrange
      const message = TicketMessage(
        id: 1,
        attachment: TicketAttachment(kind: AttachmentKind.image, name: 'IMG_2231.jpg'),
      );

      // Act
      final preview = message.previewText;

      // Assert
      expect(preview, 'صورة');
    });

    test('اسمُ الملف لـPDF بلا تعليق — هو ما يبحث عنه صاحبه', () {
      // Arrange
      const message = TicketMessage(
        id: 1,
        attachment: TicketAttachment(kind: AttachmentKind.pdf, name: 'quote.pdf'),
      );

      // Act
      final preview = message.previewText;

      // Assert
      expect(preview, 'quote.pdf');
    });
  });

  group('علامة القراءة', () {
    const mine = TicketMessage(id: 10, from: MessageAuthor.me, body: 'سؤال');
    const later = TicketMessage(id: 12, from: MessageAuthor.me, body: 'وسؤالٌ آخر');
    const theirs = TicketMessage(id: 11, from: MessageAuthor.support, body: 'جواب');

    SupportTicket ticketReadUpTo(int? id) => SupportTicket(
      id: 1,
      subject: 'سؤال',
      statusLabel: 'مفتوحة',
      supportReadUpTo: id,
    );

    test('رسالتي مقروءةٌ حين لا يتجاوز رقمُها حدَّ المحل', () {
      // Arrange
      final ticket = ticketReadUpTo(11);

      // Act
      final read = ticket.isReadBySupport(mine);

      // Assert
      expect(read, isTrue);
    });

    test('ورسالتي بعد الحدّ لم تُقرأ بعد', () {
      // Arrange
      final ticket = ticketReadUpTo(11);

      // Act
      final read = ticket.isReadBySupport(later);

      // Assert
      expect(read, isFalse);
    });

    test('ولا شيء مقروءٌ قبل أن يفتح المحل الخيط', () {
      // Arrange
      final ticket = ticketReadUpTo(null);

      // Act
      final read = ticket.isReadBySupport(mine);

      // Assert
      expect(read, isFalse);
    });

    test('ورسائل الدعم لا علامة عليها', () {
      // Arrange
      final ticket = ticketReadUpTo(20);

      // Act
      final read = ticket.isReadBySupport(theirs);

      // Assert
      expect(read, isFalse);
    });
  });

  group('سطر الملف', () {
    test('«PDF · 1.2 م.ب» — مقرَّباً كما يقرّب مدير الملفات', () {
      // Arrange
      const attachment = TicketAttachment(
        kind: AttachmentKind.pdf,
        kindLabel: 'PDF',
        sizeBytes: 1258291,
      );

      // Act
      final line = attachment.metaLine;

      // Assert
      expect(line, 'PDF · 1.2 م.ب');
    });

    test('بالكيلوبايت تحت الميجابايت', () {
      // Arrange
      const attachment = TicketAttachment(kindLabel: 'PDF', sizeBytes: 245760);

      // Act
      final line = attachment.metaLine;

      // Assert
      expect(line, 'PDF · 240 ك.ب');
    });
  });
}
