import 'dart:async';

import 'package:dayaa_client/core/network/safe_request.dart';
import 'package:dayaa_client/features/notifications/usecases/register_device_token.dart';
import 'package:dayaa_client/features/notifications/usecases/release_device_token.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// كلُّ ما يخصّ الدفع في ملفٍّ واحد — منقولٌ عن تطبيق الموظفين، بفروقٍ ثلاثة مقصودة.
///
/// **لماذا ملفٌّ واحد لا استدعاءٌ عند كلّ موضع.** للتسجيل ثلاثُ لحظات (الدخول، فتحُ التطبيق
/// بجلسة، الخروج)، وموزّعةً على الشاشات يضيع تحريرُ الخروج أوّلاً، وعَرَضُه — هاتفٌ تصله طلبياتُ
/// العميل السابق — لا يشبه سطراً ناقصاً في دالة خروج.
///
/// **والفروقُ عن تطبيق الموظفين:**
///
///   * **Firebase قد لا يكون قائماً**، فـ[FirebaseMessaging] هنا nullable وكلُّ دالةٍ لا تفعل شيئاً
///     بدونه. هناك يُبنى من `FirebaseMessaging.instance` مباشرةً، وهو يرمي على تطبيقٍ لم يُهيَّأ —
///     فملفُّ إعداداتٍ ناقص كان سيكلّف الدخولَ كلَّه لا الإشعاراتِ وحدها.
///   * **لا شريطَ والتطبيقُ مفتوح، على المنصّتين.** أندرويد لا يعرضه أصلاً، وعلى iOS تركنا
///     `setForegroundNotificationPresentationOptions` عن قصد: العميلُ الذي يقرأ محادثة الدعم يرى
///     الردَّ يصل حيّاً (Reverb)، وشريطٌ فوقه بالخبر نفسه ضجيج.
///   * **لا عدّادَ ولا جرس**: الدفعُ طَرقة، والمحتوى في شاشته.
///
/// **وهذا الصنف لا يقرّر متى يُطلب الإذن.** مَن يستدعيه يقرّر (المستودع: عند الدخول يسأل، وعند
/// الفتح لا)، وهذا يفعل ما يُقال له.
class PushService {
  PushService({
    required RegisterDeviceToken registerToken,
    required ReleaseDeviceToken releaseToken,
    required FirebaseMessaging? messaging,
    Stream<RemoteMessage>? openedApp,
  }) : _registerToken = registerToken,
       _releaseToken = releaseToken,
       _messaging = messaging,
       _openedApp = openedApp;

  final RegisterDeviceToken _registerToken;
  final ReleaseDeviceToken _releaseToken;

  /// null حين لم تقم Firebase — انظر `main.dart`.
  final FirebaseMessaging? _messaging;

  /// `FirebaseMessaging.onMessageOpenedApp` — ثابتٌ على الصنف لا على النسخة، فيُمرَّر ليُختبر.
  final Stream<RemoteMessage>? _openedApp;

  StreamSubscription<String>? _tokenRefresh;
  StreamSubscription<RemoteMessage>? _opened;

  /// آخرُ توكنٍ قَبِله الخادم، ليحرّر [release] الصحيحَ بعد أن يدوّره الهاتف. null: لا شيء مسجَّلٌ
  /// من هذا التشغيل.
  String? _registered;

  /// ضغط العميلُ إشعاراً وله وجهة. **لا يُستدعى بـnull أبداً** — إشعارٌ بلا وجهة يفتح التطبيق فقط.
  void Function(String route)? onOpenRoute;

  /// يصل المجريَين. آمنٌ أن يُستدعى أكثر من مرّة؛ الاشتراكاتُ السابقة تُلغى أوّلاً.
  ///
  /// يُستدعى مرّةً عند الإقلاع، **قبل** أيّ دخول: الإصغاءُ لا يكلّف، ودورةُ التوكن قد تحدث وهو
  /// خارج — حيث لا تفعل شيئاً لأنّ لا جلسة.
  Future<void> start() async {
    await stop();

    final messaging = _messaging;
    if (messaging == null) return;

    // FCM يدوّر التوكن على جدوله. دورةٌ لا يعلم بها الخادم جهازٌ يكفّ عن الاستقبال صامتاً.
    _tokenRefresh = messaging.onTokenRefresh.listen((token) {
      if (_registered == null) return; // خارج — لا شيء يُلاحَق
      unawaited(_send(token));
    });

    // في الخلفية ← ضُغط. التطبيقُ حيّ والموجِّه جاهز، فيُفتح فوراً — بخلاف الإقلاع البارد الذي
    // يقرؤه [initialRoute] بعد أن تحسم شاشةُ البداية الجلسة.
    _opened = _openedApp?.listen(_openFrom);
  }

