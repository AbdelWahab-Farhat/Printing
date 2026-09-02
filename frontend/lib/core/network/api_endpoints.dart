/// Every path the app can call, in one place.
///
/// A URL typed inline at a call site is a URL nobody can find when the API renames it, and the
/// compiler cannot help with a string. Endpoints live here, grouped by the backend resource
/// they belong to, and they are always relative — the host comes from `AppConfig.baseUrl`.
///
/// The live contract is the generated OpenAPI spec: run the backend and open
/// http://localhost:8000/docs/api. If a path here disagrees with the spec, the spec is right.
library;

abstract final class AuthEndpoints {
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';
  static const String logoutAll = '/auth/logout-all';
}

/// The numbers the app opens on.
abstract final class HomeEndpoints {
  /// Four counts and one row per order status, in one call — they are read together and go
  /// stale together.
  static const String summary = '/home/summary';
}

/// Who works here, what jobs exist, and what each job may do.
abstract final class AccessEndpoints {
  /// Staff accounts.
  static const String users = '/users';

  /// One employee — and, with `PUT`, their name, email and phone.
  static String user(int userId) => '/users/$userId';

  /// Replaces a user's whole set of roles — send every role they should end up with.
  static String userRoles(int userId) => '/users/$userId/roles';

  /// **Four paths, not four fields on one.** Each is guarded differently on the server —
  /// `users.manage` for the details and the activation, `users.salary` for the wage, and the
  /// administrator alone for the password — so collapsing them into one endpoint would hand
  /// every power to the weakest guard. See EMPLOYEE-DETAIL-DESIGN.md §٢.
  static String userPassword(int userId) => '/users/$userId/password';

  static String userSalary(int userId) => '/users/$userId/salary';

  static String userActivation(int userId) => '/users/$userId/activation';

  static const String roles = '/roles';

  static String role(int roleId) => '/roles/$roleId';

  /// The catalogue of everything the system can check for, already grouped into the sections a
  /// role screen renders. Read-only by design: a permission is real only because code checks
  /// for it, so there is nothing here to create.
  static const String permissions = '/permissions';
}

abstract final class CityEndpoints {
  static const String index = '/cities';

  static String show(int cityId) => '/cities/$cityId';

  static String regions(int cityId) => '/cities/$cityId/regions';

  static String region(int cityId, int regionId) => '/cities/$cityId/regions/$regionId';
}

abstract final class ShippingCompanyEndpoints {
  static const String index = '/shipping-companies';

  static String show(int companyId) => '/shipping-companies/$companyId';
}

/// مجالات العمل — what a customer's shop sells.
abstract final class BusinessFieldEndpoints {
  static const String index = '/business-fields';

  static String show(int fieldId) => '/business-fields/$fieldId';

  static String activation(int fieldId) => '/business-fields/$fieldId/activation';
}

/// المخازن — where stock sits, what sits on each shelf, and the ledger that explains it.
abstract final class WarehouseEndpoints {
  static const String index = '/warehouses';

  static String show(int warehouseId) => '/warehouses/$warehouseId';

  static String stocks(int warehouseId) => '/warehouses/$warehouseId/stocks';

  /// The whole warehouse in five numbers. Never filtered — «٤ من ٢٤» is the sentence, and the
  /// ٢٤ has to survive the filter that produced the ٤.
  static String stocksSummary(int warehouseId) => '/warehouses/$warehouseId/stocks/summary';

  /// The one thing a balance line accepts a write for. The quantity never is: it moves because
  /// a movement below explains it.
  static String stockThreshold(int warehouseId, int stockId) =>
      '/warehouses/$warehouseId/stocks/$stockId/threshold';
}

/// أصناف المخزون — the shelves themselves.
///
/// **A shelf is a material at a size, not a product's size.** «كيس شحن سادة» and «كيس شحن مطبوع»
/// at 25*35 are two catalogue rows and one pile of bags; what separates them is printing, which
/// is a cost rate, not a different material. So a warehouse holds one of these and every product
/// size that is cut from it draws on the same balance.
///
/// Sharing runs across products at one size and **never across sizes**: «كيس شحن 25*35» and
/// «كيس شحن 35*40» are two shelves, two balances and two FIFO stacks, so per-size costing is
/// intact.
abstract final class StockItemEndpoints {
  static const String index = '/stock-items';

  static String show(int stockItemId) => '/stock-items/$stockItemId';

  /// What the pile is counted in — **and changing it empties the shelf.** A quantity counted in
  /// one unit means nothing in another, so what was there leaves through a recorded adjustment
  /// rather than being relabelled. Say so before asking.
  static String unit(int stockItemId) => '/stock-items/$stockItemId/unit';

  /// Which product sizes draw on this pile — **the whole set, every time.** A PUT because the
  /// list replaces: what it carries is linked, what it omits is unlinked, and `[]` empties the
  /// material deliberately. The product bodies are untouched.
  static String variants(int stockItemId) => '/stock-items/$stockItemId/variants';

