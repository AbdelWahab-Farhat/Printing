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
/// The investor's own door, and the staff screens that manage him.
abstract final class InvestorEndpoints {
  /// **No id in the path, and that is the security rather than an omission.** The account is
  /// resolved on the server from the signed-in user's own link, so there is nothing here for an
  /// app to change into somebody else's.
  static const String portalSummary = '/investor-portal/summary';
  static const String portalStatement = '/investor-portal/statement';

  static const String investors = '/investors';
  static const String deals = '/investor-deals';

  static String investor(int id) => '/investors/$id';
  static String wallet(int id) => '/investors/$id/wallet';
  static String statement(int id) => '/investors/$id/statement';
  static String deal(int id) => '/investor-deals/$id';
  static String closeDeal(int id) => '/investor-deals/$id/close';
  static String dealExpenses(int id) => '/investor-deals/$id/expenses';

  /// The orders that sold this deal's goods, and what each one earned it.
  static String dealOrders(int id) => '/investor-deals/$id/orders';

  /// The same question from the order's end — «هذه الطلبية، من أخذ منها وكم».
  static String orderInvestorShares(int orderId) =>
      '/orders/$orderId/investor-shares';

  /// The deal being born from the order it is about — the partners, the money, and every one of
  /// the order's lines claimed, in one call. Guarded by `investors.manage`, not by the buyer's
  /// own grant.
  static String fundPurchaseOrder(int purchaseOrderId) =>
      '/purchase-orders/$purchaseOrderId/investor-funding';
}

/// إعدادات الشركة — نقطةٌ واحدة تُقرأ وتُكتب.
///
/// نقطةٌ واحدة لا اثنتان: الإعداداتُ صفٌّ واحد على الخادم، وتقسيمُها إلى «عامة» و«استثمار» في
/// المسار كان سيعد بفصلٍ لا يوجد خلفه.
/// الصندوق الاستثماري وفتراته.
///
/// `investment` لا `investor-deals`: الصفقةُ صارت دفعةَ شراءٍ داخلية، والذي يُقرأ ويُدار هو
/// الصندوقُ وفتراتُه.
abstract final class InvestmentEndpoints {
  static const String fund = '/investment/fund';
  static const String periods = '/investment/periods';
  static const String closePeriod = '/investment/periods/close';

  /// طلبياتُ فترةٍ واحدة ومن أخذ منها — «أي طلبية أعطت ربحاً، وكم أخذ كل مستثمر».
  static String periodOrders(int periodId) => '/investment/periods/$periodId/orders';

  /// حركاتُ مالٍ تمرّ بالصندوق: تشتري وحداتٍ أو تُلغيها، فلها بابُها لا بابُ المحفظة.
  static const String deposits = '/investment/deposits';
  static const String withdrawals = '/investment/withdrawals';
  static const String expenses = '/investment/expenses';

  /// إبطالُ حركةٍ في محفظة — يبطل الخزينةَ والوحداتِ معها.
  static String walletReversal(int investorId, int entryId) =>
      '/investors/$investorId/wallet/$entryId/reversal';

  /// شراءٌ بمال الصندوق: لا صفقةَ تُولد.
  static String fundPurchase(int purchaseOrderId) =>
      '/purchase-orders/$purchaseOrderId/fund-purchase';
}

abstract final class SettingsEndpoints {
  static const String settings = '/settings';
}

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
/// النواقص — what the shop is short of, and the chase to get it.
///
/// Nine paths behind five grants. Every one of the per-shortage routes also carries an **archive
/// rule**: a shortage whose order has been archived additionally demands `orders.archive.view`
/// and otherwise answers 403 with its own sentence — «هذا النقص يخصّ طلبية في الأرشيف…» — which
/// is deliberately not the blanket «ليس لديك صلاحية». Show it as sent: the reader holds the
/// grant the endpoint asks for and is being refused by a fact about *this row*.
abstract final class ShortageEndpoints {
  static const String index = '/shortages';

