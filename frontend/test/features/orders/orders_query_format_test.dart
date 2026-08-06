import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/orders/repositories/order_repository_impl.dart';

/// How a repeatable filter reaches the API.
///
/// **This file exists because of a bug that cost a whole queue.** Dio's default list format
/// writes `status=a&status=b`, and PHP keeps only the last of those — so «رواجع», which covers
/// four statuses and ends in `resend`, counted four orders and displayed none. The two grouped
/// queues before it were wrong more quietly: «قيد التنفيذ» showed the printing orders and
/// dropped the ones being designed, and nothing on screen said so.
///
/// The fix is one line on the shared client ([DioClient]), and it is invisible — which is
/// exactly why the shape is pinned here rather than trusted to stay.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// Stops every request at the door and keeps the URI it was about to send.
  late _CaptureUri capture;
  late OrderRepositoryImpl repository;

  setUp(() {
    capture = _CaptureUri();
    repository = OrderRepositoryImpl(
      Dio(
        BaseOptions(
          baseUrl: 'http://test/api/v1',
          // The same setting the real client carries. A test that built a plain `Dio()` would
          // pass while the app failed, which is the only way this test could be useless.
          listFormat: ListFormat.multiCompatible,
        ),
      )..interceptors.add(capture),
    );
  });

  test('a queue sends every status with brackets, so PHP reads an array', () async {
    // Arrange - Act
    await repository.orders(
      statuses: const [
        'returned_courier',
        'returned_carrier',
        'returned_office',
        'resend',
      ],
    );

    // Assert — `status[]=` four times. Without the brackets PHP sees `status=resend` alone.
    final query = capture.uri!.query;

    expect(query, contains('status%5B%5D=returned_courier'));
    expect(query, contains('status%5B%5D=returned_carrier'));
    expect(query, contains('status%5B%5D=returned_office'));
    expect(query, contains('status%5B%5D=resend'));

    // And the API really does receive four of them.
    expect(
      capture.uri!.queryParametersAll['status[]'],
      ['returned_courier', 'returned_carrier', 'returned_office', 'resend'],
    );
  });

  test('the payment filter is repeatable the same way', () async {
    // Arrange — «أرِني ما لم يُدفع» is two states at once, and it would have been broken by the
    // same default the day it shipped.
    // Act
    await repository.orders(paymentStatuses: const ['unpaid', 'partially_paid']);

    // Assert
    expect(
      capture.uri!.queryParametersAll['payment_status[]'],
      ['unpaid', 'partially_paid'],
    );
  });

  test('an empty filter is not sent at all', () async {
    // Arrange — a `status[]=` with nothing after it is a filter nothing satisfies.
    // Act
    await repository.orders();

    // Assert
    expect(capture.uri!.query, isNot(contains('status')));
    expect(capture.uri!.query, isNot(contains('payment_status')));
  });

  /// The tests above build their own `Dio` with the right setting, which proves the repository
  /// but would happily pass while the app shipped the default. This reads the real client the
  /// way `permission_contract_test.dart` reads the PHP enum: the guard has to be on the file
  /// that the app actually uses.
  test('the shared client is the one that carries the setting', () {
    // Arrange
    final client = File('lib/core/network/dio_client.dart').readAsStringSync();

    // Act - Assert
    expect(
      client,
      contains('listFormat: ListFormat.multiCompatible'),
      reason: 'without it every repeatable filter silently narrows to its last value',
    );
  });

  test('both axes travel together', () async {
    // Arrange — «جاهزة وغير مدفوعة» is one question with two answers applied at once.
    // Act
    await repository.orders(
      statuses: const ['ready'],
      paymentStatuses: const ['unpaid'],
    );

    // Assert
    expect(capture.uri!.queryParametersAll['status[]'], ['ready']);
    expect(capture.uri!.queryParametersAll['payment_status[]'], ['unpaid']);
  });
}

/// Rejects every request, keeping the URI it would have gone to.
///
/// Rejecting rather than answering: this file is about what leaves the phone, and a fake
/// response would only add a body nothing here reads.
class _CaptureUri extends Interceptor {
  Uri? uri;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    uri = options.uri;

    handler.reject(DioException(requestOptions: options, message: 'captured'), true);
  }
}
