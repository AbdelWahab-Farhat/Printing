import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/social_links/models/social_link.dart';
import 'package:dayaa_client/features/social_links/models/social_platform.dart';
import 'package:dayaa_client/features/social_links/repositories/social_link_repository.dart';

/// يحفظ روابط العميل مجموعةً واحدة.
///
/// **هنا يصير ما كُتب ما يقبله الخادم، مرةً واحدة:** المسافات حول الرابط تُنزع، و`https://` يُضاف
/// إلى رابطٍ كُتب بدونها — الخادم يقبل روابط الويب وحدها، و«instagram.com/alnoor» ما يكتبه الناس.
class SaveSocialLinks {
  const SaveSocialLinks(this._repository);

  final SocialLinkRepository _repository;

  Future<Either<Failure, List<SocialLink>>> call(List<SocialLinkInput> links) => _repository.save([
    for (final link in links) (id: link.id, url: normalizeSocialLink(link.url)),
  ]);
}
