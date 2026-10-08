import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/payment_settlement.dart';

/// الزمنُ الذي تُضيَّق به قائمتا «مراجعة وتسوية الدفعات» — قرار صاحب العمل ٢٠٢٦-١٠-٠٨.
///
/// **الأزرار تحت البحث** (الكل · اليوم · هذا الأسبوع · هذا الشهر) و**«من» / «إلى» في الفلتر
/// المتقدّم**، كلٌّ منهما يمكن أن يُترك فارغاً. لا زرَّ لـ«من – إلى»: التاريخان حقلان في الفلتر،
/// وما داما مضبوطين فالفترةُ [SettlementPeriod.custom] ولا زرَّ مختاراً.
///
/// مشتركٌ بين `PaymentReviewQueueCubit` و`PaymentSettlementCubit` كي يقرأ الزرّان والتاريخان
/// الشيءَ نفسه في التبويبين.
mixin PaymentPeriodFilter on PagedCubit<OrderPayment> {
  /// The phone's clock — injected, so that «هذا الأسبوع» can be tested without one.
  DateTime clock();

  /// «الكل» to begin with — the owner's choice, 2026-10-08: a work list, where a payment left from
  /// last week is the one most worth finding.
  SettlementPeriod period = SettlementPeriod.all;

  /// «من» and «إلى» from the advanced filter, either one open. Set only while [period] is
  /// [SettlementPeriod.custom].
  ({DateTime? from, DateTime? to})? customRange;

  /// The days the list is narrowed to, or null for «الكل».
  ({DateTime? from, DateTime? to})? get range => switch (period) {
    SettlementPeriod.custom => customRange,
    _ => period.rangeAt(clock()),
  };

  /// A chip. It forgets the advanced dates, and keeps what is typed in the search box.
  Future<void> showPeriod(SettlementPeriod value) {
    if (value == period) return Future<void>.value();

    period = value;
    customRange = null;

    return load(search: currentSearch);
  }

  /// Takes the advanced filter's «من» / «إلى» without loading — the caller loads once, after the
  /// rest of the sheet is applied too.
  ///
  /// A date makes the period [SettlementPeriod.custom]. No dates after a custom range go back to
  /// «الكل», the default; no dates otherwise leave the chip that was picked.
  void adoptDates({DateTime? from, DateTime? to}) {
    if (from != null || to != null) {
      period = SettlementPeriod.custom;
      customRange = (from: from, to: to);
    } else if (period == SettlementPeriod.custom) {
      period = SettlementPeriod.all;
      customRange = null;
    }
  }
}
