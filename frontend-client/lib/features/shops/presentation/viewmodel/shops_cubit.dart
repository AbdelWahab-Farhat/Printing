import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/shops/models/shop.dart';
import 'package:dayaa_client/features/shops/usecases/list_shops.dart';
import 'package:dayaa_client/features/shops/usecases/remove_shop.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shops_cubit.freezed.dart';
part 'shops_state.dart';

/// الـ ViewModel لـ«متاجري».
///
/// **القائمة تُرقَّع ولا تُعاد قراءتها.** المتجر الذي يُحفظ في النموذج يعود منه كما قبله الخادم،
/// فيوضع في مكانه — إضافةٌ في آخر القائمة، وتعديلٌ في موضعه — بلا طلبٍ ثانٍ لما يعرفه التطبيق أصلاً.
class ShopsCubit extends Cubit<ShopsState> {
  ShopsCubit({required ListShops list, required RemoveShop remove})
    : _list = list,
      _remove = remove,
      super(const ShopsState.loading());

  final ListShops _list;
  final RemoveShop _remove;

  Future<void> load() async {
    emit(const ShopsState.loading());

    final result = await _list();

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => ShopsState.failure(failure),
        (shops) => ShopsState.loaded(shops),
      ),
    );
  }

  /// متجرٌ عاد من النموذج محفوظاً: يحلّ محلّ نفسه إن كان في القائمة، ويُضاف آخرها إن كان جديداً —
  /// حيث يضعه الخادم، لأن القائمة بترتيب الإضافة.
  void saved(Shop shop) {
    final loaded = _loaded;
    if (loaded == null) return;

    final index = loaded.shops.indexWhere((existing) => existing.id == shop.id);
    final shops = [...loaded.shops];

    if (index >= 0) {
      shops[index] = shop;
    } else {
      shops.add(shop);
    }

    emit(ShopsState.loaded(shops));
  }

  /// يحذف متجراً. **القائمة تبقى على الشاشة أثناء الطلب**، والرفض يعيدها كما كانت ومعه سببه.
  Future<void> remove(int id) async {
    final loaded = _loaded;
    if (loaded == null || loaded.isBusy) return;

    emit(loaded.copyWith(isBusy: true, lastFailure: null));

    final result = await _remove(id);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => loaded.copyWith(isBusy: false, lastFailure: failure),
        (_) => ShopsState.loaded([...loaded.shops.where((shop) => shop.id != id)]),
      ),
    );
  }

  ShopsLoaded? get _loaded => switch (state) {
    final ShopsLoaded loaded => loaded,
    _ => null,
  };
}
