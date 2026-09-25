import 'package:dayaa_client/features/shops/models/shop.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// الـ ViewModel لصفحة المتجر: المتجر كما هو الآن.
///
/// **يُفتح على المتجر الذي في القائمة ولا يطلبه ثانيةً** — «متاجري» جلبته للتوّ. وما يتغيّر بعدها
/// يصل من نموذج المتجر محفوظاً كما قبله الخادم، فيحلّ محلّ ما كان.
class ShopDetailsCubit extends Cubit<Shop> {
  ShopDetailsCubit(super.shop);

  /// المتجر عائداً من نموذج التعديل.
  void edited(Shop shop) {
    if (shop.id != state.id) return;

    emit(shop);
  }
}
