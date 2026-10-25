import 'dart:convert';
import 'dart:typed_data';

import 'package:dayaa/core/store_update/store_update.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// جوابُ Apple كما يصل: `text/javascript` لا `application/json` — فلا يفكّه Dio وحده.
class _LookupAdapter implements HttpClientAdapter {
  _LookupAdapter(this.results, {this.status = 200});

  final List<Map<String, Object?>> results;
  final int status;
  int calls = 0;
  Uri? lastUri;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    lastUri = options.uri;

    return ResponseBody.fromString(
      jsonEncode({'resultCount': results.length, 'results': results}),
      status,
      headers: {
        Headers.contentTypeHeader: ['text/javascript; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> _listing({String version = '1.13.0', String minimumOs = '15.0'}) => {
  'bundleId': 'ly.dayaa.app',
  'version': version,
  'minimumOsVersion': minimumOs,
  'trackViewUrl': 'https://apps.apple.com/ly/app/daya-staff/id6808283408?uo=4',
};

void main() {
  late SharedPreferences prefs;
  late DateTime now;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 10, 25, 9);
  });

  StoreUpdate build(
    _LookupAdapter adapter, {
    String installed = '1.12.0',
    String bundleId = 'ly.dayaa.app',
    String osVersion = 'Version 17.5 (Build 21F79)',
  }) => StoreUpdate(
    dio: Dio()..httpClientAdapter = adapter,
    prefs: prefs,
    installed: () async => (bundleId: bundleId, version: installed),
    osVersion: osVersion,
    now: () => now,
  );

  group('compareVersions', () {
    test('compares each part as a number, not as text', () {
      // Act
      final result = compareVersions('1.6', '1.12.0');

      // Assert
      expect(result, isNegative);
    });

    test('a missing part counts as zero', () {
      // Act
      final result = compareVersions('1.12', '1.12.0');

      // Assert
      expect(result, 0);
    });

    test('a higher major wins whatever follows it', () {
      // Act
      final result = compareVersions('2.0.0', '1.99.9');

      // Assert
      expect(result, isPositive);
    });
  });

  group('pending', () {
    test('a newer version on the store is the update to announce', () async {
      // Arrange
      final update = build(_LookupAdapter([_listing()]));

      // Act
      final release = await update.pending();

      // Assert
      expect(release?.version, '1.13.0');
      expect(
        release?.url,
        Uri.parse('https://apps.apple.com/ly/app/daya-staff/id6808283408?uo=4'),
      );
    });

    test('asks the Libyan store for this app, past any cached answer', () async {
      // Arrange
      final adapter = _LookupAdapter([_listing()]);
      final update = build(adapter);

      // Act
      await update.pending();

      // Assert
      expect(adapter.lastUri?.host, 'itunes.apple.com');
      expect(adapter.lastUri?.path, '/lookup');
      expect(adapter.lastUri?.queryParameters['bundleId'], 'ly.dayaa.app');
      expect(adapter.lastUri?.queryParameters['country'], 'ly');
      expect(adapter.lastUri?.queryParameters['_cb'], isNotEmpty);
    });

    test('the same version as the store is nothing to announce', () async {
      // Arrange
      final update = build(_LookupAdapter([_listing(version: '1.12.0')]), installed: '1.12.0');

      // Act
      final release = await update.pending();

      // Assert
      expect(release, isNull);
    });

    test('a TestFlight build ahead of the store is nothing to announce', () async {
      // Arrange
      final update = build(_LookupAdapter([_listing(version: '1.6')]), installed: '1.12.0');

      // Act
      final release = await update.pending();

      // Assert
      expect(release, isNull);
    });

    test('an app the store does not list — the dev build — is nothing to announce', () async {
      // Arrange
      final update = build(_LookupAdapter([]), bundleId: 'ly.dayaa.app.dev');

      // Act
      final release = await update.pending();

      // Assert
      expect(release, isNull);
    });

    test('a version this iPhone cannot install is nothing to announce', () async {
      // Arrange
      final update = build(
        _LookupAdapter([_listing(minimumOs: '17.0')]),
        osVersion: 'Version 16.7.10 (Build 20H350)',
      );

      // Act
      final release = await update.pending();

      // Assert
      expect(release, isNull);
    });

    test('a failed lookup is silence, not an error', () async {
      // Arrange
      final update = build(_LookupAdapter([], status: 503));

      // Act
      final release = await update.pending();

      // Assert
      expect(release, isNull);
    });

    test('asks Apple at most once an hour', () async {
      // Arrange
      final adapter = _LookupAdapter([_listing()]);
      final update = build(adapter);
      await update.pending();
      now = now.add(const Duration(minutes: 59));

      // Act
      final second = await update.pending();

      // Assert
      expect(second, isNull);
      expect(adapter.calls, 1);
    });
  });

  group('snooze', () {
    test('«لاحقاً» hides that version for a day', () async {
      // Arrange
      final update = build(_LookupAdapter([_listing()]));
      final release = (await update.pending())!;
      await update.snooze(release);
      now = now.add(const Duration(hours: 23));

      // Act
      final again = await update.pending();

      // Assert
      expect(again, isNull);
    });

    test('a day later the same version is announced again', () async {
      // Arrange
      final update = build(_LookupAdapter([_listing()]));
      final release = (await update.pending())!;
      await update.snooze(release);
      now = now.add(const Duration(hours: 25));

      // Act
      final again = await update.pending();

      // Assert
      expect(again?.version, '1.13.0');
    });

    test('a newer version than the one snoozed is announced at once', () async {
      // Arrange
      final adapter = _LookupAdapter([_listing()]);
      final update = build(adapter);
      final release = (await update.pending())!;
      await update.snooze(release);
      now = now.add(const Duration(hours: 2));
      adapter.results
        ..clear()
        ..add(_listing(version: '1.14.0'));

      // Act
      final again = await update.pending();

      // Assert
      expect(again?.version, '1.14.0');
    });
  });
}