  /// How many sit in each status — what the chip row above the list draws its numbers from.
  ///
  /// Declared on the server *before* `/shortages/{id}`, or the word «summary» would be read as an
  /// id. It takes the same filters as the list and **ignores `status`**: a chip row exists to say
  /// what *else* there is, and counting only the status already selected would make every chip
  /// but one read zero.
  static const String summary = '/shortages/summary';

  static String show(int shortageId) => '/shortages/$shortageId';

  /// Moving it along the chase. `PATCH` — and «مكتمل» is not reachable through it, because it is
  /// written by arithmetic when the remainder reaches zero.
  static String status(int shortageId) => '/shortages/$shortageId/status';

  /// Handing it to somebody. Its own grant, `shortages.assign`: routing work and doing it are
  /// different jobs.
  static String assignee(int shortageId) => '/shortages/$shortageId/assignee';

  /// Saying how much the warehouse is short, in the unit it will be bought in.
  ///
  /// Asked here rather than only on the order screen because the person who first knows the
  /// weight is the buyer standing on the shortage — and until it is known, `supplies` refuses
  /// every arrival: kilograms cannot be subtracted from a count of bags.
  static String warehouseQuantity(int shortageId) =>
      '/shortages/$shortageId/warehouse-quantity';

  /// Recording what was bought. **This posts goods onto a shelf**, not a note beside them — see
  /// the record-supply sheet for why the warehouse is required on a stockable shortage.
  static String supplies(int shortageId) => '/shortages/$shortageId/supplies';

  /// Undoing one. Its own grant, `shortages.supplies.reverse`, and it takes the goods back off
  /// the shelf — so Inventory can refuse it in its own words.
  static String supplyReversal(int shortageId, int supplyId) =>
      '/shortages/$shortageId/supplies/$supplyId/reversal';

  /// The history, identical in shape to every other `logs` endpoint and read by the same screen.
  static String logs(int shortageId) => '/shortages/$shortageId/logs';
}

abstract final class DesignTicketEndpoints {
  static const String index = '/design-tickets';

  /// How many sit in each status — what the chip row above the list draws its numbers from.
  ///
  /// Declared on the server *before* `/design-tickets/{id}`, or the word «summary» would be read
  /// as an id. It takes the same filters as the list and **ignores `status`**: a chip row exists
  /// to say what *else* there is.
  static const String summary = '/design-tickets/summary';

  static String show(int ticketId) => '/design-tickets/$ticketId';

  /// Routing a ticket to a designer. `PATCH`, and its own grant `design_tickets.assign`:
  /// directing work and doing it are different jobs.
  ///
  /// **There is deliberately no `status` endpoint beside this one.** Every status is written by
  /// the action that earns it — the acceptance, the version, the verdict, the cancellation — so
  /// this app never sends a status anywhere.
  static String designer(int ticketId) => '/design-tickets/$ticketId/designer';

  /// «قبول الطلب». A POST to a noun rather than a PATCH on the ticket: what is created is the
  /// acceptance — a fact with a person and a time — and exactly one may ever exist. A second
  /// caller gets a 422 naming whoever holds it.
  static String acceptance(int ticketId) => '/design-tickets/$ticketId/acceptance';

  /// Calling the request off, with the reason the server requires.
  static String cancellation(int ticketId) => '/design-tickets/$ticketId/cancellation';

  /// The employee's reference files — `multipart/form-data`.
  static String attachments(int ticketId) => '/design-tickets/$ticketId/attachments';

  static String attachment(int ticketId, int attachmentId) =>
      '/design-tickets/$ticketId/attachments/$attachmentId';

  /// The designer's work. **The same path sends the first version and every revision** — a
  /// revision is a row, not a new ticket — and the version number is the server's to allocate.
  static String versions(int ticketId) => '/design-tickets/$ticketId/versions';

  /// The verdict. Refused to whoever uploaded the version, even an administrator.
  static String review(int ticketId, int versionId) =>
      '/design-tickets/$ticketId/versions/$versionId/review';

  /// «الرد داخل التذكرة» — the same comment shape every other commentable record uses.
  static String comments(int ticketId) => '/design-tickets/$ticketId/comments';

