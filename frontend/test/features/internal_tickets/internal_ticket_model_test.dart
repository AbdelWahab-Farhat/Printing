import 'package:dayaa/core/chat/chat_message.dart';
import 'package:dayaa/core/chat/chat_thread_timeline.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket_query.dart';
import 'package:flutter_test/flutter_test.dart';

/// النماذج كما يرسلها الخادم (INTERNAL-TICKETS-DESIGN §٥)، والسؤال كما يُرسل، والمحادثةُ مرصوفة.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// تذكرةٌ كما يرسلها `GET internal-tickets/{id}` لسالم، صاحبِها.
  Map<String, dynamic> serverTicket() => {
    'id': 3,
    'code': 'T3',
    'title': 'الطلبية متأخرة',
    'status': 'in_progress',
    'status_label': 'قيد المعالجة',
    'priority': 'high',
    'priority_label': 'عالية',
    'category': {'id': 1, 'name': 'طلبية'},
    'opener': {'id': 7, 'name': 'سالم'},
    'assignee': {'id': 9, 'name': 'هدى'},
    'counterpart': {'id': 9, 'name': 'هدى'},
    'i_opened_it': true,
    'is_party': true,
    'customer': null,
    'order': {'id': 55, 'code': 'O55'},
    'unread_count': 1,
    'counterpart_read_up_to': 1,
    'read_up_to': {'opener': 2, 'assignee': 1},
    'awaiting_my_reply': true,
    'last_message': {
      'id': 2,
      'author_id': 9,
      'author_name': 'هدى',
      'preview': '🎤 رسالة صوتية',
      'kind': 'voice',
      'duration_seconds': 42,
      'sent_at': '2026-10-21T10:00:00+03:00',
    },
    'messages': [
      {
        'id': 1,
        'ticket_id': 3,
        'author': {'id': 7, 'name': 'سالم'},
        'is_mine': true,
        'body': 'هل وصلت؟',
        'is_deleted': false,
        'is_edited': true,
        'reply_to': null,
        'attachments': <Object>[],
        'client_token': null,
        'sent_at': '2026-10-21T09:00:00+03:00',
        'can_edit': true,
        'can_delete': true,
        'mutation_block_reason': null,
        'mutable_until': '2026-10-21T09:20:00+03:00',
      },
      {
        'id': 2,
        'ticket_id': 3,
        'author': {'id': 9, 'name': 'هدى'},
        'is_mine': false,
        'body': null,
        'is_deleted': false,
        'is_edited': false,
        'reply_to': {'id': 1, 'author_name': 'سالم', 'preview': 'هل وصلت؟', 'is_deleted': false},
        'attachments': [
          {
            'id': 44,
            'kind': 'voice',
            'kind_label': 'رسالة صوتية',
            'name': 'voice.m4a',
            'mime_type': 'audio/mp4',
            'size_bytes': 24000,
            'width_px': null,
            'height_px': null,
            'duration_seconds': 42,
            'waveform': [10, 50, 90],
            'url': 'https://example.test/a44',
          },
        ],
        'sent_at': '2026-10-21T10:00:00+03:00',
        'can_edit': false,
        'can_delete': false,
        'mutation_block_reason': 'هذه الرسالة ليست لك',
      },
    ],
    'can_reply': true,
    'can_close': true,
    'can_transfer': true,
    'last_message_at': '2026-10-21T10:00:00+03:00',
    'closed_at': null,
    'created_at': '2026-10-21T09:00:00+03:00',
  };

  test('a ticket reads as the server writes it', () {
    // Act
    final ticket = InternalTicket.fromJson(serverTicket());

    // Assert
    expect(ticket.status, InternalTicketStatus.inProgress);
    expect(ticket.priority, InternalTicketPriority.high);
    expect(ticket.counterpart?.name, 'هدى');
    expect(ticket.order?.code, 'O55');
    expect(ticket.lastMessage?.kind, 'voice');
    expect(ticket.messages.first.isEdited, isTrue);
    expect(ticket.messages.last.replyTo?.preview, 'هل وصلت؟');
    expect(ticket.messages.last.voice?.durationSeconds, 42);
    expect(ticket.messages.last.voice?.waveform, [10, 50, 90]);
    expect(ticket.messages.last.mutationBlockReason, 'هذه الرسالة ليست لك');
  });

  test('a status or kind this build has not heard of does not drop the ticket', () {
    // Arrange
    final json = serverTicket()
      ..['status'] = 'archived'
      ..['priority'] = 'urgent';
    final voiceMessage = (json['messages'] as List<dynamic>).last as Map<String, dynamic>;
    final attachments = voiceMessage['attachments'] as List<dynamic>;
    (attachments.single as Map<String, dynamic>)['kind'] = 'video';

    // Act
    final ticket = InternalTicket.fromJson(json);

    // Assert
    expect(ticket.status, InternalTicketStatus.unknown);
    expect(ticket.priority, InternalTicketPriority.unknown);
    expect(ticket.messages.last.attachments.single.kind, ChatAttachmentKind.unknown);
  });

  test('a broadcast ticket — no reader — still knows who read up to where', () {
    // Arrange — كما يبثّها الخادم: بلا طرفٍ آخر ولا حدٍّ محسوب.
    final json = serverTicket()
      ..['counterpart'] = null
      ..['counterpart_read_up_to'] = null;

    // Act
    final ticket = InternalTicket.fromJson(json);

    // Assert
    expect(ticket.readByOtherSideUpTo(7), 1);
    expect(ticket.readByOtherSideUpTo(9), 2);
    expect(ticket.otherSideOf(9)?.name, 'سالم');
    expect(ticket.otherSideOf(100), isNull);
  });

  test('«my» message is mine by the flag or, in a broadcast, by its author', () {
    // Arrange
    const echo = ChatMessage(id: 1, author: ChatPerson(id: 7, name: 'سالم'));

    // Assert
    expect(echo.isFrom(7), isTrue);
    expect(echo.isFrom(9), isFalse);
  });

  test('the query sends what is asked and drops what is not', () {
    // Arrange
    const query = InternalTicketQuery(
      allTickets: true,
      status: InternalTicketStatus.closed,
      unreadOnly: true,
      orderId: 55,
      oldestFirst: true,
    );

    // Act
    final sent = query.toQuery(search: 'T', page: 2);

    // Assert
    expect(sent, {
      'page': 2,
      'scope': 'all',
      'status': 'closed',
      'search': 'T',
      'unread': 1,
      'order_id': 55,
      'sort': 'oldest_activity',
    });
    expect(const InternalTicketQuery().toQuery(page: 1), {'page': 1, 'status': 'in_progress'});
  });

  test('a list opened from an order is titled by it', () {
    // Assert
    expect(const InternalTicketSubject(orderId: 5, orderCode: 'O5').listTitle, 'تذاكر الطلبية O5');
    expect(
      const InternalTicketSubject(customerId: 2, customerName: 'متجر الأمل').listTitle,
      'تذاكر الموظفين عن متجر الأمل',
    );
  });

  group('the conversation laid out', () {
    ChatMessage said(int id, int author, DateTime at) => ChatMessage(
      id: id,
      author: ChatPerson(id: author, name: 'م$author'),
      sentAt: at,
    );

    test('one person speaking twice in a row is one run; the colleague starts another', () {
      // Arrange
      final morning = DateTime(2026, 10, 21, 9);
      final messages = [
        said(1, 7, morning),
        said(2, 7, morning.add(const Duration(minutes: 1))),
        said(3, 9, morning.add(const Duration(minutes: 2))),
      ];

      // Act
      final items = chatThreadTimeline(messages: messages);

      // Assert
      final entries = items.whereType<ChatThreadEntry>().toList();
      expect(items.first, isA<ChatThreadDay>());
      expect(
        [for (final e in entries) (e.startsRun, e.endsRun)],
        [(true, false), (false, true), (true, true)],
      );
    });

    test('a closed ticket ends with its closing line', () {
      // Act
      final items = chatThreadTimeline(
        messages: [said(1, 7, DateTime(2026, 10, 21, 9))],
        closedNotice: 'أُغلقت التذكرة',
      );

      // Assert
      expect((items.last as ChatThreadNotice).label, 'أُغلقت التذكرة');
    });
  });
}
