import 'dart:async';
import 'dart:convert';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:dayaa/core/realtime/pusher_realtime_client.dart';
import 'package:dayaa/core/realtime/realtime_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// العميلُ الحيّ مقابل خادمٍ مزيّف يتكلم بروتوكول Pusher، بلا شبكة.
///
/// **ما يُحرس هنا هو ما أضفناه فوق الحزمة**: الاشتراكُ يتبع المستمعين، والقناةُ لا تُطلب قبل أن
/// يكون للمقبس رقم، وتُدخَل من جديد بعد كل انقطاع ومعها [RealtimeClient.resumed]، والتوقيعُ
/// المرفوض لا يفتح شيئاً.
void main() {
  const endpoint = RealtimeEndpoint(scheme: 'ws', host: 'localhost', port: 8080, key: 'k');

  late _FakeServer server;
  late List<(String, String)> signed;

  PusherRealtimeClient build({ChannelSigner? sign, RealtimeEndpoint? at = endpoint}) {
    return PusherRealtimeClient(
      endpoint: at,
      sign: sign ??
          (socketId, channel) async {
            signed.add((socketId, channel));

            return 'k:signature';
          },
      connection: server.connect,
      followAppLifecycle: false,
      backoff: (_) => Duration.zero,
    );
  }

  /// يترك الخادمَ والحزمةَ يتبادلان ما في الطابور — كلُّ خطوةٍ عندهما مهمّةٌ مؤجّلة.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  setUp(() {
    server = _FakeServer();
    signed = [];
  });

  test('the first listener connects and enters the channel once the socket has an id', () async {
    // Arrange
    final client = build();

    // Act
    final subscription = client.privateEvents('private-support.desk', 'support.ticket.changed').listen((_) {});
    await settle();

    // Assert
    expect(server.connections, hasLength(1));
    expect(signed, [('1.1', 'private-support.desk')]);
    expect(server.subscribedTo('private-support.desk'), isTrue);

    await subscription.cancel();
  });

  test('an event on the channel arrives decoded, and other events and channels do not', () async {
    // Arrange
    final client = build();
    final received = <Map<String, dynamic>>[];
    final subscription = client.privateEvents('private-support.desk', 'support.ticket.changed').listen(received.add);
    await settle();

    // Act
    server
      ..push('private-support.desk', 'support.ticket.changed', {'ticket': {'id': 7}})
      ..push('private-support.desk', 'something.else', {'ticket': {'id': 8}})
      ..push('private-customers.3', 'support.ticket.changed', {'ticket': {'id': 9}});
    await settle();

    // Assert
    expect(received, [
      {'ticket': {'id': 7}},
    ]);

    await subscription.cancel();
  });

  test('the last listener leaving closes the socket; the next one opens a new one', () async {
    // Arrange
    final client = build();
    final first = client.privateEvents('private-support.desk', 'support.ticket.changed').listen((_) {});
    final second = client.privateEvents('private-support.desk', 'support.ticket.changed').listen((_) {});
    await settle();

    // Act
    await first.cancel();
    await settle();
    final stillOpen = !server.connections.single.closed;
    await second.cancel();
    await settle();
    final closedAfterLast = server.connections.single.closed;
    final again = client.privateEvents('private-support.desk', 'support.ticket.changed').listen((_) {});
    await settle();

    // Assert
    expect(stillOpen, isTrue);
    expect(closedAfterLast, isTrue);
    expect(server.connections, hasLength(2));
    expect(server.subscribedTo('private-support.desk', connection: 1), isTrue);

    await again.cancel();
  });

  test('after the server drops the socket the channel is entered again and resumed fires', () async {
    // Arrange
    final client = build();
    var resumes = 0;
    final resumed = client.resumed.listen((_) => resumes++);
    final received = <Map<String, dynamic>>[];
    final subscription = client.privateEvents('private-support.desk', 'support.ticket.changed').listen(received.add);
    await settle();

    // Act
    server.dropCurrent();
    await settle();
    server.push('private-support.desk', 'support.ticket.changed', {'ticket': {'id': 11}});
    await settle();

    // Assert
    expect(server.connections, hasLength(2));
    expect(signed.map((s) => s.$1), ['1.1', '2.2']);
    expect(resumes, 1);
    expect(received, [
      {'ticket': {'id': 11}},
    ]);

    await subscription.cancel();
    await resumed.cancel();
  });

  test('a refused signature never subscribes', () async {
    // Arrange
    final client = build(sign: (_, _) async => null);

    // Act
    final subscription = client.privateEvents('private-support.desk', 'support.ticket.changed').listen((_) {});
    await settle();

    // Assert
    expect(server.subscribedTo('private-support.desk'), isFalse);

    await subscription.cancel();
  });

  test('with no endpoint configured nothing connects and the stream stays silent', () async {
    // Arrange
    final client = build(at: null);
    var done = false;

    // Act
    final subscription = client
        .privateEvents('private-support.desk', 'support.ticket.changed')
        .listen((_) {}, onDone: () => done = true);
    await settle();

    // Assert
    expect(server.connections, isEmpty);
    expect(done, isTrue);

    await subscription.cancel();
  });
}

