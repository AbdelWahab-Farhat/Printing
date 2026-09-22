import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investment_fund/usecases/investment_fund_usecases.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/usecases/purchase_order_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'save_purchase_order_cubit.freezed.dart';
part 'save_purchase_order_state.dart';

/// The ViewModel behind the purchase-order form.
///
/// It holds no draft: the form owns its controllers and its line list, because those are
/// widget-lifecycle resources that must be disposed.
class SavePurchaseOrderCubit extends Cubit<SavePurchaseOrderState> {
  SavePurchaseOrderCubit({
    required SavePurchaseOrder saveOrder,
    required BuyWithFund buyWithFund,
  }) : _saveOrder = saveOrder,
       _buyWithFund = buyWithFund,
       super(const SavePurchaseOrderState.initial());

  final SavePurchaseOrder _saveOrder;

  /// بابُ الصندوق، يُطرق بعد الحفظ وبرقم الأمر الذي عاد منه.
  final BuyWithFund _buyWithFund;

  /// **[funding] يجعل الحفظَ فعلين في ضغطةٍ واحدة**: يُكتب الأمر، ثم يشتريه الصندوق برقمه.
  ///
  /// الترتيبُ ليس تفضيلاً — لا رقمَ لأمرٍ لم يُكتب بعد، ولا يُموَّل ما لا رقم له. ولأن الفعلين
  /// ليسا معاملةً واحدة على الخادم، فالثاني قد يسقط وحده: يردّ الخادمُ «لا يكفي النقد» والأمرُ
  /// مكتوبٌ على كل حال. فتلك ليست حالةَ فشل — {@see SavePurchaseOrderState.success} تحملها في
  /// `fundingFailure` — والشاشةُ تُغلق على الأمر وتقول ما لم يقع.
  Future<void> submit({
    int? id,
    required int vendorId,
    required int warehouseId,
    required String orderDate,
    required List<DraftLine> items,
    List<DraftAdditionalCost> additionalCosts = const [],
    String? expectedDate,
    String? notes,
    FundPurchaseRequest? funding,
  }) async {
    // Ignored rather than queued: a second tap while the first is in flight is a second POST,
    // and a purchase order has no natural key the server could dedupe on — it would be two
    // orders against the same supplier for the same goods.
    if (state.isSubmitting) return;

    emit(const SavePurchaseOrderState.submitting());

    final result = await _saveOrder(
      id: id,
      vendorId: vendorId,
      warehouseId: warehouseId,
      orderDate: orderDate,
      items: items,
      additionalCosts: additionalCosts,
      expectedDate: expectedDate,
      notes: notes,
    );

    if (isClosed) return;

    final saved = result.fold((failure) {
      emit(SavePurchaseOrderState.failure(failure));

      return null;
    }, (order) => order);

    // رُفض الأمرُ نفسُه، فلا شيءَ يُموَّل.
    if (saved == null) return;

    if (funding == null) {
      emit(SavePurchaseOrderState.success(saved));

      return;
    }

    // الحالةُ تبقى `submitting` حتى يفرغ البابان: الزرُّ يدور، ولا تُغلق الشاشةُ على تمويلٍ ما
    // زال في الطريق.
    final funded = await _buyWithFund(saved.id, funding);

    if (isClosed) return;

    emit(
      SavePurchaseOrderState.success(
        saved,
        fundingFailure: funded.fold((failure) => failure, (_) => null),
      ),
    );
  }

  void clearFailure() {
    if (state is SavePurchaseOrderFailure) {
      emit(const SavePurchaseOrderState.initial());
    }
  }
}