  /// «قرأتُ المحادثة» — تُطفئ شارة هذه التذكرة، ومعها خبرُها في الجرس لأنهما صفوفٌ واحدة.
  ///
  /// مُعلَنٌ على الخادم **قبل** `comments/{comment}`، وإلا قرأ المتغيّرُ كلمةَ «read» معرّفاً.
  /// و`POST` لا أثرٌ جانبيٌّ على `GET` القائمة: طلبٌ يغيّر حالةً لا يُعاد إرساله عند كلّ تحديث.
  static String commentsRead(int ticketId) => '/design-tickets/$ticketId/comments/read';

  static String comment(int ticketId, int commentId) =>
      '/design-tickets/$ticketId/comments/$commentId';

  /// The history, identical in shape to every other `logs` endpoint and read by the same screen.
  static String logs(int ticketId) => '/design-tickets/$ticketId/logs';
}

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

  /// Undoing a receipt entered in error. Guarded by `inventory.manage`, like [arrivals] — it
  /// takes stock back off the shelf, and whoever may put it there by mistake must be able to
  /// take it back. `purchase_orders.reverse_receipt_any_time` does not open this door; it only
  /// waives the 24-hour window once inside.
  static String receiptReversal(int purchaseOrderId) =>
      '/purchase-orders/$purchaseOrderId/receipt-reversal';
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

  /// أرشيف الطلبيات — the deleted ones, and nothing else.
  ///
  /// **Declared on the server *before* `/orders/{order}`**, or implicit binding reads the
  /// literal word «archive» as an order id and answers 404 — the same trap `/orders/summary`
  /// sits beside, and the same one `Routes.ordersFiltered` sits beside on this side of the
  /// wire. It is a path rather than a flag on [index] because three separate queries seed the
  /// list, the status counts and the payment counts, and a flag put on one of them would leave
  /// the three describing different sets.
  ///
  /// Takes exactly the query [index] takes: the archive screen is the orders screen with a
  /// different source, so every filter the reader already had travels unchanged.
  static const String archive = '/orders/archive';

  /// The archive's own counters. Under the archive rather than beside it for the reason above:
  /// two rows of chips describing two different sets is the failure that contradicts itself in
  /// front of the eye.
  static const String archiveSummary = '/orders/archive/summary';

  static String show(int orderId) => '/orders/$orderId';

  /// Putting an archived order back in the shop. A POST for the reason [status] and [reinstate]
  /// are: the order's history gains a row.
  ///
  /// **And it is not [reinstate].** «تراجع عن الإلغاء» undoes a recorded business event and
  /// deliberately leaves the warehouse alone; this undoes a *record that should never have
  /// existed*, so the stock is drawn again — at today's cost, which is what the confirmation
  /// says out loud. See §١ of ORDER-DELETE-AND-ARCHIVE.md.
  static String restore(int orderId) => '/orders/$orderId/restore';

  /// Moving an order. A POST, not a PATCH: the server records a row on the order's timeline as
  /// well as changing the field, so it is an event rather than an edit to a value.
  static String status(int orderId) => '/orders/$orderId/status';

  /// Undoing a cancellation made by mistake. A POST for the same reason [status] is one: the
  /// order's timeline gains a row.
  ///
  /// **It carries no destination, and there is none to send.** The server puts the order back
  /// in the status its own timeline says it was cancelled from — read `reinstateTo` off the
  /// order to name that status on the button. An optional `reason` is a note on the row.
  static String reinstate(int orderId) => '/orders/$orderId/reinstate';

  /// What is missing from each line — and so what the customer is charged, since a line is
  /// billed for what is left of it. A PATCH rather than a POST: nothing is recorded on the
  /// timeline, a number on the order is corrected.
  static String shortages(int orderId) => '/orders/$orderId/shortages';

  /// «هل أُبلِغ الزبون أنّ طلبه جاهز؟» — recording that an employee sent the customer the message
  /// saying their order is ready, and taking that record back.
  ///
  /// A PATCH for the reason [shortages] is one: nothing is written to the order's timeline, a
  /// field on it is corrected. The body is `{"sent": true|false}` — the second value is the undo
  /// of a stray tap, and it costs the same grant, `orders.ready_message`.
  static String readyMessage(int orderId) => '/orders/$orderId/ready-message';

  /// «هل وصل العربون فعلاً؟» — an employee confirming the deposit landed, and taking that back.
  ///
  /// A PATCH like [readyMessage] above, and the same shape of fact: a field on the order is
  /// corrected and nothing is written to its timeline. The body is `{"received": true|false}`,
  /// and the grant is `orders.deposit.confirm` — **but the grant is not the whole rule.** The
  /// server also refuses whoever moved the order to «عربون مدفوع», so that the claim and its
  /// confirmation are two people; `Order.canConfirmDeposit` carries the answer to both.
  static String depositReceipt(int orderId) => '/orders/$orderId/deposit-receipt';

  /// What the shelves are short of for this order, line by line — the numbers that fill the
  /// «نواقص» form instead of somebody counting them by hand.
  ///
  /// Read-only, and behind `orders.status.shortage` because it is the move it serves. Omit
  /// `warehouse_id` and it answers across every warehouse; `available_scope` says which question
  /// was answered, so a cross-site sum can be labelled as one. `suggested_shortage` is what to
  /// put in a line's box — **a suggestion, not a fact**: two lines can share a shelf, the server
  /// apportions earlier lines first, and only the total is certain. There is no new write path;
  /// the answer is typed into the existing `PATCH /orders/{order}/status`.
  static String stockShortfall(int orderId) => '/orders/$orderId/stock-shortfall';

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

  /// إحصائيات المبيعات وحركة الأكياس. The same two required days, behind a different grant:
  /// this board carries no cost and no margin, so the press and the warehouse can be shown
  /// their own output without being shown what the shop earns on it.
  static const String salesStatistics = '/reports/sales-statistics';
}

