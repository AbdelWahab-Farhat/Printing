import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/shops/models/shop.dart';
import 'package:dayaa_client/features/shops/repositories/shop_repository.dart';

/// يعدّل متجراً كما يعرضه النموذج.
class UpdateShop {
  const UpdateShop(this._repository);

  final ShopRepository _repository;

  Future<Either<Failure, Shop>> call({
    required int id,
    required String name,
    required int cityId,
    int? regionId,
    int? businessFieldId,
    String? pageUrl,
  }) => _repository.update(
    id: id,
    name: name,
    cityId: cityId,
    regionId: regionId,
    businessFieldId: businessFieldId,
    pageUrl: pageUrl,
  );
}
