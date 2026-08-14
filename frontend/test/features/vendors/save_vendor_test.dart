import 'package:dayaa/features/vendors/repositories/vendor_repository_impl.dart';
import 'package:dayaa/features/vendors/usecases/save_vendor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Adding and correcting a supplier.
///
/// **The one thing worth pinning is the phone.** The server's rule is `regex:/^\d{9,15}$/` —
/// ASCII digits only — and a Libyan keyboard produces «٠٩١…», which earns a 422 pointing at a
/// field the user filled in correctly.
///
/// Arrange - Act - Assert throughout.
void main() {
  late Dio dio;
  late SaveVendor save;
  late RequestOptions captured;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.reject(
            DioException(requestOptions: options, message: 'captured'),
            true,
          );
        },
      ),
    );
    save = SaveVendor(VendorRepositoryImpl(dio));
  });

  test('no id adds; an id corrects the supplier it names', () async {
    // Act
    await save(name: 'شركة الأوراق', phone: '0912345678');
    final adding = captured;

    await save(id: 12, name: 'شركة الأوراق', phone: '0912345678');

    // Assert — one endpoint each, and the id decides which.
    expect(adding.method, 'POST');
    expect(adding.path, '/vendors');
    expect(captured.method, 'PUT');
    expect(captured.path, '/vendors/12');
  });

  test('an Arabic-Indic phone reaches the server as digits', () async {
    // Act
    await save(name: 'مورد', phone: '٠٩١٢٣٤٥٦٧٨');

    // Assert
    final body = captured.data as Map<String, dynamic>;

    expect(body['phone'], '0912345678');
  });

  test('an empty optional box is null, not an empty string', () async {
    // Act — «الشخص المسؤول» left blank is "nothing recorded", which the API spells null. An
    // empty string would be a value: a contact person whose name is blank.
    await save(name: 'مورد', phone: '0912345678', contactPerson: '   ', email: '');

    // Assert
    final body = captured.data as Map<String, dynamic>;

    expect(body['contact_person'], isNull);
    expect(body['email'], isNull);
  });

  test('a save never carries is_active', () async {
    // Act
    await save(id: 12, name: 'مورد', phone: '0912345678');

    // Assert — the API refuses it here: retiring a supplier is its own endpoint, so that
    // "I corrected their phone" and "I stopped dealing with them" can never be one request.
    expect((captured.data as Map<String, dynamic>).containsKey('is_active'), isFalse);
  });

  test('retiring one is a PATCH to its own path', () async {
    // Arrange
    final setActive = SetVendorActive(VendorRepositoryImpl(dio));

    // Act
    await setActive(12, isActive: false);

    // Assert
    expect(captured.method, 'PATCH');
    expect(captured.path, '/vendors/12/activation');
    expect(captured.data, {'is_active': false});
  });
}
