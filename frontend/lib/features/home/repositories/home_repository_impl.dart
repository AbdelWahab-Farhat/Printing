import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/home/models/home_summary.dart';
import 'package:printing/features/home/repositories/home_repository.dart';

/// ⚠️ **Placeholder data.** Nothing here has been near the server yet.
///
/// The orders module does not exist on the backend, so there is no `GET /home/summary` to call.
/// Rather than leave the screen empty until it does, this returns a fixed snapshot in the exact
/// shape the endpoint will return — which is what lets the screen, the Cubit and their tests be
/// finished and reviewed now.
///
/// **What changes when the endpoint lands:** this file, and only this file. The body of
/// [summary] becomes
///
/// ```dart
/// safeRequest(() => _dio.get<Map<String, dynamic>>(HomeEndpoints.summary), HomeSummary.fromJson)
/// ```
///
/// — the same `Either<Failure, HomeSummary>` out of the same method, so no caller notices. The
/// models already carry their `@JsonKey` names, so the wire format is settled too.
///
/// The statuses below are the ones the current paper workflow uses; they are placeholders in
/// the same sense as the numbers, and become the app's own statuses when orders are modelled.
class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl();

  @override
  Future<Either<Failure, HomeSummary>> summary() async {
    // The delay is deliberate: without it the loading state never renders, and a skeleton
    // nobody has seen is a skeleton nobody has checked.
    await Future<void>.delayed(const Duration(milliseconds: 400));

    return right(_placeholder);
  }

  static const HomeSummary _placeholder = HomeSummary(
    totalOrders: 9651,
    customersCount: 8041,
    dailyOrders: 5,
    monthlyOrders: 34,
    statuses: [
      OrderStatusCount(status: 'new', label: 'الجديدة', count: 72, needsAttention: true),
      OrderStatusCount(status: 'under_review', label: 'قيد المراجعة', count: 10),
      OrderStatusCount(
        status: 'deposit_unpaid',
        label: 'عرابين لم تراجع',
        count: 816,
        needsAttention: true,
      ),
      OrderStatusCount(status: 'deposit_paid', label: 'عربون مدفوع', count: 228),
      OrderStatusCount(status: 'deposit_delivery', label: 'توصيل عربون', count: 112),
      OrderStatusCount(status: 'missing_after_purchase', label: 'نواقص بعد شراء', count: 14),
      OrderStatusCount(status: 'rejected', label: 'مرفوض', count: 76),
    ],
  );
}
