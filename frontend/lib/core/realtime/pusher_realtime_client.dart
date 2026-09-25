import 'dart:async';
import 'dart:math' as math;

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:dayaa/core/realtime/realtime_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// [RealtimeClient] فوق `dart_pusher_channels` — عميلُ بروتوكول Pusher الذي يتكلمه Reverb.
///
/// ### ما يفعله هذا الصنف ولا تفعله الحزمة
///
/// - **الاتصالُ يتبع الشاشات.** يُفتح مع أول مستمع ويُغلق مع آخرهم، فلا مقبسَ يبقى مفتوحاً
///   لموظفٍ لا يقرأ التذاكر.
/// - **القنواتُ تُدخَل من جديد بعد كل عودة.** الخادم ينسى اشتراكات المقبس الذي انقطع، والحزمة
///   لا تعيدها وحدها — فتُعاد هنا عند كل `connection_established`، ثم يُطلق [resumed] ليعيد كلُّ
///   من يرسم شيئاً حيّاً قراءةَ ما فاته.
/// - **المحاولاتُ تتباعد** (١، ٢، ٤ … حتى ٣٠ ثانية): خادمٌ نائم لا يُطرق كل ثانية إلى الأبد.
/// - **عودةُ التطبيق من الخلفية تعيد الاتصال فوراً.** iOS يقتل المقبس في الخلفية أحياناً بلا خبر،
///   والحزمة لا تكتشف ذلك إلا بعد دقيقةٍ من الصمت — دقيقةٌ تفوت فيها الردود.
/// - **رفضُ المفتاح نهائي** (أخطاء Pusher ٤٠٠٠–٤٠٩٩): مفتاحٌ خاطئ لا تصلحه المحاولة الثانية،
///   فيُقطع الاتصال بدل أن يُعاد كل ثانية.
class PusherRealtimeClient implements RealtimeClient {
  PusherRealtimeClient({
    required RealtimeEndpoint? endpoint,
    required ChannelSigner sign,

    /// **الاختبارات وحدها تمرّر هذا** — اتصالٌ مزيّف يمثّل الخادم بلا شبكة.
    @visibleForTesting PusherChannelsConnection Function()? connection,

    /// والاختبارات تطفئه: مراقبةُ دورة حياة التطبيق تحتاج `WidgetsBinding`.
    @visibleForTesting bool followAppLifecycle = true,
    @visibleForTesting Duration Function(int attempt) backoff = _defaultBackoff,
  }) : _endpoint = endpoint,
       _sign = sign,
       _connection = connection,
       _followAppLifecycle = followAppLifecycle,
       _backoff = backoff;

  final RealtimeEndpoint? _endpoint;
  final ChannelSigner _sign;
  final PusherChannelsConnection Function()? _connection;
  final bool _followAppLifecycle;
  final Duration Function(int attempt) _backoff;

  final Map<String, _ChannelEntry> _channels = {};
  final StreamController<void> _resumed = StreamController<void>.broadcast();

  PusherChannelsClient? _client;
  final List<StreamSubscription<Object?>> _clientSubscriptions = [];
  AppLifecycleListener? _lifecycle;
  Timer? _retry;
  int _failures = 0;
  bool _connected = false;
  bool _hasConnectedBefore = false;

  @override
  Stream<void> get resumed => _resumed.stream;

  @override
  Stream<Map<String, dynamic>> privateEvents(String channel, String event) {
    // لا بثّ مُعدّ: تيارٌ صامت، والشاشة كما كانت قبل البثّ.
    if (_endpoint == null) return const Stream.empty();

    StreamSubscription<ChannelReadEvent>? binding;
    late final StreamController<Map<String, dynamic>> out;

    out = StreamController<Map<String, dynamic>>(
      onListen: () {
        final entry = _retain(channel);

        binding = entry.channel.bind(event).listen((read) {
          // حمولةٌ لا تُفكّ لا تُمرَّر: الحزمة تعيد null بدل أن ترمي.
          final data = read.tryGetDataAsMap();
          if (data != null) out.add(data);
        });
      },
      onCancel: () async {
        await binding?.cancel();
        _release(channel);
        // تيارٌ لمستمعٍ واحد: غادر، فلا شيء بعده يُرسل فيه.
        unawaited(out.close());
      },
    );

    return out.stream;
  }

  _ChannelEntry _retain(String name) {
    final client = _clientOrStart();

    final entry = _channels.putIfAbsent(
      name,
      () => _ChannelEntry(
        client.privateChannel(
          name,
          authorizationDelegate: _Authorizer(_sign),
          // نسخةٌ جديدة لكل دخول: قناةٌ خرجنا منها تبقى «مُلغاة» في ذاكرة الحزمة ولا تعود.
          forceCreateNewInstance: true,
        ),
      ),
    );

    entry.listeners++;

    // قبل أن يتصل المقبس لا رقمَ له يُوقَّع عليه — الدخولُ يقع عند `connection_established`.
    if (entry.listeners == 1 && _connected) entry.channel.subscribe();

    return entry;
  }

