import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/social_links/models/social_link.dart';
import 'package:dayaa_client/features/social_links/repositories/social_link_repository.dart';

/// روابط العميل، بترتيب إضافتها.
class ListSocialLinks {
  const ListSocialLinks(this._repository);

  final SocialLinkRepository _repository;

  Future<Either<Failure, List<SocialLink>>> call() => _repository.list();
}
