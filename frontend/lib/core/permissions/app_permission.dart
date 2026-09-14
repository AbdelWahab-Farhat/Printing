/// Every permission the system recognises — the app's whole vocabulary of "may I".
///
/// Open this file and you know, exhaustively, what the app can gate on. That is the point of it
/// existing at all: the alternative is `'products.manage'` typed as a string in ten screens,
/// where a rename is a search and a typo is a silently hidden button.
///
/// **It mirrors the backend's `PermissionName.php`, case for case, using the same case names**
/// so the two files diff by eye. That duplication is real and has no compiler watching it, so
/// `permission_contract_test.dart` reads the PHP file and fails when the two lists drift.
///
/// It lives in `core/`, not in `features/auth/`, so a products screen never imports the auth
/// feature merely to name a string.
///
/// **Adding one is a code change on both sides**, and deliberately so: a permission is only real
/// because something checks for it, so a permission nobody checks is a checkbox that lies.
///
/// The three greps that make this layer knowable:
///
/// ```text
/// lib/core/permissions/app_permission.dart   every permission that exists
/// grep -rn "AppPermission\." lib/            every place the app gates on one
/// grep -rn "Session>().isAdmin" lib/         must match only the two staff-creation gates
/// ```
///
/// The third is the one that matters: anything else matching it is a second permission system
/// starting. It is **not zero**, and that is deliberate — creating a staff account is
/// administrators-only *for now*, and the server enforces it with a gate ability rather than a
/// permission, so that it cannot be ticked onto a role. There is no case here to ask for,
/// because there is no permission. See `Session.isAdmin`; the day it is delegated, a case
/// arrives here and those two call sites become `can(...)`.
enum AppPermission {
  // Access management
  viewUsers('users.view', 'عرض المستخدمين'),
  manageUsers('users.manage', 'إدارة المستخدمين وأدوارهم'),

  /// Seeing what a colleague is paid, and setting it. Its own case rather than part of
  /// [manageUsers], because they are different jobs: whoever assigns roles is not necessarily
  /// whoever agrees wages. The salary section of the employee screen is drawn off this — and
  /// off the server, which simply omits the key for anybody without it.
  manageUserSalaries('users.salary', 'عرض رواتب الموظفين وتعديلها'),
  manageRoles('roles.manage', 'إدارة الأدوار والصلاحيات'),

  // Customers
  viewCustomers('customers.view', 'عرض العملاء'),
  manageCustomers('customers.manage', 'إضافة وتعديل العملاء'),

  // Rewriting or removing a note somebody else wrote about a customer. Its own permission
  // rather than part of `customers.manage`: correcting a phone number is bookkeeping, while
  // editing a colleague's sentence under their name is a claim about what they said. Writing a
  // note and changing your own needs no grant at all — reading the record covers it.
  //
  // **One permission for notes on every kind of record** — a customer, a supplier — because the
  // question it answers is one question. See GENERAL-COMMENTS.md.
  //
  // Nothing in the app gates on this. The server computes «صاحبه أو مشرف» per reader and sends
  // the answer as `can_edit` on each note, so the buttons are drawn from the row rather than
  // from a rule this side re-derives. The case exists because `permission_contract_test`
  // requires the two catalogues to match, and because a role screen has to be able to tick it.
  moderateComments('comments.moderate', 'تعديل وحذف ملاحظات الآخرين'),

  // مجالات العمل — what a customer's shop sells. Reading is granted to every role, because
  // the customer form cannot be filled in without the list; curating the list is the rare job.
  viewBusinessFields('business_fields.view', 'عرض مجالات العمل'),
  manageBusinessFields('business_fields.manage', 'إضافة وتعديل مجالات العمل'),

  // Catalogue
  viewProducts('products.view', 'عرض المنتجات والأسعار'),
  manageProducts('products.manage', 'إضافة وتعديل المنتجات والأسعار'),
  // What the shop pays a vendor for a وسيط size, on the product **and** on the order line.
  // Split from `viewProducts` on purpose: taking an order needs the price the customer pays and
  // nothing else, so the server omits the key entirely for anybody without this — the same
  // arrangement `inventory.view_cost` has with the ledger.
  viewProductCost('products.view_cost', 'عرض سعر تكلفة المنتجات الوسيطة'),