  Future<void> stop() async {
    await _tokenRefresh?.cancel();
    await _opened?.cancel();
    _tokenRefresh = null;
    _opened = null;
  }

  /// الوجهةُ التي أُقلع منها التطبيق بضغطِ إشعار، أو null لإقلاعٍ عاديّ.
  ///
  /// **لا تُقرأ إلا بعد أن تحسم شاشةُ البداية الجلسة**، وإلا دُفع عميلٌ بلا جلسة إلى شاشةٍ تحتاجها.
  Future<String?> initialRoute() async {
    final message = await _messaging?.getInitialMessage();

    return _routeOf(message);
  }

  /// يسجّل هذا الجهاز. بعد الدخول يسأل النظام ([askPermission])، وعند الفتح بجلسةٍ لا يسأل.
  ///
  /// يُرجع false حين لا يُسجَّل شيء: لا Firebase، أو رفض النظام، أو لا توكن بعد، أو رفض الخادم.
  Future<bool> register({bool askPermission = true}) async {
    final messaging = _messaging;
    if (messaging == null) return false;

    final settings = askPermission
        ? await messaging.requestPermission()
        : await messaging.getNotificationSettings();
    if (!_granted(settings.authorizationStatus)) return false;

    final token = await _currentToken(messaging);
    if (token == null) return false;

    return _send(token);
  }

  /// يحرّر هذا الجهاز. عند الخروج **قبل أن يُمسح رمزُ الدخول** — التحرير نفسه طلبٌ موثَّق.
  ///
  /// الفشلُ يُبتلع عن قصد: الخروج لا يُعطّله خطأُ شبكة. يبقى السطر في الخادم حينها، ولذلك
  /// يحذف الخادمُ التوكنَ متى أخبره FCM أنه ميّت.
  Future<void> release() async {
    final messaging = _messaging;
    if (messaging == null) return;

    final token = _registered ?? await _currentToken(messaging);
    _registered = null;
    if (token == null) return;

    await _releaseToken(token: token);
  }

  Future<bool> _send(String token) async {
    final result = await _registerToken(token: token, platform: _platform());

    return result.fold((_) => false, (_) {
      _registered = token;

      return true;
    });
  }

  /// توكنُ FCM الآن، أو null.
  ///
  /// **على iOS يرمي `getToken` حتى يصل توكنُ APNs** (`apns-token-not-set`)، وأوّلُ دخولٍ بعد
  /// التنصيب هو بالضبط تلك اللحظة. والتسجيل يُستدعى دون انتظار، فاستثناءٌ هنا خطأٌ لا يلتقطه أحد؛
  /// «لا توكن بعد» هو الجواب الصادق، والفتحُ التالي يسجّل.
  Future<String?> _currentToken(FirebaseMessaging messaging) async {
    final result = await safePlatformCall(messaging.getToken);

    return result.fold((_) => null, (token) => token);
  }

  void _openFrom(RemoteMessage message) {
    final route = _routeOf(message);
    if (route != null) onOpenRoute?.call(route);
  }

  /// الخادمُ يضع الوجهة في `data.route`، وهي nullable بطبيعتها. والسلسلةُ الفارغة كالغائبة، لا
  /// تُدفع إلى الموجِّه فتنتهي بصفحة خطأ.
  String? _routeOf(RemoteMessage? message) {
    final route = message?.data['route'];

    return route is String && route.isNotEmpty ? route : null;
  }

  /// يطابق `DevicePlatform` في الخادم — `android` و`ios` و`web`؛ ما سواها يرفضه التحقّق.
  ///
  /// [defaultTargetPlatform] لا `Platform`: الأوّلُ يُقرأ على الويب ويُبدَّل في الاختبار.
  String _platform() {
    if (kIsWeb) return 'web';

    return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  }

  bool _granted(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized || status == AuthorizationStatus.provisional;
}