/// شحنات نورس — the carrier integration's operations surface.
///
/// **Separate from `ShippingCompanyEndpoints`**, which maintains the list of companies. This is
/// what happens to a parcel after one of them has it.
///
/// Only [lodge] is called today: the read-only monitoring endpoints — the event queue, the parcel
/// list, the not-lodged queue — have no screen yet, and naming them here before one exists would
/// advertise routes nothing reaches.
abstract final class CarrierEndpoints {
  /// Hands the order to Nawris and answers with the parcel.
  ///
  /// **Creates a parcel; it does not move the order.** The status changes when the carrier
  /// reports a courier is holding it, through the webhook.
  static String lodge(int orderId) => '/carrier/orders/$orderId/lodge';

  /// Sends a returned parcel out again — closes the old one, opens a new one.
  static String resend(int orderId) => '/carrier/orders/$orderId/resend';

  /// Deletes the parcel at Nawris and closes ours — for one that never went anywhere.
  static String deleteShipment(int orderId) =>
      '/carrier/orders/$orderId/delete-shipment';

  /// Drops our claim on a parcel **without telling Nawris**, for one they deleted themselves.
  static String unlink(int orderId) => '/carrier/orders/$orderId/unlink';
}

/// الإشعارات — every account's own mailbox, plus the device registry push needs.
///
/// **Reading is behind no permission.** Every account has a mailbox, so there is nothing to
/// grant; the scoping is done by removing the surface rather than by a check — a foreign
/// notification id answers 404, never 403, because a 403 would confirm the id names something
/// real. Only [announcements] is guarded, by `notifications.broadcast`.
abstract final class NotificationEndpoints {
  /// Newest first, paginated. `?unread=true` narrows it to the unread ones.
  static const String list = '/notifications';

  /// `{ "count": 3 }` — what the bell draws, and the only thing it needs.
  static const String unreadCount = '/notifications/unread-count';

  static const String readAll = '/notifications/read-all';

  /// POST registers this device's FCM token, DELETE releases it. **The DELETE is the one that
  /// matters**: skipped at sign-out, a shared counter phone keeps receiving the previous
  /// employee's notifications.
  static const String devices = '/notifications/devices';

  /// The only endpoint here that writes to everybody. Throttled server-side as well as
  /// permissioned.
  static const String announcements = '/notifications/announcements';

  static String read(int id) => '/notifications/$id/read';
}