  // Delivery map — cities and regions share one pair; a region is never administered by
  // somebody who is not also administering its city.
  viewDeliveryLocations('cities.view', 'عرض مدن ومناطق التوصيل'),
  manageDeliveryLocations('cities.manage', 'إضافة وتعديل مدن ومناطق التوصيل'),

  // Who carries the parcels. Its own pair: agreeing rates with a carrier is not the same job as
  // maintaining the list of neighbourhoods.
  viewShippingCompanies('shipping_companies.view', 'عرض شركات التوصيل'),
  manageShippingCompanies('shipping_companies.manage', 'إضافة وتعديل شركات التوصيل'),

  // Stock. One pair covers warehouses, balances and the ledger, exactly as on the backend:
  // whoever may move stock between two warehouses is administering both. Declared here before
  // any screen reads them, because this enum is the contract with `PermissionName.php` — a case
  // missing on one side is what `permission_contract_test.dart` fails the build for.
  viewInventory('inventory.view', 'عرض المخازن والأرصدة والحركات'),
  manageInventory('inventory.manage', 'إدارة المخازن وتسجيل حركات المخزون'),
  // Correcting what a cost layer is carried at — its own grant on the backend because it moves
  // the book value of the business without a shelf being touched.
  revalueStock('inventory.revalue', 'تعديل تكلفة دفعات المخزون'),
  // Knowing how much is on the shelf and knowing what it was bought for are two levels of
  // trust: the storekeeper counts and does not buy. Gates the cost column on the ledger, the
  // value in its header and the cost layers tab — the app decides by checking this, never by
  // the absence of a key in the payload.
  viewStockCost('inventory.view_cost', 'عرض تكلفة المخزون'),

  // Who we buy from. Its own pair rather than folded into inventory.*, the same split
  // `customers.*` draws from `products.*`: agreeing terms with a supplier and receiving what
  // they sent are different jobs. **Recording the shipment itself is still `inventory.manage`** —
  // it writes to the ledger, and that is squarely the storekeeper's work.
  viewVendors('vendors.view', 'عرض الموردين'),
  manageVendors('vendors.manage', 'إضافة وتعديل الموردين'),

  // Purchase orders. Its own pair rather than folded into vendors.*: agreeing terms with a
  // supplier and raising the paperwork against them are different jobs. **Receiving a shipment
  // is neither** — it posts stock, so it is guarded by `inventory.manage` even when it happens
  // on a purchase order's own screen.
  viewPurchaseOrders('purchase_orders.view', 'عرض أوامر الشراء'),
  managePurchaseOrders(
    'purchase_orders.manage',
    'إنشاء وتعديل أوامر الشراء وإرسالها وإلغاؤها',
  ),
  // Undoing a receipt is `inventory.manage` like posting one — this is not the grant that opens
  // that door. It waives the **clock** and nothing else: a receipt nobody can still walk over
  // and verify is a different level of trust, the same reasoning `inventory.revalue` carries.
  // So it is listed here for the permissions screen to grant, and no button is gated on it —
  // the server folds it into `can_reverse_receipt` for the caller who is asking.
  reverseReceiptAnyTime(
    'purchase_orders.reverse_receipt_any_time',
    'التراجع عن استلام شحنة بعد انتهاء مهلة الـ٢٤ ساعة',
  ),

  // Orders. One permission per status the workflow can move *into*, so the business composes
  // a designer, a printer and a delivery coordinator out of this list without any of those
  // jobs being named in code. The two dispatch statuses share one permission on purpose; the
  // three returns stay separate, because a clerk does choose which one happened.
  viewOrders('orders.view', 'عرض الطلبيات'),
  manageOrders('orders.manage', 'إضافة وتعديل الطلبيات'),
  discountOrders('orders.discount', 'منح خصم على الطلبية'),
  // Its own grant rather than the discount's — `PermissionName.php`'s own reasoning, and worth
  // repeating here: one gives money away and the other asks the customer for more, and a
  // business may reasonably trust a role with exactly one of them.
  addOrderAdditionalCost('orders.additional_cost', 'إضافة تكلفة إضافية على الطلبية'),
  manageOrderDesigns('orders.designs.manage', 'إدارة تصاميم الطلبية واعتمادها'),

