import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:flutter_test/flutter_test.dart';

/// Decoding a thread the way `SupportTicketResource` actually sends one.
///
/// **The payloads here are copied from the resource, not invented.** A model test that feeds
/// itself a shape the server never sends proves the model agrees with the test author, which is
/// the one party whose agreement is free.
///
/// The properties worth stating are the ones a compiler cannot: that an unrecognised word does
/// not crash the queue, that `assigned_to` and `assignee` can disagree without either being
/// wrong, and that a list endpoint's ticket — which carries no messages at all — decodes to an
/// empty thread rather than a null one the screen would have to guard.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// A thread as `show` returns it: loaded relations, two messages, on somebody's desk.
  Map<String, dynamic> full() => <String, dynamic>{
    'id': 12,
    'subject': 'أين طلبيتي؟',
    'status': 'in_progress',
    'status_label': 'قيد المعالجة',
    'customer': {'id': 4, 'code': 'A-1001', 'name': 'سالم', 'phone': '0910000000'},
    'order': {'id': 77, 'code': '77'},
    'assigned_to': 9,
    'assignee': {'id': 9, 'name': 'محمد'},
    'unread_count': 2,
    'messages': [
      {
        'id': 1,
        'from': 'customer',
        'author_name': null,
        'body': 'مرّ أسبوع',
        'sent_at': '2026-09-15T10:00:00+00:00',
      },
      {
        'id': 2,
        'from': 'staff',
        'author_name': 'محمد',
        'body': 'نعتذر، خرجت اليوم',
        'sent_at': '2026-09-16T08:30:00+00:00',
      },
    ],
    'last_message_at': '2026-09-16T08:30:00+00:00',
    'closed_at': null,
    'created_at': '2026-09-15T09:55:00+00:00',
  };

  group('a thread as the desk receives it', () {
    test('decodes every field the resource sends', () {
      // Arrange
      final json = full();

      // Act
      final ticket = SupportTicket.fromJson(json);

      // Assert
      expect(ticket.id, 12);
      expect(ticket.subject, 'أين طلبيتي؟');
      expect(ticket.status, TicketStatus.inProgress);
      expect(ticket.statusLabel, 'قيد المعالجة');
      expect(ticket.unreadCount, 2);
      expect(ticket.customer?.phone, '0910000000');
      expect(ticket.order?.code, '77');
      expect(ticket.assignee?.name, 'محمد');
      expect(ticket.lastMessageAt, DateTime.parse('2026-09-16T08:30:00+00:00'));
      expect(ticket.closedAt, isNull);
    });

    test('keeps who said what, and only names the shop side', () {
      // Arrange
      final json = full();

      // Act
      final messages = SupportTicket.fromJson(json).messages;

      // Assert — the customer's own line carries no name, because the resource sends none. A
      // model that invented one would put a name on a message nobody signed.
      expect(messages, hasLength(2));
      expect(messages.first.from, MessageAuthor.customer);
      expect(messages.first.authorName, isNull);
      expect(messages.last.from, MessageAuthor.staff);
      expect(messages.last.authorName, 'محمد');
    });
  });

  group('what the queue endpoint leaves out', () {
    test('a ticket with no messages key decodes to an empty thread, not a null one', () {
      // Arrange — `index` does not load `messages`, so `whenLoaded` omits the key entirely.
      final json = full()..remove('messages');

      // Act
      final ticket = SupportTicket.fromJson(json);

      // Assert — the card reads `messages` without a guard; a null here would be a crash on
      // the list screen rather than on the thread.
      expect(ticket.messages, isEmpty);
    });

    test('an unassigned, unread-free ticket decodes without either key', () {
      // Arrange
      final json = full()
        ..remove('assignee')
        ..remove('unread_count')
        ..['assigned_to'] = null;

      // Act
      final ticket = SupportTicket.fromJson(json);

      // Assert — «غير مُسندة» on the card is this being null, and the badge is this being 0.
      expect(ticket.assignee, isNull);
      expect(ticket.assignedTo, isNull);
      expect(ticket.unreadCount, 0);
    });
  });

  group('words this build has not heard of', () {
    test('an unknown status decodes to unknown rather than throwing', () {
      // Arrange — a fourth status added to the business after this build shipped.
      final json = full()
        ..['status'] = 'escalated'
        ..['status_label'] = 'مُصعّدة';

      // Act
      final ticket = SupportTicket.fromJson(json);

      // Assert — the queue must still draw. It shows the server's Arabic, which is exactly why
      // `status_label` travels with the row instead of being translated here.
      expect(ticket.status, TicketStatus.unknown);
      expect(ticket.statusLabel, 'مُصعّدة');
    });

    test('an unknown status is still treated as open to replies', () {
      // Arrange
      final json = full()..['status'] = 'escalated';

      // Act
      final ticket = SupportTicket.fromJson(json);

      // Assert — `isClosed` asks for one specific value rather than "not one I know", so a
      // status nobody here recognises leaves the composer up. Hiding it would silence the desk
      // on every ticket the moment the business adds a word.
      expect(ticket.status.isClosed, isFalse);
      expect(ticket.status.acceptsReplies, isTrue);
    });

    test('an unknown author is drawn as the shop, never as the customer', () {
      // Arrange
      final json = full();
      final messages = json['messages']! as List<dynamic>;
      (messages.first as Map<String, dynamic>)['from'] = 'system';

      // Act
      final message = SupportTicket.fromJson(json).messages.first;

      // Assert — the safe reading, and the model says so: attributing a message to the customer
      // that was not theirs is the worse of the two mistakes.
      expect(message.from, MessageAuthor.unknown);
      expect(message.from, isNot(MessageAuthor.customer));
    });
  });
}
