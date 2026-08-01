import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/core/config/app_config.dart';

/// Reading configuration, and the one way it goes wrong.
///
/// Arrange - Act - Assert throughout.
void main() {
  // `dotenv.env` throws until something has loaded; an empty map is a loaded map with no keys,
  // which is exactly the "nothing configured" case one of these tests is about.
  setUp(() => dotenv.testLoad(fileInput: ''));

  tearDown(() => dotenv.env.clear());

  group('a key that is present but blank', () {
    test('the map falls back to a real tile server', () {
      // Arrange — `MAP_TILE_URL=` with nothing after it is what "optional" invites somebody to
      // write, and dotenv reports it as `''` rather than as missing. A plain `??` therefore
      // hands an empty string to the map, every tile fails with "No host specified in URI",
      // and the screen shows a blank grey grid that still pans and still returns coordinates.
      dotenv.env['MAP_TILE_URL'] = '';

      // Act
      final url = AppConfig.mapTileUrl;

      // Assert
      expect(url, startsWith('https://'));
      expect(Uri.parse(url).host, isNotEmpty);
    });

    test('the geocoder falls back too', () {
      // Arrange
      dotenv.env['GEOCODER_BASE_URL'] = '   ';

      // Act
      final url = AppConfig.geocoderBaseUrl;

      // Assert
      expect(Uri.parse(url).host, isNotEmpty);
    });
  });

  group('a key that is set', () {
    test('is used as given, and trimmed', () {
      // Arrange — a trailing space survives copy-paste out of a chat message.
      dotenv.env['MAP_TILE_URL'] = ' https://tiles.example.ly/{z}/{x}/{y}.png ';

      // Act
      final url = AppConfig.mapTileUrl;

      // Assert
      expect(url, 'https://tiles.example.ly/{z}/{x}/{y}.png');
    });
  });

  test('a key that is absent falls back', () {
    // Arrange — nothing set at all.
    // Act
    final url = AppConfig.geocoderBaseUrl;

    // Assert
    expect(Uri.parse(url).host, 'nominatim.openstreetmap.org');
  });
}