  // «هل أُبلِغ الزبون أنّ طلبه جاهز؟» — the tick an employee puts on an order to say they told
  // the customer, and the box on the home screen counting the orders nobody has told yet.
  //
  // **Its own grant rather than a ride on `manageOrders`**, and the box is the reason: this is
  // one person's morning work, and a queue put in front of the whole shop is a number everybody
  // learns to scroll past. It gates two things — the switch on the order screen, which is drawn
  // for every reader and enabled only for a holder, and the box, which is not drawn at all
  // without it. See ORDER-READY-MESSAGE.md §٤.
  confirmReadyMessage('orders.ready_message', 'تأكيد إرسال رسالة الجاهزية للزبون'),
  // The warehouse's own grant: it weighs the goods, names the shelf they leave from, and hands
  // the order to the press. Separate from the two production grants beside it because a
  // different desk does it — the wording is `PermissionName.php`'s, word for word.
  moveOrderToReadyToPrint(
    'orders.status.ready_to_print',
    'تحويل الطلبية إلى جاهزة للطباعة',
  ),
  moveOrderToDesigning(
    'orders.status.designing',
    'تحويل الطلبية إلى قيد التصميم',
  ),
  moveOrderToPrinting(
    'orders.status.printing',
    'تحويل الطلبية إلى قيد الطباعة',
  ),
  // The وسيط road's own step: the job has gone out to the vendor. Its own grant rather than the
  // press's, because a different person sends work out than runs the machine.
  moveOrderToManufacturing(
    'orders.status.manufacturing',
    'تحويل الطلبية إلى قيد التصنيع',
  ),
  moveOrderToReady('orders.status.ready', 'تحويل الطلبية إلى جاهزة'),
  moveOrderToShortage('orders.status.shortage', 'تحويل الطلبية إلى نواقص'),
  dispatchOrders(
    'orders.status.dispatch',
    'تسليم الطلبية للتوصيل أو للاستلام من المكتب',
  ),
  markOrdersDelivered('orders.status.delivered', 'تأكيد استلام العميل للطلبية'),

  /// Recording that the customer took only part of the order — which shrinks the invoice.
  ///
  /// **The app never checks this.** The server withholds the *fields* from anybody lacking it,
  /// so a screen that renders what it is handed is correct either way. It is here because the
  /// roles screen lists every permission by name.
  recordPartialDelivery('orders.partial_delivery', 'تسجيل تسليم جزئي — يُنقص الفاتورة'),
  settleOrders('orders.status.settled', 'تسوية مبلغ الطلبية'),
  recordCourierReturn(
    'orders.status.returned_courier',
    'تسجيل راجع لدى المندوب',
  ),
  recordCarrierReturn(
    'orders.status.returned_carrier',
    'تسجيل راجع لدى شركة التوصيل',
  ),
  recordOfficeReturn('orders.status.returned_office', 'تسجيل راجع مكتب'),
  resendOrders('orders.status.resend', 'إعادة إرسال طلبية راجعة'),
  cancelOrders('orders.status.cancelled', 'إلغاء الطلبية'),

  // الأرشيف. Three grants and not one, because they answer three different questions — and
  // none of them is [cancelOrders], which is the neighbour they are most likely to be confused
  // with. «إلغاء تام» says the order happened and ended without a delivery; «حذف» says it
  // should never have been written at all, and its undo puts the stock back on the order
  // rather than leaving the shelf alone. See §١ of ORDER-DELETE-AND-ARCHIVE.md.
  //
  // Deleting and restoring are split for the reason `orders.payments.*` splits three ways: the
  // person who may take a wrong entry out of the shop is not automatically the person who may
  // put one back, and restoring is the heavier of the two — it draws stock again, at today's
  // cost. Reading the archive is split off both, because the supervisor who checks what was
  // deleted is auditing rather than deleting.
  deleteOrders('orders.delete', 'حذف الطلبات'),
  restoreOrders('orders.restore', 'استعادة الطلبات المحذوفة'),
  viewOrderArchive('orders.archive.view', 'عرض أرشيف الطلبات'),

  // The money ledger on an order. Three, and the split that matters is the third: money going
  // *out* — refunded to the customer, or an entry cancelled as a mistake — is a different
  // decision from money coming in. Taking a deposit is a receptionist's daily work; putting a
  // hand back into the drawer belongs to whoever answers for it.
  //
  // Viewing is separate from `orders.view`, so the person printing the bags sees the order and
  // not what the customer has paid.
  viewOrderPayments('orders.payments.view', 'عرض دفعات الطلبية'),
  recordOrderPayments('orders.payments.record', 'تسجيل دفعة على الطلبية'),
  reverseOrderPayments('orders.payments.reverse', 'إلغاء دفعة أو ردّ مبلغ'),
  writeOffOrderPayments('orders.payments.write_off', 'شطب فرق مبلغ الطلبية'),

