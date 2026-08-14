import 'package:dayaa/features/location/repositories/geocoding_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// What actually goes out to the geocoder, and what comes back.
///
/// Arrange - Act - Assert throughout.
class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late GeocodingRepositoryImpl repository;

  Response<dynamic> ok(dynamic body) => Response<dynamic>(
    data: body,
    statusCode: 200,
    requestOptions: RequestOptions(path: '/search'),
  );

  setUp(() {
    dio = _MockDio();
    repository = GeocodingRepositoryImpl(dio);
  });

  void arrange(dynamic body) {
    when(
      () => dio.get<dynamic>(any(), queryParameters: any(named: 'queryParameters')),
    ).thenAnswer((_) async => ok(body));
  }

  Map<String, dynamic> sentQuery() {
    final captured = verify(
      () => dio.get<dynamic>(captureAny(), queryParameters: captureAny(named: 'queryParameters')),
    ).captured;

    return captured.last as Map<String, dynamic>;
  }

  test('the search is confined to Libya and asked for in Arabic', () async {
    // Arrange — without countrycodes, «الزاوية» comes back from five countries and the right
    // answer is on page two. Without accept-language, half of Libya answers with a
    // transliteration nobody recognises.
    arrange(<dynamic>[]);

    // Act
    await repository.search('الزاوية');

    // Assert
    final query = sentQuery();
    expect(query['q'], 'الزاوية');
    expect(query['countrycodes'], 'ly');
    expect(query['accept-language'], 'ar');
    expect(query['format'], 'jsonv2');
    expect(query['limit'], 6);
  });

  test('a result becomes a place with a real point', () async {
    // Arrange — the geocoder sends the coordinates as strings.
    arrange(<dynamic>[
      {'lat': '32.8872', 'lon': '13.1913', 'display_name': 'سوق الجمعة، طرابلس، ليبيا'},
    ]);

    // Act
    final result = await repository.search('سوق الجمعة');

    // Assert
    final places = result.getOrElse(() => []);
    expect(places, hasLength(1));
    expect(places.single.point.latitude, 32.8872);
    expect(places.single.point.longitude, 13.1913);
    expect(places.single.title, 'سوق الجمعة');
    expect(places.single.subtitle, 'طرابلس، ليبيا');
  });

  test('one unreadable row does not empty the list', () async {
    // Arrange — a search is not a record; there is nothing to lose by skipping a row nobody
    // could have used, and everything to lose by throwing away the five that were fine.
    arrange(<dynamic>[
      {'lat': 'not a number', 'lon': '13.1913', 'display_name': 'خطأ'},
      {'lat': '32.8872', 'lon': '13.1913', 'display_name': 'طرابلس'},
    ]);

    // Act
    final result = await repository.search('طرابلس');

    // Assert
    expect(result.getOrElse(() => []), hasLength(1));
  });

  test('nothing found is an answer, not a failure', () async {
    // Arrange — for a small Libyan town this is the ordinary outcome.
    arrange(<dynamic>[]);

    // Act
    final result = await repository.search('قرية صغيرة');

    // Assert
    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => [const _Never()].cast()), isEmpty);
  });

  test('a body that is not a list is empty, not a crash', () async {
    // Arrange — a proxy or a captive portal answering HTML is the realistic case.
    arrange('<html>403</html>');

    // Act
    final result = await repository.search('طرابلس');

    // Assert
    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => [const _Never()].cast()), isEmpty);
  });
}

/// Only ever used to give `getOrElse` a non-empty fallback, so an empty *result* is
/// distinguishable from the fallback itself.
class _Never {
  const _Never();
}