/// خادمٌ بحجم الاختبار: يمنح كل مقبسٍ رقماً، ويؤكّد كل اشتراك، ويدفع ما يُطلب منه.
///
/// **يَعُدّ المقابس التي اتصلت فعلاً**، لا كلَّ ما بنته الحزمة: متحكّمها يبني اتصالاً أولاً
/// ويغلقه قبل أن يتصل، في كل دورة.
class _FakeServer {
  final List<_FakeConnection> connections = [];

  PusherChannelsConnection connect() => _FakeConnection(this);

  bool subscribedTo(String channel, {int? connection}) {
    final on = connection == null ? connections : [connections[connection]];

    return on.any(
      (c) => c.sent.any(
        (message) =>
            message['event'] == 'pusher:subscribe' &&
            (message['data'] as Map<String, dynamic>)['channel'] == channel,
      ),
    );
  }

  void push(String channel, String event, Map<String, dynamic> data) =>
      connections.last.deliver({'event': event, 'channel': channel, 'data': jsonEncode(data)});

  void dropCurrent() => connections.last.drop();
}

class _FakeConnection implements PusherChannelsConnection {
  _FakeConnection(this._server);

  final _FakeServer _server;
  final List<Map<String, dynamic>> sent = [];
  bool closed = false;

  PusherChannelsConnectionOnEventCallback? _onEvent;
  PusherChannelsConnectionOnDoneCallback? _onDone;

  @override
  void connect({
    required PusherChannelsConnectionOnDoneCallback onDoneCallback,
    required PusherChannelsConnectionOnErrorCallback onErrorCallback,
    required PusherChannelsConnectionOnEventCallback onEventCallback,
  }) {
    _onEvent = onEventCallback;
    _onDone = onDoneCallback;
    _server.connections.add(this);

    final number = _server.connections.length;

    scheduleMicrotask(
      () => deliver({
        'event': 'pusher:connection_established',
        'data': jsonEncode({'socket_id': '$number.$number', 'activity_timeout': 120}),
      }),
    );
  }

  void deliver(Map<String, dynamic> message) {
    if (!closed) _onEvent?.call(jsonEncode(message));
  }

  void drop() {
    closed = true;
    _onDone?.call();
  }

  @override
  void sendEvent(String eventEncoded) {
    final message = jsonDecode(eventEncoded) as Map<String, dynamic>;
    sent.add(message);

    if (message['event'] == 'pusher:subscribe') {
      final channel = (message['data'] as Map<String, dynamic>)['channel'];

      scheduleMicrotask(
        () => deliver({
          'event': 'pusher_internal:subscription_succeeded',
          'channel': channel,
          'data': '{}',
        }),
      );
    }
  }

  @override
  void ping() {}

  @override
  FutureOr<void> close() {
    closed = true;
  }
}