  // The carrier integration's own surface, and separate from `shipping_companies.*`: that pair
  // maintains the list of companies, this one hands parcels to one of them and answers for what
  // comes back. Split in two because seeing that a parcel is stuck is not the authority to
  // declare a delivery conflict resolved — `carrier.manage` gates exactly three buttons: lodge,
  // cancel a shipment, resolve a conflict.
  viewCarrierParcels('carrier.view', 'عرض شحنات الناقل'),
  manageCarrierParcels('carrier.manage', 'إدارة شحنات الناقل'),

  // What a unit of production standard-costs at. The rates are applied automatically the moment
  // an order enters printing, so this pair guards only the table that maintains them — the same
  // split `purchase_orders.*` draws between the paperwork and the ledger it feeds.
  viewManufacturingCostRates('manufacturing_cost_rates.view', 'عرض معدلات تكلفة التصنيع'),
  manageManufacturingCostRates('manufacturing_cost_rates.manage', 'إدارة معدلات تكلفة التصنيع'),

  // Read-only, and its own permission for one reason: every figure in it is already visible
  // somewhere else, but this is the screen that puts revenue and cost side by side — which is a
  // different sensitivity from being allowed to see either alone.
  viewProfitAndLossReport('reports.pnl.view', 'عرض تقرير الأرباح والخسائر'),

  // إحصائيات المبيعات. Separate from the one above, and not a ride on `orders.view` either:
  // the board shows what was sold and how much of it left the warehouse, with no cost and no
  // margin anywhere on it — so it can be handed to the press and the storekeeper, whose own
  // work it reports, without handing them the profit screen. Reusing `reports.pnl.view` here
  // would quietly undo that.
  viewSalesStatisticsReport('reports.sales.view', 'عرض إحصائيات المبيعات'),

  // Investors. Reading and administering are the usual pair; the three money verbs are split
  // off it for the reason `orders.payments.*` splits three ways — recording a deposit, paying an
  // investor out and undoing either are different levels of trust, and whoever edits a deal's
  // name is not necessarily whoever hands over cash.
  viewInvestors('investors.view', 'عرض المستثمرين وصفقاتهم'),
  manageInvestors('investors.manage', 'إضافة وتعديل المستثمرين والصفقات'),
  recordInvestorMoney('investors.money.record', 'تسجيل إيداع أو تمويل أو سحب لمستثمر'),
  reverseInvestorMoney('investors.money.reverse', 'عكس حركة مالية لمستثمر'),
  recordDealExpenses('investor_deals.expenses.record', 'تسجيل مصاريف الصفقة'),

  /// An investor's own account, and nothing else in the system.
  ///
  /// Held by the «مستثمر» role and by no employee. **An investor must never be granted
  /// `orders.view`**: the order resource publishes `total_cogs` and `gross_profit` to anyone who
  /// holds it, on the list endpoint as well as the detail one, so that single grant would show
  /// him every customer's margin.
  viewInvestorPortal('investor_portal.view', 'بوابة المستثمر — رأس ماله وأرباحه وحدها'),

  // The company's editable defaults. Its own pair rather than riding on an existing one:
  // everybody's screens read them and almost nobody should change them.
  viewCompanySettings('settings.view', 'عرض إعدادات الشركة'),
  manageCompanySettings('settings.manage', 'تعديل إعدادات الشركة'),

  // The audit trail. One permission, not a pair: nothing writes to it by hand.
  viewActivityLogs('logs.view', 'عرض سجل النشاطات'),

  // Interrupting every phone in the company at once. Grantable rather than a Gate on purpose,
  // so the business can hand it to a floor manager with one tick on the roles screen and no
  // deploy — which is exactly why the app must gate the compose screen on `can` and never on
  // `isAdmin`. The two agree today only because no role holds this yet.
  broadcastNotifications('notifications.broadcast', 'إرسال إشعار عام لكل الموظفين');

  const AppPermission(this.wire, this.label);

  /// Exactly the string the API sends and the route's `can:` middleware names.
  final String wire;

  /// Arabic, for a screen that lists permissions to a person. Never compared against anything.
  final String label;
}
