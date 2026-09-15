import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:dayaa/features/shortages/models/shortage_counts.dart';
import 'package:dayaa/features/shortages/models/shortage_supply.dart';

/// النواقص, as this app asks about them.
///
/// **The list already excludes shortages whose order is archived** unless the reader holds
/// `orders.archive.view`. There is nothing for the app to filter out.
///
/// Sorted newest first, always, and there is no sort parameter. Completed rows are not buried:
/// within a month of shipping «مكتمل» will be the majority of the table, and hiding it would make
/// the historical record reachable only by filtering — the chip row above the list is what makes
/// that readable instead.
abstract class ShortageRepository {
  /// One page of them.
  ///
  /// [assignedTo] takes a user id as a string, **`'me'`** or **`'none'`** — two of the three are
  /// not ids: «me» is only knowable on the server from the bearer token, and «none» is a null a
  /// query string cannot otherwise carry.
  ///
  /// [search] matches the shortage's own name, its code (`N7`), **or the order's code**.
  Future<Either<Failure, Paginated<Shortage>>> shortages({
    List<String> statuses = const <String>[],
    String? assignedTo,
    int? productId,
    int? orderId,
    int? customerId,
    String? source,
    String? search,
    int page = 1,
    int perPage = 20,
  });

  /// How many sit in each status, under the same filters as the list.
  ///
  /// **`status` is not among them, by the server's own design** — see [ShortageEndpoints.summary].
  /// Every *other* filter is kept, so «جديد ١٢» under a product filter means twelve of that
  /// product: hand the whole question over without stripping anything.
  Future<Either<Failure, ShortageCounts>> statusCounts({
    String? assignedTo,
    int? productId,
    int? orderId,
    int? customerId,
    String? source,
    String? search,
  });

  /// One shortage with its ledger. The only endpoint that sends `supplies`.
  Future<Either<Failure, Shortage>> shortage(int shortageId);

  /// Writing one down by hand — «شريط لاصق عريض». A shortage born of an order is never created
  /// here; it is mirrored by the server when the order comes up short.
  Future<Either<Failure, Shortage>> create({
    required String name,
    required String quantity,
    int? productId,
    int? productVariantId,
    String? unit,
    int? assignedToUserId,
    String? description,
  });

  /// Correcting one.
  ///
  /// Refused on a shortage born of an order — «نقصٌ مصدره طلبية — تُعدَّل كميته من شاشة الطلبية لا
  /// من هنا» — which `Shortage.isEditable` says in advance, and refused again when the new
  /// requirement would fall below what has already been supplied.
  Future<Either<Failure, Shortage>> update(
    int shortageId, {
    required String name,
    required String quantity,
    int? assignedToUserId,
    String? description,
  });

  /// Moving it along. **Only the values in `available_transitions`** — «مكتمل» is refused, and
  /// an illegal move is refused in the server's own words.
  Future<Either<Failure, Shortage>> changeStatus(int shortageId, {required String status});

  /// Handing it to somebody, or taking it back — `null` unassigns.
  Future<Either<Failure, Shortage>> assign(int shortageId, {required int? userId});

  /// Recording what was bought.
  ///
  /// **This is the goods arriving, not a note about them.** It writes a purchase arrival onto
  /// [warehouseId] at `amount ÷ quantity`, which is what lets the order draw its full quantity at
  /// «جاهزة» and what carries the money into the P&L.
  ///
  /// [warehouseId] is **required on a stockable shortage and refused on one that is not** — both
  /// as 422s in the server's own words. `Shortage.isStockable` is the flag to read.
  ///
  /// The ceiling on [quantity] is checked again on the server under a lock, so the «أكبر من
  /// المتبقي» refusal can still arrive even from a screen that capped the box: two clerks can
  /// record the last ten kilos at once.
  Future<Either<Failure, ShortageSupply>> recordSupply(
    int shortageId, {
    required String quantity,
    String? amount,
    String? method,
    int? warehouseId,
    String? reference,
    String? occurredOn,
    String? notes,
  });

  /// Undoing one.
  ///
  /// **It takes the goods back off the shelf**, so Inventory can refuse it for reasons that have
  /// nothing to do with shortages — the layer was already drawn on by an order, or repriced by
  /// hand. Those arrive as 422s in Inventory's own words; show them as sent.
  ///
  /// [reason] is **required by the server**, and is the sentence somebody reads six months later
  /// beside a struck-through purchase. It is typed as non-nullable so a caller cannot forget it
  /// and discover the 422 at runtime — which is exactly what used to happen.
  Future<Either<Failure, ShortageSupply>> reverseSupply(
    int shortageId,
    int supplyId, {
    required String reason,
  });
}
