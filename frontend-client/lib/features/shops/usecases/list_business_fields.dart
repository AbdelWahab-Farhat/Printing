import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/shops/models/shop.dart';
import 'package:dayaa_client/features/shops/repositories/shop_repository.dart';

/// ما يعرضه منتقي «مجال العمل» في نموذج المتجر.
class ListBusinessFields {
  const ListBusinessFields(this._repository);

  final ShopRepository _repository;

  Future<Either<Failure, List<BusinessField>>> call() => _repository.businessFields();
}
