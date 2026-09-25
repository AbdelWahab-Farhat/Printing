import 'dart:io' show Platform;

import 'package:dayaa_client/core/realtime/realtime_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Which build this is. Chosen at compile time — by `--flavor dev`, or by `--dart-define=FLAVOR=dev`
/// — so a release build cannot be talked into pointing at the development API by anything at
/// runtime. See [resolve] for which of the two wins.
///
/// **One file each, and no two share one.** The env file is the only thing deciding which API a
/// build talks to, so a flavour without its own would be a build silently pointed at whichever
/// server its neighbour uses — the kind of mistake that is invisible until real data lands
/// somewhere it should not.
/// **Two, and no more.** A flavour is worth its keep only when it points somewhere else. This
/// app talks to the same API the staff app does, so a third pointing at a different path on the
/// same server would be a build indistinguishable from `prod` — that was tried in the staff app
/// and removed.
enum Flavor {
  /// The machine the developer is sitting at. See `BASE_URL_ANDROID`.
  dev('.env.dev'),

  /// Everything that is not a developer's laptop — the build that ships.
  prod('.env');

  const Flavor(this.envFile);

  /// Which file [AppConfig.load] reads. Bundled as an asset — a flavour added here and not
  /// listed under `assets:` in `pubspec.yaml` fails at launch, not at build.
  final String envFile;

  /// **Only [dev].** This gates the Android emulator's `10.0.2.2` rewrite, so any other flavour
  /// answering true would rewrite its host to an address that exists solely inside an emulator
  /// and reach nothing at all.
  bool get isDevelopment => this == Flavor.dev;

  static Flavor get current => resolve(
    defined: const String.fromEnvironment('FLAVOR'),
    gradleFlavor: appFlavor,
  );

  /// أيُّ النكهتين هذه، من مفتاحَي البناء — بلا ثوابتِ ترجمة، ليكون للقرار اختبار.
  ///
  /// **`--flavor` وحده يكفي.** هو ما يعطي الحزمةَ اسمَها وأيقونتَها («فلايركس تجريبي» و`.dev`)،
  /// فلو بقي ملفُّ البيئة معلّقاً بـ`--dart-define` وحده لخرجت نسخةٌ تقول «تجريبي» وتكلّم الإنتاج
  /// متى نُسي المفتاحُ الثاني. و Flutter يمرّر `--flavor` إلى Dart باسم [appFlavor].
  ///
  /// **و`--dart-define=FLAVOR` المكتوبُ صراحةً يغلب.** `default-flavor: prod` في pubspec يجعل
  /// [appFlavor] «prod» في كل أمرٍ بلا `--flavor`، والأمرُ القديم `--dart-define=FLAVOR=dev`
  /// يجب أن يبقى على ملف التطوير كما كان.
  @visibleForTesting
  static Flavor resolve({required String defined, required String? gradleFlavor}) {
    final name = defined.isNotEmpty ? defined : (gradleFlavor ?? 'prod');

    // Falls back to `prod` rather than throwing: a typo in a build command must not produce a
    // release pointed at a developer's laptop.
    return Flavor.values.firstWhere(
      (flavor) => flavor.name == name,
      orElse: () => Flavor.prod,
    );
  }
}

/// Everything the app needs to know about *where* it is running.
///
/// One place reads `dotenv`, and it is this one. A `dotenv.env['…']` anywhere else is a
/// missing key waiting to become a null-check at a call site that has no idea what to do
/// about it.
abstract final class AppConfig {
  static Flavor get flavor => Flavor.current;

  static bool get isDev => flavor.isDevelopment;

  static Future<void> load() => dotenv.load(fileName: flavor.envFile);

  /// The API root, already including `/api/v1`.
  ///
  /// The Android emulator cannot reach the host's `127.0.0.1` — that address is the emulator
  /// itself — so development on Android goes through `10.0.2.2`. Getting this wrong costs an
  /// afternoon of "the app just hangs", which is why it is resolved here rather than typed
  /// into a config by each developer.
  static String get baseUrl => resolveBaseUrl(
    isDevFlavor: isDev,
    isDebugBuild: kDebugMode,
    isAndroid: !kIsWeb && Platform.isAndroid,
    androidUrl: dotenv.env['BASE_URL_ANDROID'],
    url: dotenv.env['BASE_URL'],
  );

  /// القرارُ وحدَه، بلا منصّةٍ ولا ملفِّ بيئة — ليكون له اختبار.
  ///
  /// **و`isDebugBuild` هو الشرطُ الذي كان ناقصاً**، كما نقص من تطبيق الموظفين قبله. `10.0.2.2`
  /// لا معنى له خارج مُحاكي أندرويد: على هاتفٍ حقيقيّ لا يُوجَّه إلى شيء، فيقف كلُّ طلبٍ على مهلة
  /// الاتصال بلا ردٍّ ولا رسالةِ خطأ. ونسخةُ `dev` المُصدَّرة هي ما يُسلَّم للمُختبِر، فلا تُعيد
  /// الكتابة أبداً؛ والمُحاكي يعمل بالتصحيح، وهناك وحدَه تبقى الحيلة.
  @visibleForTesting
  static String resolveBaseUrl({
    required bool isDevFlavor,
    required bool isDebugBuild,
    required bool isAndroid,
    required String? androidUrl,
    required String? url,
  }) {
    if (isDevFlavor && isDebugBuild && isAndroid && androidUrl != null && androidUrl.isNotEmpty) {
      return androidUrl;
    }

    assert(url != null && url.isNotEmpty, 'BASE_URL is missing from ${flavor.envFile}');

    return url ?? '';
  }

  /// خادمُ البثّ الحيّ (Reverb) — أو `null` حين لا يكون مُعدّاً، فتعمل الشاشات بالسحب كما كانت.
  ///
  /// **لا يُكتب فيه إلا المفتاحُ والمنفذ**، والباقي يُشتقّ من [baseUrl]: المضيفُ مضيفُه — ومنه
  /// `10.0.2.2` لمحاكي أندرويد بلا سطرٍ ثانٍ — والمخطّطُ `wss` حين يكون الـ API على `https`.
  static RealtimeEndpoint? get realtime {
    final key = dotenv.env['REVERB_APP_KEY']?.trim();
    if (key == null || key.isEmpty) return null;

    final api = Uri.parse(baseUrl);
    final host = dotenv.env['REVERB_HOST']?.trim();
    final scheme = dotenv.env['REVERB_SCHEME']?.trim();

    return RealtimeEndpoint(
      scheme: (scheme == null || scheme.isEmpty) ? (api.scheme == 'https' ? 'wss' : 'ws') : scheme,
      host: (host == null || host.isEmpty) ? api.host : host,
      port: int.tryParse(dotenv.env['REVERB_PORT']?.trim() ?? ''),
      key: key,
    );
  }

  /// Long enough for a slow Libyan mobile connection, short enough that a dead server does not
  /// leave a spinner running for a minute.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 30); // uploads need the extra room
}