  static String logs(int stockItemId) => '/stock-items/$stockItemId/logs';
}

/// مجموعات الأصناف — the material itself, the thing a shelf is a *size of*.
///
/// **It holds nothing**: no balance, no cost layer, no size. It exists so nobody has to point
/// each product size at its shelf by hand — naming the material once on the product files every
/// size of it automatically, and one wrong click can no longer split a heap in two.
abstract final class StockItemGroupEndpoints {
  static const String index = '/stock-item-groups';

  static String show(int groupId) => '/stock-item-groups/$groupId';

  static String logs(int groupId) => '/stock-item-groups/$groupId/logs';
}

/// The ledger. One feed to read, and an endpoint per *kind* of write — an arrival has no
/// source, a transfer has both ends, an adjustment has a direction instead of either.
abstract final class StockMovementEndpoints {
  static const String index = '/stock-movements';

  static const String arrivals = '/stock-movements/arrivals';
  static const String transfers = '/stock-movements/transfers';
  static const String adjustments = '/stock-movements/adjustments';
}

/// دفعات التكلفة — the cost layers under a balance: what each arrival was booked at and how
/// much of it is still on the shelf. Read in consumption order, because that is the order the
/// next issue will draw them in.
abstract final class StockBatchEndpoints {
  static const String index = '/stock-batches';

  static String cost(int batchId) => '/stock-batches/$batchId/cost';
}

/// الموردون — who the business buys its stock from. Deactivated, never deleted, so there is no
/// destroy path here: past shipments must keep naming the vendor that sent them.
abstract final class VendorEndpoints {
  static const String index = '/vendors';

  static String show(int vendorId) => '/vendors/$vendorId';

  static String activation(int vendorId) => '/vendors/$vendorId/activation';

  /// What staff have written to each other about this supplier. Nested and scoped exactly as the
  /// customer's notes are — another supplier's comment id is a 404 by construction.
  static String comments(int vendorId) => '/vendors/$vendorId/comments';
}

/// شحنات التوريد — a document from a vendor: one warehouse, one or more lines.
///
/// **Read and create only.** Posting one writes a ledger row per line onto the same
/// `stock_movements` feed [StockMovementEndpoints] reads, so it is never edited afterwards —
/// a mistake is corrected by an adjustment against the warehouse, exactly as it is for any
/// other movement. Hence no `show`-with-PUT and no delete.
abstract final class StockArrivalEndpoints {
  static const String index = '/stock-arrivals';

  static String show(int stockArrivalId) => '/stock-arrivals/$stockArrivalId';
}

/// The paperwork raised against a supplier.
abstract final class PurchaseOrderEndpoints {
  static const String index = '/purchase-orders';

  /// How many orders stand in each status — what a supplier's screen draws its numbers from.
  ///
  /// Declared on the server *before* `/purchase-orders/{id}`, or the word «summary» would be
  /// read as an id. Nothing here depends on that; it is why the path is safe to call.
  static const String summary = '/purchase-orders/summary';

  static String show(int purchaseOrderId) => '/purchase-orders/$purchaseOrderId';

  /// Sending or cancelling. `PATCH` — «مكتمل» is not reachable through it.
  static String status(int purchaseOrderId) =>
      '/purchase-orders/$purchaseOrderId/status';

  /// Booking a shipment in against the order. Guarded by `inventory.manage`, not by
  /// `purchase_orders.manage` — it writes to the stock ledger.
  static String arrivals(int purchaseOrderId) =>
      '/purchase-orders/$purchaseOrderId/arrivals';
}

/// معدلات تكلفة التصنيع — the standing prices an order is charged when it enters printing.
///
/// **The list is the priority ladder.** The API returns the size-specific rates first, then the
/// product-wide ones, then the defaults — the same order it resolves them in — so nothing here is
/// re-sorted by the app.
abstract final class ManufacturingCostRateEndpoints {
  static const String index = '/manufacturing-cost-rates';

  static String show(int rateId) => '/manufacturing-cost-rates/$rateId';

  /// Retiring a rate, which is what stopping one *is*: it leaves the ladder from that point on,
  /// and every cost entry it already produced keeps the amount it was snapshotted with.
  static String activation(int rateId) => '/manufacturing-cost-rates/$rateId/activation';
}

/// التصنيفات — the headings the catalogue is organised under. A sibling of the products
/// resource rather than a child of it: a category exists whether or not any product is in it.
abstract final class ProductCategoryEndpoints {
  static const String index = '/product-categories';

  static String show(int categoryId) => '/product-categories/$categoryId';

  static String activation(int categoryId) => '/product-categories/$categoryId/activation';

  /// The whole order in one call — a drag moves one card and renumbers everything after it.
  static const String order = '/product-categories/order';

