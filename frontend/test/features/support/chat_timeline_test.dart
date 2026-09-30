import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/presentation/viewmodel/chat_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

/// كيف تُرصف المحادثة على شاشة الموظف: يومٌ يُقال مرّةً فوق رسائله، ورسائلُ المتكلّم الواحد
/// المتتابعة سلسلةٌ واحدة بذيلٍ تحت آخرها — كما في تيليغرام.
///
/// **والمتكلّم في جهة المحل شخصٌ لا جهة**: زميلان يردّان متتابعَين سلسلتان، لكلٍّ اسمُه فوقها.
///
/// Arrange - Act - Assert في كل حالة.
void main() {
  final morning = DateTime(2026, 9, 24, 9, 0);

  TicketMessage message(int id, MessageAuthor from, DateTime at, {String? author}) =>
      TicketMessage(id: id, from: from, authorName: author, body: 'رسالة $id', sentAt: at);

  group('الأيام', () {
    test('يومٌ واحد يُقال مرّةً فوق رسائله', () {
      // Arrange
      final messages = [
        message(1, MessageAuthor.customer, morning),
        message(2, MessageAuthor.staff, morning.add(const Duration(minutes: 3)), author: 'محمد'),
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
        message(1, MessageAuthor.customer, morning),
        message(2, MessageAuthor.customer, morning.add(const Duration(days: 1))),
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
    test('رسائل المتكلّم الواحد المتتابعة سلسلةٌ بذيلٍ تحت آخرها', () {
      // Arrange
      final messages = [
        message(1, MessageAuthor.customer, morning),
        message(2, MessageAuthor.customer, morning.add(const Duration(minutes: 1))),
        message(3, MessageAuthor.customer, morning.add(const Duration(minutes: 2))),
      ];

      // Act
      final entries = chatTimeline(messages: messages).whereType<ChatEntry>().toList();

      // Assert
      expect([for (final e in entries) e.startsRun], [true, false, false]);
      expect([for (final e in entries) e.endsRun], [false, false, true]);
    });

    test('تبدّلُ الجهة يقطع السلسلة', () {
      // Arrange
      final messages = [
        message(1, MessageAuthor.customer, morning),
        message(2, MessageAuthor.staff, morning.add(const Duration(minutes: 1)), author: 'محمد'),
      ];

      // Act
      final entries = chatTimeline(messages: messages).whereType<ChatEntry>().toList();

      // Assert
      expect(entries.every((e) => e.startsRun && e.endsRun), isTrue);
    });

    test('وزميلٌ آخر يردّ بعد زميله سلسلةٌ جديدة، لأن الاسم فوقها يتغيّر', () {
      // Arrange
      final messages = [
        message(1, MessageAuthor.staff, morning, author: 'محمد'),
        message(2, MessageAuthor.staff, morning.add(const Duration(minutes: 1)), author: 'فرحات'),
      ];

      // Act
      final entries = chatTimeline(messages: messages).whereType<ChatEntry>().toList();

      // Assert
      expect(entries.every((e) => e.startsRun && e.endsRun), isTrue);
    });

    test('وصمتٌ طويل يقطعها وإن كان المتكلّم واحداً', () {
      // Arrange
      final messages = [
        message(1, MessageAuthor.customer, morning),
        message(2, MessageAuthor.customer, morning.add(const Duration(minutes: 30))),
      ];

      // Act
      final entries = chatTimeline(messages: messages).whereType<ChatEntry>().toList();

      // Assert
      expect(entries.every((e) => e.startsRun && e.endsRun), isTrue);
    });
  });

  test('التذكرة المغلقة تُختم بسطرٍ يقول ذلك', () {
    // Arrange
    final messages = [message(1, MessageAuthor.customer, morning)];

    // Act
    final items = chatTimeline(messages: messages, isClosed: true);

    // Assert
    expect(items.last, isA<ChatNotice>());
    expect((items.last as ChatNotice).label, 'أُغلقت التذكرة');
  });
}
