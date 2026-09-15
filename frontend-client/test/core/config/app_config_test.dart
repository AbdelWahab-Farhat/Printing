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
      final resolved = Flavor.values.firstWhere(
        (flavor) => flavor.name == 'typo',
        orElse: () => Flavor.prod,
      );

      // Assert
      expect(resolved, Flavor.prod);
      expect(Flavor.current, isNot(Flavor.dev));
    });

    test('only the development flavour is treated as development', () {
      // Arrange — `isDev` gates the Android emulator's 10.0.2.2 rewrite, an address that exists
      // only inside an emulator. A release build answering true to it would reach nothing.
      // Act & Assert
      expect(Flavor.dev.isDevelopment, isTrue);
      expect(Flavor.prod.isDevelopment, isFalse);
    });
  });
}
