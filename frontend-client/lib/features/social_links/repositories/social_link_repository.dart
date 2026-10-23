import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/social_links/models/social_link.dart';

/// «روابط التواصل» — روابط العميل، تُقرأ وتُحفظ مجموعةً واحدة.
///
/// **لا مُعرِّف عميلٍ يُرسل.** الخادم يأخذه من التوكن، فلا شيء هنا يشير إلى روابط غيره.
abstract interface class SocialLinkRepository {
  /// روابطه كلها، بترتيب إضافتها. بلا صفحات: عشرةٌ على الأكثر.
  Future<Either<Failure, List<SocialLink>>> list();

  /// يحفظ المجموعة كلها ويعيدها كما حفظها الخادم: سطرٌ بمُعرِّفه يُعدَّل، وبلا مُعرِّف يُضاف، وما غاب
  /// عنها يُحذف — فقائمةٌ فارغة تحذفها كلها.
  Future<Either<Failure, List<SocialLink>>> save(List<SocialLinkInput> links);
}
