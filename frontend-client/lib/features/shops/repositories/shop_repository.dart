import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/shops/models/shop.dart';

/// «متاجري» — متاجر العميل، يضيف منها ما يشاء.
///
/// **لا مُعرِّف عميلٍ يُرسل، ولا يمكن أن يُرسل.** الخادم يأخذه من التوكن، فلا شيء هنا يشير إلى متاجر
/// غيره.
abstract interface class ShopRepository {
  /// متاجره كلها، بترتيب إضافتها — الأول هو الذي فُتح به الحساب. بلا صفحات: بضعةٌ لا مئات.
  Future<Either<Failure, List<Shop>>> list();

  /// يضيف متجراً بجانب ما عنده، ولا يحلّ محلّ شيء.
  Future<Either<Failure, Shop>> add({
    required String name,
    required int cityId,
    int? regionId,
    int? businessFieldId,
    String? pageUrl,
  });

  /// المتجر كاملاً كما يعرضه النموذج. الإحداثيات وحدها لا تُرسل، والخادم يبقيها كما هي.
  Future<Either<Failure, Shop>> update({
    required int id,
    required String name,
    required int cityId,
    int? regionId,
    int? businessFieldId,
    String? pageUrl,
  });

  /// يُخفى من القائمة، والطلبيات التي ذهبت إليه تبقى تسمّيه.
  Future<Either<Failure, Unit>> remove(int id);

  /// مجالات العمل المعروضة لمنتقي النموذج، بترتيب المتجر.
  Future<Either<Failure, List<BusinessField>>> businessFields();
}
