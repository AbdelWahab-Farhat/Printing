import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/chat_timeline.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/outgoing_message.dart';
import 'package:flutter_test/flutter_test.dart';

/// كيف تُرصف المحادثة: يومٌ يُقال مرّةً فوق رسائله، ورسائلُ الطرف الواحد المتتابعة سلسلةٌ واحدة
/// بذيلٍ تحت آخرها — كما في تيليغرام.
///
/// Arrange - Act - Assert في كل حالة.
void main() {
  final morning = DateTime(2026, 9, 24, 9, 0);

  TicketMessage message(int id, MessageAuthor from, DateTime at) =>
      TicketMessage(id: id, from: from, body: 'رسالة $id', sentAt: at);

  group('الأيام', () {
    test('يومٌ واحد يُقال مرّةً فوق رسائله', () {
      // Arrange
      final messages = [
        message(1, MessageAuthor.me, morning),
        message(2, MessageAuthor.support, morning.add(const Duration(minutes: 3))),
      ];

      // Act
      final items = chatTimeline(messages: messages);

      // Assert
      expect(items.whereType<ChatDay>(), hasLength(1));
      expect(items.first, isA<ChatDay>());
    });

    test('ويومٌ جديد فاصلٌ جديد', () {
      // Arrange
      final messages = [
        message(1, MessageAuthor.me, morning),
        message(2, MessageAuthor.support, morning.add(const Duration(days: 1))),
      ];

      // Act
      final items = chatTimeline(messages: messages);

      // Assert
      expect(items.map((item) => item.runtimeType).toList(), [
        ChatDay,
        ChatEntry,
        ChatDay,
        ChatEntry,
      ]);
    });
  });

  group('السلاسل', () {
    test('رسائل الطرف الواحد المتتابعة سلسلةٌ بذيلٍ تحت آخرها', () {
      // Arrange
      final messages = [
        message(1, MessageAuthor.me, morning),
        message(2, MessageAuthor.me, morning.add(const Duration(minutes: 1))),
        message(3, MessageAuthor.me, morning.add(const Duration(minutes: 2))),
      ];

      // Act
      final entries = chatTimeline(messages: messages).whereType<ChatEntry>().toList();

      // Assert
      expect([for (final e in entries) e.startsRun], [true, false, false]);
      expect([for (final e in entries) e.endsRun], [false, false, true]);
    });

    test('تبدّلُ المتكلّم يقطع السلسلة', () {
      // Arrange
      final messages = [
        message(1, MessageAuthor.me, morning),
        message(2, MessageAuthor.support, morning.add(const Duration(minutes: 1))),
      ];

      // Act
      final entries = chatTimeline(messages: messages).whereType<ChatEntry>().toList();

      // Assert
      expect(entries.every((e) => e.startsRun && e.endsRun), isTrue);
    });

    test('وصمتٌ طويل يقطعها وإن كان المتكلّم واحداً', () {
      // Arrange
      final messages = [
        message(1, MessageAuthor.me, morning),
        message(2, MessageAuthor.me, morning.add(const Duration(minutes: 30))),
      ];

      // Act
      final entries = chatTimeline(messages: messages).whereType<ChatEntry>().toList();

      // Assert
      expect(entries.every((e) => e.startsRun && e.endsRun), isTrue);
    });
  });

  group('ما لم يُرسل بعد', () {
    test('الرسائل المعلّقة تأتي بعد المحادثة، في سلسلة رسائلي', () {
      // Arrange
      final now = DateTime.now();
      final messages = [message(1, MessageAuthor.me, now)];
      final pending = [OutgoingMessage(clientToken: 't1', body: 'قيد الإرسال', createdAt: now)];

      // Act
      final items = chatTimeline(messages: messages, pending: pending);

      // Assert
      expect(items.last, isA<ChatOutgoing>());
      final entry = items.whereType<ChatEntry>().single;
      expect(entry.endsRun, isFalse);
      expect((items.last as ChatOutgoing).endsRun, isTrue);
    });

    test('رسالةٌ معلّقة وصلت نسختها من الخادم لا تُرسم مرّتين', () {
      // Arrange — البثّ الحيّ قد يسبق ردّ الطلب نفسه.
      final now = DateTime.now();
      final messages = [
        TicketMessage(id: 9, from: MessageAuthor.me, body: 'مرحباً', clientToken: 't1', sentAt: now),
      ];
      final pending = [OutgoingMessage(clientToken: 't1', body: 'مرحباً', createdAt: now)];

      // Act
      final items = chatTimeline(messages: messages, pending: pending);

      // Assert
      expect(items.whereType<ChatOutgoing>(), isEmpty);
      expect(items.whereType<ChatEntry>(), hasLength(1));
    });
  });

  test('التذكرة المغلقة تُختم بسطرٍ يقول ذلك', () {
    // Arrange
    final messages = [message(1, MessageAuthor.support, morning)];

    // Act
    final items = chatTimeline(messages: messages, isClosed: true);

    // Assert
    expect(items.last, isA<ChatNotice>());
    expect((items.last as ChatNotice).label, 'أُغلقت التذكرة');
  });
}