  void _release(String name) {
    final entry = _channels[name];
    if (entry == null) return;

    entry.listeners--;
    if (entry.listeners > 0) return;

    _channels.remove(name);
    entry.channel.unsubscribe();

    if (_channels.isEmpty) _shutDown();
  }

  PusherChannelsClient _clientOrStart() {
    final existing = _client;
    if (existing != null) return existing;

    final endpoint = _endpoint!;
    final options = PusherChannelsOptions.fromHost(
      scheme: endpoint.scheme,
      host: endpoint.host,
      port: endpoint.port,
      key: endpoint.key,
    );

    final connection = _connection;
    final client = connection == null
        ? PusherChannelsClient.websocket(
            options: options,
            connectionErrorHandler: _onConnectionError,
          )
        : PusherChannelsClient.custom(
            connectionDelegate: connection,
            connectionErrorHandler: _onConnectionError,
            minimumReconnectDelayDuration: Duration.zero,
          );

    _clientSubscriptions
      ..add(client.lifecycleStream.listen(_onLifecycle))
      ..add(client.pusherErrorEventStream.listen(_onPusherError));

    if (_followAppLifecycle) {
      _lifecycle = AppLifecycleListener(onResume: () => unawaited(client.reconnect()));
    }

    _client = client;
    unawaited(client.connect());

    return client;
  }

  void _onLifecycle(PusherChannelsClientLifeCycleState state) {
    if (state != PusherChannelsClientLifeCycleState.establishedConnection) {
      _connected = false;

      return;
    }

    _connected = true;
    _failures = 0;

    // الخادم نسي اشتراكات المقبس القديم: كلُّ قناةٍ ما زال أحدٌ يسمعها تُدخَل من جديد.
    for (final entry in _channels.values) {
      entry.channel.subscribe();
    }

    if (_hasConnectedBefore) _resumed.add(null);
    _hasConnectedBefore = true;
  }

  void _onConnectionError(dynamic exception, StackTrace trace, void Function() refresh) {
    _connected = false;
    _retry?.cancel();
    _retry = Timer(_backoff(_failures++), refresh);
  }

  void _onPusherError(PusherChannelsReadEvent event) {
    final code = int.tryParse('${event.tryGetDataAsMap()?['code']}');

    // ٤٠٠٠–٤٠٩٩ في بروتوكول Pusher تعني «لا تُعِد المحاولة»: مفتاحٌ لا يعرفه الخادم، أو تطبيقٌ
    // معطّل. المحاولةُ التالية ستُرفض بالسبب نفسه.
    if (code != null && code >= 4000 && code < 4100) {
      if (kDebugMode) debugPrint('⚠️ خادم البثّ رفض الاتصال نهائياً ($code)');

      unawaited(_client?.disconnect());
    }
  }

  void _shutDown() {
    _retry?.cancel();
    _retry = null;
    _lifecycle?.dispose();
    _lifecycle = null;

    for (final subscription in _clientSubscriptions) {
      unawaited(subscription.cancel());
    }
    _clientSubscriptions.clear();

    _client?.dispose();
    _client = null;
    _connected = false;
    _hasConnectedBefore = false;
    _failures = 0;
  }

  static Duration _defaultBackoff(int attempt) =>
      Duration(seconds: math.min(30, 1 << math.min(attempt, 5)));
}

class _ChannelEntry {
  _ChannelEntry(this.channel);

  final PrivateChannel channel;
  int listeners = 0;
}

/// التوقيعُ عبر [ChannelSigner]، بالشكل الذي تطلبه الحزمة.
///
/// **يرمي حين يُرفض**، ولا يلتقط شيئاً: الحزمةُ هي من تلتقط، فتُعلن فشلَ الدخول على القناة
/// نفسها بدل أن ترسل للخادم اشتراكاً بلا توقيع.
class _Authorizer implements EndpointAuthorizableChannelAuthorizationDelegate<
    PrivateChannelAuthorizationData> {
  const _Authorizer(this._sign);

  final ChannelSigner _sign;

  @override
  EndpointAuthFailedCallback? get onAuthFailed => null;

  @override
  Future<PrivateChannelAuthorizationData> authorizationData(
    String socketId,
    String channelName,
  ) async {
    final auth = await _sign(socketId, channelName);

    if (auth == null) throw StateError('رُفض الدخول إلى $channelName');

    return PrivateChannelAuthorizationData(authKey: auth);
  }
}
