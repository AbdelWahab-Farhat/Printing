import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/api_endpoints.dart';
import 'package:dayaa_client/core/network/safe_request.dart';
import 'package:dayaa_client/features/social_links/models/social_link.dart';
import 'package:dayaa_client/features/social_links/repositories/social_link_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [SocialLinkRepository] over HTTP.
class SocialLinkRepositoryImpl implements SocialLinkRepository {
  const SocialLinkRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, List<SocialLink>>> list() {
    return safeRequest<List<SocialLink>>(
      () => _dio.get(SocialLinkEndpoints.index),
      parse: _parse,
    );
  }

  @override
  Future<Either<Failure, List<SocialLink>>> save(List<SocialLinkInput> links) {
    return safeRequest<List<SocialLink>>(
      () => _dio.put(
        SocialLinkEndpoints.index,
        // **المفتاح يُرسل دائماً**، وقائمته الفارغة «احذفها كلها»: الخادم يرفض طلباً بلا القائمة.
        // والمُعرِّف يُحذف حين لا يكون — غيابه ما يقرؤه الخادم «رابطٌ جديد».
        data: <String, dynamic>{
          'social_links': [
            for (final link in links) <String, dynamic>{'id': ?link.id, 'url': link.url},
          ],
        },
      ),
      parse: _parse,
    );
  }

  static List<SocialLink> _parse(Object? data) => (data as List<dynamic>)
      .map((item) => SocialLink.fromJson(item as Map<String, dynamic>))
      .toList();
}
