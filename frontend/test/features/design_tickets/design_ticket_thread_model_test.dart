import 'package:dayaa/core/chat/chat_message.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_thread.dart';
import 'package:flutter_test/flutter_test.dart';

/// المحادثة كما يرسلها `GET design-tickets/{id}/messages` (`DesignTicketThreadResource`)، والرسالةُ
/// بشكل رسالة التذكرة الداخلية حرفاً بحرف — فتُقرأ بـ[ChatMessage] نفسه.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// المحادثة كما يراها سالم (٧)، طالبُ التذكرة، وهدى (٩) مصمّمتُها.
  Map<String, dynamic> serverThread() => {
    'ticket': {
      'id': 3,
      'code': 'D3',
      'title': 'كيس شحن أسود',
      'status': 'in_progress',
      'status_label': 'قيد التصميم',
      'is_open': true,
      'customer_name': 'متجر إكس',
      'requester': {'id': 7, 'name': 'سالم'},
      'designer': {'id': 9, 'name': 'هدى'},
    },
    'messages': [
      {
        'id': 11,
        'ticket_id': 3,
        'author': {'id': 7, 'name': 'سالم'},
        'is_mine': true,
        'body': 'الشعار في المرفقات',
        'is_deleted': false,
        'deleted_at': null,
        'is_edited': false,
        'edited_at': null,
        'reply_to': null,
        'attachments': <Map<String, dynamic>>[],
        'client_token': 'tok-1',
        'sent_at': '2026-10-24T09:00:00+02:00',
        'can_edit': true,
        'can_delete': true,
        'mutation_block_reason': null,
        'mutable_until': '2026-10-24T09:20:00+02:00',
      },
      {
        'id': 12,
        'ticket_id': 3,
        'author': {'id': 9, 'name': 'هدى'},
        'is_mine': false,
        'body': null,
        'is_deleted': false,
        'is_edited': false,
        'reply_to': {'id': 11, 'author_name': 'سالم', 'preview': 'الشعار في المرفقات', 'is_deleted': false},
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
            'duration_seconds': 4,
            'waveform': [10, 20, 30],
            'url': 'https://example.test/v.m4a',
          },
        ],
        'sent_at': '2026-10-24T09:05:00+02:00',
        'can_edit': false,
        'can_delete': false,
        'mutation_block_reason': 'هذه الرسالة ليست لك',
      },
    ],
    'is_party': true,
    'can_reply': true,
    'closed_note': null,
    'read_up_to': {'requester': 12, 'designer': 11},
    'counterpart_read_up_to': 11,
  };

  test('the thread parses into the chat model the internal tickets read', () {
    // Act
    final thread = DesignTicketThread.fromJson(serverThread());

    // Assert
    expect(thread.ticket.code, 'D3');
    expect(thread.ticket.status, DesignTicketStatus.inProgress);
    expect(thread.ticket.customerName, 'متجر إكس');
    expect(thread.messages, hasLength(2));
    expect(thread.messages.first.isFrom(7), isTrue);
    expect(thread.messages.last.voice?.id, 44);
    expect(thread.messages.last.voice?.durationSeconds, 4);
    expect(thread.messages.last.replyTo?.authorName, 'سالم');
    expect(thread.canReply, isTrue);
    expect(thread.readByOtherSideUpTo(7), 11);
  });

  test('the other side is the designer for the requester, and the requester for the designer', () {
    // Arrange
    final thread = DesignTicketThread.fromJson(serverThread());

    // Act
    final forRequester = thread.otherSideOf(7);
    final forDesigner = thread.otherSideOf(9);
    final forManager = thread.otherSideOf(1);

    // Assert
    expect(forRequester?.name, 'هدى');
    expect(forDesigner?.name, 'سالم');
    expect(forManager, isNull);
  });

  test('a broadcast has no reader, so the ticks come from the two cursors', () {
    // Arrange — البثُّ بلا `counterpart_read_up_to` ولا رسائل.
    final payload = serverThread()
      ..remove('messages')
      ..['is_party'] = false
      ..['can_reply'] = false
      ..['counterpart_read_up_to'] = null;
    final live = DesignTicketThread.fromJson(payload);

    // Act
    final forRequester = live.readByOtherSideUpTo(7);
    final forDesigner = live.readByOtherSideUpTo(9);

    // Assert
    expect(live.messages, isEmpty);
    expect(forRequester, 11);
    expect(forDesigner, 12);
  });

  test('a status this build does not know still parses', () {
    // Act
    final thread = DesignTicketThread.fromJson({
      ...serverThread(),
      'ticket': {...serverThread()['ticket'] as Map<String, dynamic>, 'status': 'archived'},
    });

    // Assert
    expect(thread.ticket.status, DesignTicketStatus.unknown);
  });
}
