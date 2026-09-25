import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/shops/repositories/shop_repository.dart';

/// يُخرج متجراً من القائمة. **يُخفى على الخادم ولا يُمحى**: الطلبيات التي ذهبت إليه تبقى تسمّيه.
class RemoveShop {
  const RemoveShop(this._repository);

  final ShopRepository _repository;

  Future<Either<Failure, Unit>> call(int id) => _repository.remove(id);
}
