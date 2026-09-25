import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/shops/models/shop.dart';
import 'package:dayaa_client/features/shops/repositories/shop_repository.dart';

/// يضيف متجراً بجانب ما عند العميل.
class AddShop {
  const AddShop(this._repository);

  final ShopRepository _repository;

  Future<Either<Failure, Shop>> call({
    required String name,
    required int cityId,
    int? regionId,
    int? businessFieldId,
    String? pageUrl,
  }) => _repository.add(
    name: name,
    cityId: cityId,
    regionId: regionId,
    businessFieldId: businessFieldId,
    pageUrl: pageUrl,
  );
}
