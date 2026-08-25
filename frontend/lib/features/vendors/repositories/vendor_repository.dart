import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/vendors/models/stock_arrival.dart';
import 'package:dayaa/features/vendors/models/vendor.dart';

/// الموردون وشحناتهم, stated without saying how.
///
/// **One contract for both shapes, the same way [WarehouseRepository] covers the places, the
/// shelves and the ledger together.** They are one context on the server too: a shipment is a
/// vendor's document, and a screen showing the vendor without what they sent would be showing
/// half an answer.
///
/// There is **no delete and no update for an arrival** anywhere here, and both absences are the
/// contract: a vendor is deactivated so past documents keep naming them, and a posted arrival has
/// already moved a warehouse's balance — correcting one is an adjustment against that warehouse,
/// which belongs to `WarehouseRepository.recordAdjustment`.
abstract interface class VendorRepository {
  Future<Either<Failure, Paginated<Vendor>>> vendors({
    String? search,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  });

  Future<Either<Failure, Vendor>> show(int vendorId);

  Future<Either<Failure, Vendor>> create({
    required String name,
    required String phone,
    String? contactPerson,
    String? email,
    String? address,
  });

  /// A full replacement of the vendor's details. It deliberately cannot carry `is_active` —
  /// see [setActive].
  Future<Either<Failure, Vendor>> update(
    int vendorId, {
    required String name,
    required String phone,
    String? contactPerson,
    String? email,
    String? address,
  });

  /// Retiring a vendor, or bringing one back.
  ///
  /// Its own endpoint rather than a field on [update], for the reason the server split it: a
  /// plain edit that happened to omit the flag would otherwise reactivate a supplier nobody
  /// meant to reactivate.
  Future<Either<Failure, Vendor>> setActive(int vendorId, bool isActive);

  /// The shipments, newest first. [vendorId] narrows to one supplier's history — the
  /// purpose-built reader for it, which is why the vendor's own audit log leaves its arrivals
  /// out. [from] and [to] are plain days, inclusive.
  Future<Either<Failure, Paginated<StockArrival>>> stockArrivals({
    int? vendorId,
    int? warehouseId,
    String? from,
    String? to,
    int page = 1,
    int perPage = 20,
  });

  Future<Either<Failure, StockArrival>> stockArrival(int stockArrivalId);

  /// Posts a shipment: one document, and one ledger row per line, in a single transaction.
  ///
  /// `received_by` is **not** a parameter — the server stamps it from the authenticated user,
  /// and sending it would be this app claiming who received something it does not know.
  ///
  /// A fractional [StockArrivalLine.quantity] against a shelf counted in «قطعة» is refused with
  /// a `422` on that item, the same rule a single-line arrival already meets. The unit is the
  /// **stock item's** now, not the product's — `products.stock_unit` is gone.
  Future<Either<Failure, StockArrival>> recordStockArrival({
    required int vendorId,
    required int warehouseId,
    required List<StockArrivalLine> items,
    String? invoiceNumber,
    String? notes,
  });
}

/// One line of a shipment being posted: which shelf, and how much of it.
///
/// A class rather than the record type the spec sketched, because it is named in a repository
/// contract, a use case and a form's state — three places that would each have to spell the
/// record's shape out in full, and all three would have to be edited the day a line grows a
/// third field.
class StockArrivalLine {
  const StockArrivalLine({required this.stockItemId, required this.quantity});

  /// **The stock item, not a product's size.** Two products at one size draw on one pile, so
  /// booking goods in against either of them separately is what used to split the heap.
  ///
  /// Unlike a purchase order's lines, `StoreStockArrivalRequest` puts **no `distinct` rule** on
  /// this — the same shelf may legitimately appear twice on one document, e.g. two pallets from
  /// the same vendor weighed apart. Nothing here refuses it either.
  final int stockItemId;

  /// A decimal as typed, kept as text all the way to the wire — see [StockArrivalItem.quantity].
  final String quantity;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'stock_item_id': stockItemId,
    'quantity': quantity,
  };
}
