import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/shops/models/shop.dart';
import 'package:dayaa_client/features/shops/repositories/shop_repository.dart';

/// متاجر العميل، بترتيب إضافتها.
class ListShops {
  const ListShops(this._repository);

  final ShopRepository _repository;

  Future<Either<Failure, List<Shop>>> call() => _repository.list();
}
