import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/files/picked_file.dart';
import 'package:dayaa_client/core/network/api_endpoints.dart';
import 'package:dayaa_client/core/network/safe_request.dart';
import 'package:dayaa_client/core/print_colors/print_color.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/repositories/design_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [DesignRepository] over HTTP.
class DesignRepositoryImpl implements DesignRepository {
  const DesignRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, List<CustomerDesign>>> list() {
    return safeRequest<List<CustomerDesign>>(
      () => _dio.get(DesignEndpoints.index),
      parse: (data) => (data as List<dynamic>)
          .map((item) => CustomerDesign.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<Either<Failure, CustomerDesign>> upload({
    required PickedFile file,
    String? label,
    List<PrintColor> printColors = const [],
  }) async {
    // `multipart/form-data`, because the server reads the magic bytes with finfo rather than
    // trusting a name or a Content-Type header — so the bytes have to arrive as bytes.
    //
    // `multiCompatible` writes the colors as `print_colors[0][name]`, the shape PHP reads back
    // as a list.
    final form = FormData.fromMap(<String, dynamic>{
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
      if (label != null && label.trim().isNotEmpty) 'label': label.trim(),
      if (printColors.isNotEmpty) 'print_colors': PrintColor.listToJson(printColors),
    }, ListFormat.multiCompatible);

    return safeRequest<CustomerDesign>(
      () => _dio.post(DesignEndpoints.store, data: form),
      parse: (data) => CustomerDesign.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, CustomerDesign>> rename({
    required int id,
    required String label,
  }) {
    return safeRequest<CustomerDesign>(
      () => _dio.patch(
        DesignEndpoints.design(id),
        data: <String, dynamic>{'label': label.trim()},
      ),
      parse: (data) => CustomerDesign.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, CustomerDesign>> setColors({
    required int id,
    required List<PrintColor> colors,
  }) {
    return safeRequest<CustomerDesign>(
      // Always sent, empty included: the server asks for the key, and an empty list clears.
      () => _dio.put(
        DesignEndpoints.colors(id),
        data: <String, dynamic>{'print_colors': PrintColor.listToJson(colors)},
      ),
      parse: (data) => CustomerDesign.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Unit>> remove(int id) async {
    final result = await safeCommand(() => _dio.delete(DesignEndpoints.design(id)));

    return result.map((_) => unit);
  }

  @override
  Future<Either<Failure, Uint8List>> fileBytes(String fileUrl) {
    return safeDownload(
      // الرابط كاملٌ وقد يشير إلى مضيف التخزين لا إلى الـ API، فيُمرَّر كما هو: Dio لا يضيف
      // `baseUrl` إلى عنوانٍ كامل. و`bytes` كي لا يحاول Dio أن يقرأ صورةً على أنها JSON.
      () => _dio.get<List<int>>(
        fileUrl,
        options: Options(
          responseType: ResponseType.bytes,
          // ملف الطباعة ميغابايتات على اتصالٍ محمول، ومهلة الاستلام المضبوطة لصفحة JSON
          // تتركه في منتصفه.
          receiveTimeout: const Duration(minutes: 2),
        ),
      ),
    );
  }
}