  /// The picture the catalogue prints above a heading. `POST` to set or replace it, `DELETE` to
  /// take it off — the same address either way.
  static String image(int categoryId) => '/product-categories/$categoryId/image';
}

abstract final class ProductEndpoints {
  static const String index = '/products';

  static String show(int productId) => '/products/$productId';

  static String quote(int productId) => '/products/$productId/quote';

  /// A product's photographs — where one is added.
  ///
  /// **There is deliberately no listing endpoint here, and that shapes the screen.** The server
  /// registers `store`, `update` and `destroy` only; the images themselves travel inside [show].
  /// So the screen that manages them reads the *product*, and reads it again after every write —
  /// which is also the only way to learn which photo the server made primary once one was
  /// promoted or the primary one deleted.
  static String images(int productId) => '/products/$productId/images';

  /// One photograph: promoting it to primary, or removing it.
  ///
  /// The file is never replaced through this path — the API refuses to swap the bytes behind an
  /// id, so a URL already handed out cannot start pointing at different content. Changing a
  /// picture is an upload followed by a delete.
  static String image(int productId, int imageId) => '/products/$productId/images/$imageId';
}

abstract final class OrderEndpoints {
  static const String index = '/orders';

  /// How many orders sit in each status, under the same filters as the list.
  static const String summary = '/orders/summary';

  static String show(int orderId) => '/orders/$orderId';

  /// Moving an order. A POST, not a PATCH: the server records a row on the order's timeline as
  /// well as changing the field, so it is an event rather than an edit to a value.
  static String status(int orderId) => '/orders/$orderId/status';

  /// What is missing from each line — and so what the customer is charged, since a line is
  /// billed for what is left of it. A PATCH rather than a POST: nothing is recorded on the
  /// timeline, a number on the order is corrected.
  static String shortages(int orderId) => '/orders/$orderId/shortages';

  static String designs(int orderId) => '/orders/$orderId/designs';

  static String reviewDesign(int orderId, int designId) =>
      '/orders/$orderId/designs/$designId/review';

  /// Bags spoiled while the line was being produced. Guarded by `inventory.manage`, not by any
  /// `orders.*` grant — it draws stock off the order's shelf and posts its FIFO cost, so it
  /// belongs to the stock ledger the same way booking a shipment in does.
  ///
  /// The item is scoped *inside* the order by the API, so another order's line id is a 404
  /// rather than a refusal somebody has to read.
  static String scrapItem(int orderId, int itemId) => '/orders/$orderId/items/$itemId/scrap';

  /// An order's money ledger. A GET to read it, a POST to add to it — and **nothing that
  /// updates or deletes an entry**, because the API has no such route: a mistake is undone by
  /// [reversePayment] below, which writes a second entry beside the wrong one.
  static String payments(int orderId) => '/orders/$orderId/payments';

  /// Money handed back to the customer. Its own path rather than a `type` on [payments],
  /// because the API models them as two different acts — a refund is a cash event a report
  /// should count, and a cancelled entry is not.
  static String refundPayment(int orderId) => '/orders/$orderId/payments/refunds';

  /// Closing what is left of a debt without any money moving — the five dinars that never came
  /// back. Its own path and its own permission: a refund hands back money the business holds,
  /// while this decides that money it is owed will never arrive.
  static String writeOffPayment(int orderId) => '/orders/$orderId/payments/write-offs';

  /// Cancelling an entry that should never have been written.
  static String reversePayment(int orderId, int paymentId) =>
      '/orders/$orderId/payments/$paymentId/reverse';
}

abstract final class CustomerEndpoints {
  static const String index = '/customers';

  static String show(int customerId) => '/customers/$customerId';

  static String activation(int customerId) => '/customers/$customerId/activation';

  /// A customer's artwork. Nested under the customer because the API scopes it that way —
  /// another customer's design id is a 404 by construction rather than by a check.
  static String designs(int customerId) => '/customers/$customerId/designs';

  static String design(int customerId, int designId) =>
      '/customers/$customerId/designs/$designId';

  /// What staff have written to each other about this customer. Nested and scoped exactly as
  /// the designs are — another customer's comment id is a 404 by construction.
  static String comments(int customerId) => '/customers/$customerId/comments';

  static String comment(int customerId, int commentId) =>
      '/customers/$customerId/comments/$commentId';
}

/// What the business is read by, rather than what it is made of.
///
/// **Read-only, and never paginated.** Each of these answers one object about a whole period, so
/// there is no page to ask for and no `meta` beside the data.
abstract final class ReportEndpoints {
  /// الأرباح والخسائر. `from` and `to` are both **required** — unlike every list in this app,
  /// this call has no unfiltered form: a report without a period is not a smaller report, it is
  /// a question nobody asked.
  static const String profitAndLoss = '/reports/profit-loss';
}
