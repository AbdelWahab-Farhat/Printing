import 'package:dayaa_client/core/config/app_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reading configuration, and the one way it goes wrong.
///
/// Arrange - Act - Assert throughout.
void main() {
  // `dotenv.env` throws until something has loaded; an empty map is a loaded map with no keys,
  // which is exactly the "nothing configured" case one of these tests is about.
  setUp(() => dotenv.testLoad(fileInput: ''));

  tearDown(() => dotenv.env.clear());

  group('flavours', () {
    test('each one reads its own env file, and they are all distinct', () {
      // Arrange — the file is what decides which API a build talks to, so two flavours sharing
      // one would be a build silently pointed at wherever its neighbour happens to point.
      //
      // **Two, and only two.** A third that named a different file but the same server was
      // exactly that: two builds nobody could tell apart, and a picker on the build command
      // that changed nothing. One production API means one production flavour.
      // Act
      final files = [for (final flavor in Flavor.values) flavor.envFile];

      // Assert
      expect(files.toSet(), hasLength(Flavor.values.length));
      expect(Flavor.dev.envFile, '.env.dev');
      expect(Flavor.prod.envFile, '.env');
    });

    test('an unknown FLAVOR falls back to prod, never to a development API', () {
      // Arrange — `Flavor.current` reads a compile-time constant this test cannot set, so what
      // is pinned here is the *default* it resolves to. A typo in a build command must not
      // produce a release pointed at 127.0.0.1.
      // Act
      final resolved = Flavor.resolve(defined: 'typo', gradleFlavor: null);

      // Assert
      expect(resolved, Flavor.prod);
      expect(Flavor.current, isNot(Flavor.dev));
    });

    test('--flavor dev alone picks the dev env file, with no --dart-define beside it', () {
      // Arrange — «flutter build apk --flavor dev» بلا `--dart-define=FLAVOR=dev`. لو قُرئ
      // الـ dart-define وحده لخرجت حزمةُ الاختبار — أيقونتُها واسمُها «تجريبي» — تكلّم الإنتاج،
      // ولأنشأ المُختبِرُ طلبياتٍ حقيقية.
      // Act
      final resolved = Flavor.resolve(defined: '', gradleFlavor: 'dev');

      // Assert
      expect(resolved, Flavor.dev);
    });

    test('an explicit --dart-define=FLAVOR still wins over the default flavour', () {
      // Arrange — «flutter run --dart-define=FLAVOR=dev» كما كُتب قبل النكهات: `default-flavor:
      // prod` في pubspec يجعل `appFlavor` «prod»، والأمرُ القديم يجب أن يبقى على ملف التطوير.
      // Act
      final resolved = Flavor.resolve(defined: 'dev', gradleFlavor: 'prod');

      // Assert
      expect(resolved, Flavor.dev);
    });

    test('with neither given, the build is prod', () {
      // Arrange
      // Act
      final resolved = Flavor.resolve(defined: '', gradleFlavor: null);

      // Assert
      expect(resolved, Flavor.prod);
    });

    test('only the development flavour is treated as development', () {
      // Arrange — `isDev` gates the Android emulator's 10.0.2.2 rewrite, an address that exists
      // only inside an emulator. A release build answering true to it would reach nothing.
      // Act & Assert
      expect(Flavor.dev.isDevelopment, isTrue);
      expect(Flavor.prod.isDevelopment, isFalse);
    });
  });

  // الحالاتُ الخمس نفسُها في تطبيق الموظفين (frontend/test/core/config/app_config_test.dart)،
  // حيث وصلت نسخةُ مُختبِرٍ تطلب `10.0.2.2` من هاتفٍ حقيقيّ.
  group('the API address a build talks to', () {
    // العنوانُ الافتراضيّ في كلّ اختبارات هذه المجموعة: ما يقوله ملفُّ البيئة.
    const server = 'https://primulatest.server.ly/api/v1';
    const emulator = 'http://10.0.2.2:8000/api/v1';

    test('a released test build never rewrites the host to the emulator address', () {
      // Arrange — نكهةُ `dev`، بناءٌ مُصدَّر، أندرويد، وملفُّ بيئةٍ فيه `BASE_URL_ANDROID`.
      // و`10.0.2.2` هو المضيفُ كما يراه مُحاكي أندرويد وحدَه؛ على هاتفٍ حقيقيّ لا يُوجَّه إلى
      // شيء، فتقف الشاشةُ على التحميل بلا رسالةِ خطأ.
      // Act
      final url = AppConfig.resolveBaseUrl(
        isDevFlavor: true,
        isDebugBuild: false,
        isAndroid: true,
        androidUrl: emulator,
        url: server,
      );

      // Assert
      expect(url, server);
    });

    test('the emulator rewrite still applies where it belongs: a debug run', () {
      // Arrange — مُحاكي أندرويد لا يصل `127.0.0.1` الماك، لأن ذاك العنوان هو المُحاكي نفسُه.
      // Act
      final url = AppConfig.resolveBaseUrl(
        isDevFlavor: true,
        isDebugBuild: true,
        isAndroid: true,
        androidUrl: emulator,
        url: 'http://127.0.0.1:8000/api/v1',
      );

      // Assert
      expect(url, emulator);
    });

    test('production never rewrites, whatever the env file happens to hold', () {
      // Arrange — النكهةُ هي الحارس لا الملفّ.
      // Act
      final url = AppConfig.resolveBaseUrl(
        isDevFlavor: false,
        isDebugBuild: true,
        isAndroid: true,
        androidUrl: emulator,
        url: 'https://api.daaya.ly/api/v1',
      );

      // Assert
      expect(url, 'https://api.daaya.ly/api/v1');
    });

    test('a blank BASE_URL_ANDROID is treated as absent, not as an empty host', () {
      // Arrange — «BASE_URL_ANDROID=» بلا قيمة يردّه dotenv نصّاً فارغاً لا null.
      // Act
      final url = AppConfig.resolveBaseUrl(
        isDevFlavor: true,
        isDebugBuild: true,
        isAndroid: true,
        androidUrl: '',
        url: server,
      );

      // Assert
      expect(url, server);
    });

    test('iOS reads BASE_URL even in a debug run; the rewrite is Android-only', () {
      // Arrange
      // Act
      final url = AppConfig.resolveBaseUrl(
        isDevFlavor: true,
        isDebugBuild: true,
        isAndroid: false,
        androidUrl: emulator,
        url: server,
      );

      // Assert
      expect(url, server);
    });
  });
}
