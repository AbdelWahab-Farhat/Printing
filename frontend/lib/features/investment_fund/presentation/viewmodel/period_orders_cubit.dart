import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:dayaa/features/investment_fund/usecases/investment_fund_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'period_orders_cubit.freezed.dart';

/// ترتيبُ قائمة طلبيات الفترة.
enum PeriodOrdersSort {
  /// بيوم التسليم، وبيوم الطلب لما لم يُسلَّم — كما يرسلها الخادم. قرارُ المالك ٥ في §١١.
  newest('الأحدث'),
  oldest('الأقدم'),
  largest('الأعلى ربحاً');

  const PeriodOrdersSort(this.label);

  final String label;
}

/// شاشةُ الفترة الواحدة: طلبياتُها ومن أخذ منها، وأين ربحُ كلٍّ منها.
///
/// **البحثُ والتصفية هنا لا في الخادم** — قرارُ المالك ٤: الفترةُ شهرٌ يصل كلُّه بنداءٍ واحد،
/// فالتصفيةُ فوريةٌ بلا انتظار. **والمجاميعُ من الخادم وحده**: المرشّحُ يُظهر صفوفاً، ولا
/// يُعيد جمعَها رقماً ثانياً.
class PeriodOrdersCubit extends Cubit<PeriodOrdersState> {
  PeriodOrdersCubit({required GetPeriodOrders getOrders})
    : _getOrders = getOrders,
      super(const PeriodOrdersState.loading());

  final GetPeriodOrders _getOrders;

  Future<void> load(int periodId) async {
    // السحبُ للتحديث لا يُضيّع ما اختاره القارئ: مرشّحُه وبحثُه وترتيبُه يعودون مع الأرقام.
    // **ولا تُستبدل القائمةُ بدوّارٍ أثناءه** — مؤشّرُ السحب يكفي، ومربّعُ البحث لو هُدم لعاد
    // فارغاً والبحثُ ما زال قائماً.
    final kept = state is PeriodOrdersLoaded ? state as PeriodOrdersLoaded : null;

    if (kept == null) emit(const PeriodOrdersState.loading());

    final result = await _getOrders(periodId);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => PeriodOrdersState.failure(failure),
        (loaded) => PeriodOrdersState.loaded(
          loaded,
          filter: kept?.filter,
          query: kept?.query ?? '',
          sort: kept?.sort ?? PeriodOrdersSort.newest,
        ),
      ),
    );
  }

  /// يُطفئه لمسُ المرشّح نفسِه ثانيةً — بطاقةُ المجموع تُشغّله وتُطفئه بلمسةٍ واحدة.
  void filterBy(PeriodOrdersFilter? filter) {
    if (state case final PeriodOrdersLoaded loaded) {
      emit(loaded.copyWith(filter: loaded.filter == filter ? null : filter));
    }
  }

  void search(String query) {
    if (state case final PeriodOrdersLoaded loaded) {
      emit(loaded.copyWith(query: query));
    }
  }

  void sortBy(PeriodOrdersSort sort) {
    if (state case final PeriodOrdersLoaded loaded) {
      emit(loaded.copyWith(sort: sort));
    }
  }
}

@freezed
sealed class PeriodOrdersState with _$PeriodOrdersState {
  const factory PeriodOrdersState.loading() = PeriodOrdersLoading;

  const factory PeriodOrdersState.loaded(
    PeriodOrders held, {
    PeriodOrdersFilter? filter,
    @Default('') String query,
    @Default(PeriodOrdersSort.newest) PeriodOrdersSort sort,
  }) = PeriodOrdersLoaded;

  const factory PeriodOrdersState.failure(Failure failure) = PeriodOrdersFailure;
}

/// ما يُرسم من طلبيات الفترة بعد المرشّح والبحث والترتيب.
///
/// **المرشّحُ يقرأ `states` لا `profitState`** ({@link PeriodOrdersFilter.matches}): طلبيةٌ انقسم
/// ربحُها تقع تحت حالتين، فتظهر تحت كلٍّ منهما — وهو ما يجعل الصفوفَ تحت المرشّح تجمع إلى رقمه.
///
/// والبحثُ برمز الطلبية أو اسم العميل، والأرقامُ العربية تُقرأ لاتينية.
List<PeriodOrder> visiblePeriodOrders(
  List<PeriodOrder> orders, {
  PeriodOrdersFilter? filter,
  String query = '',
  PeriodOrdersSort sort = PeriodOrdersSort.newest,
}) {
  final needle = _latinDigits(query.trim().toLowerCase());

  final shown = orders.where((order) {
    if (filter != null && !filter.matches(order)) return false;
    if (needle.isEmpty) return true;

    return _latinDigits(order.code.toLowerCase()).contains(needle) ||
        (order.customerName?.toLowerCase().contains(needle) ?? false);
  }).toList();

  switch (sort) {
    case PeriodOrdersSort.newest:
      shown.sort((a, b) => _byMoment(b, a));
    case PeriodOrdersSort.oldest:
      shown.sort(_byMoment);
    case PeriodOrdersSort.largest:
      shown.sort((a, b) => _headline(b).compareTo(_headline(a)));
  }

  return shown;
}

/// يومُها، ثم رقمُها — كما يرتّب الخادم، فلا تتبادل طلبيتان من يومٍ واحد مكانَيهما.
int _byMoment(PeriodOrder a, PeriodOrder b) {
  final at = a.occurredAt;
  final bt = b.occurredAt;

  if (at != null && bt != null && at != bt) return at.compareTo(bt);
  if (at == null && bt != null) return -1;
  if (at != null && bt == null) return 1;

  return a.orderId.compareTo(b.orderId);
}

/// الرقمُ الكبير على بطاقتها: ما في الدفتر، أو ما سيصل عند التسليم لطلبيةٍ في الطريق وحدها.
double _headline(PeriodOrder order) {
  final onTheRoadOnly =
      order.profitState == PeriodProfitState.awaitingDelivery && order.investors.isEmpty;
  final figure = onTheRoadOnly ? order.byState?.awaitingDelivery : order.investorsTotal;

  return double.tryParse(figure ?? '') ?? 0;
}

String _latinDigits(String value) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  final buffer = StringBuffer();

  for (final char in value.split('')) {
    final index = arabic.indexOf(char);
    buffer.write(index == -1 ? char : '$index');
  }

  return buffer.toString();
}
