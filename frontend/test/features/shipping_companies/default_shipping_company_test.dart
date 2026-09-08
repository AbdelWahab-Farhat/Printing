import 'dart:convert';
import 'dart:typed_data';

import 'package:dayaa/features/shipping_companies/models/shipping_company.dart';
import 'package:dayaa/features/shipping_companies/presentation/widgets/shipping_company_card.dart';
import 'package:dayaa/features/shipping_companies/repositories/shipping_company_repository_impl.dart';
import 'package:dayaa/features/shipping_companies/usecases/save_shipping_company.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «الشركة الافتراضية» — the carrier a dispatch form opens on.
///
/// **A fact about the list rather than about the row**, which is why it travels on every save:
/// the form sends the whole record, and a save that stayed silent about the flag would leave the
/// server guessing whether the person meant to move it. The server's own rule — that silence
/// means «اتركها كما هي» — is what protects the clients that have not been updated yet, and this
/// app is not one of them.
///
/// Arrange - Act - Assert throughout.
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter({this.isDefault = true});

  final bool isDefault;

  String? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      body = utf8.decode(chunks.expand((chunk) => chunk).toList());
    }

    return ResponseBody.fromString(
      jsonEncode({
        'status': true,
        'message': 'تم تحديث شركة التوصيل بنجاح',
        'data': {
          'id': 9,
          'name': 'النورس',
          'phone': '0911234567',
          'notes': null,
          'is_active': true,
          'is_default': isDefault,
          'created_at': '2026-09-08T10:00:00+00:00',
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('the flag on the wire', () {
    test('a save says which company the dispatch form should open on', () async {
      // Arrange
      final adapter = _CapturingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = adapter;
      final save = SaveShippingCompany(ShippingCompanyRepositoryImpl(dio));

      // Act
      await save(id: 9, name: 'النورس', phone: '0911234567', isDefault: true);

      // Assert — sent as a real boolean beside the rest of the record, never left out.
      expect(jsonDecode(adapter.body!), containsPair('is_default', true));
    });

    test('the company that comes back knows whether it is the default', () async {
      // Arrange
      final adapter = _CapturingAdapter(isDefault: false);
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = adapter;
      final save = SaveShippingCompany(ShippingCompanyRepositoryImpl(dio));

      // Act
      final result = await save(id: 9, name: 'النورس');

      // Assert — the row the list redraws is the server's answer, flag included.
      expect(result.getOrElse(() => throw StateError('refused')).isDefault, isFalse);
    });

    test('a company from a server too old to know the flag is simply not the default', () {
      // Arrange
      final json = <String, dynamic>{'id': 3, 'name': 'درب', 'is_active': true};

      // Act
      final company = ShippingCompany.fromJson(json);

      // Assert — absent is «لا», not a crash: nobody named it, so nobody prefers it.
      expect(company.isDefault, isFalse);
    });
  });

  group('the row in the list', () {
    Widget host(Widget card) {
      return ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => MaterialApp(
          home: Scaffold(
            body: Directionality(textDirection: TextDirection.rtl, child: card),
          ),
        ),
      );
    }

    testWidgets('the default carrier is marked as such', (tester) async {
      // Arrange
      const company = ShippingCompany(id: 9, name: 'النورس', isDefault: true);

      // Act
      await tester.pumpWidget(host(const ShippingCompanyCard(company: company)));
      await tester.pumpAndSettle();

      // Assert — which one a dispatch opens on is answered by the list itself, rather than by
      // opening each company in turn to find out.
      expect(find.text('الافتراضية'), findsOneWidget);
    });

    testWidgets('a company we stopped dealing with is still marked «متوقفة»', (tester) async {
      // Arrange — the two badges cannot both be true of a live row, and being retired is the
      // one that changes what the picker will show.
      const company = ShippingCompany(id: 3, name: 'درب', isActive: false);

      // Act
      await tester.pumpWidget(host(const ShippingCompanyCard(company: company)));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('متوقفة'), findsOneWidget);
    });
  });
}
