<?php

declare(strict_types=1);

namespace App\Domain\Identity\Enums;

/**
 * Every permission the system recognises.
 *
 * **Permissions are defined by the code; roles are created by the administrator.** That split
 * matters. A permission is only real because something in the codebase checks for it, so
 * letting anyone invent one at runtime would produce a row that grants nothing and a checkbox
 * that lies. Roles are the opposite — pure policy, and entirely the business's to shape.
 *
 * So the administrator's job is: create a role, tick permissions from this catalogue, give it
 * to staff. Adding a *new* permission means adding a case here and guarding an endpoint with
 * it — a code change, because it is one.
 */
enum PermissionName: string
{
    // Access management
    case ViewUsers = 'users.view';
    case ManageUsers = 'users.manage';

    // Seeing what a colleague is paid, and setting it. **Its own permission, deliberately not
    // part of `users.manage`**: assigning somebody a role and knowing everyone's wage are
    // different jobs, and the accountant who needs the second usually has no business with the
    // first. Both halves are one case rather than a view/manage pair, because a wage is one
    // number on one screen — the person trusted to read it is the person who agrees it.
    case ManageUserSalaries = 'users.salary';
    case ManageRoles = 'roles.manage';

    // Customers
    case ViewCustomers = 'customers.view';
    case ManageCustomers = 'customers.manage';

    // Rewriting or removing a note somebody else wrote — on a customer, on a supplier, on
    // whatever gains notes next. Its own permission rather than part of `customers.manage`,
    // because they are different powers: correcting a phone number is bookkeeping, while editing
    // a colleague's sentence under their name is a claim about what they said. Everybody who may
    // read a record may *write* a note on it and change their own — that needs no grant at all.
    //
    // **One permission, not one per kind of record.** The question is «هل يعدّل هذا الموظف كلام
    // زميله؟», and it has one answer per employee. See GENERAL-COMMENTS.md §١.
    case ModerateComments = 'comments.moderate';

    // مجالات العمل — what a customer's shop sells. Reading is split from managing and granted
    // to every role, because anyone recording a customer needs the list to pick from; curating
    // the list itself is a rarer, deliberate job. Same shape as the delivery map, for the same
    // reason.
    case ViewBusinessFields = 'business_fields.view';
    case ManageBusinessFields = 'business_fields.manage';

    // Catalogue
    case ViewProducts = 'products.view';
    case ManageProducts = 'products.manage';

    // Delivery map — cities and the regions inside them share one pair: a region is never
    // administered by anyone who is not also administering its city.
    case ViewDeliveryLocations = 'cities.view';
    case ManageDeliveryLocations = 'cities.manage';

    // Who carries the parcels. Separate from the map above: the person who agrees rates with a
    // carrier is not the person who maintains the list of neighbourhoods.
    case ViewShippingCompanies = 'shipping_companies.view';
    case ManageShippingCompanies = 'shipping_companies.manage';

    // Orders. One permission per status the machine can move *into*, so the business composes
    // a designer, a printer and a delivery coordinator out of this list without any of those
    // jobs being named in the code. See OrderStatus::permission().
    //
    // The two dispatch statuses share `DispatchOrders` on purpose: the clerk says "it is going
    // out" and the destination city decides whether that means استلام مكتب or جاري التوصيل, so
    // two grants would make one button succeed for طرابلس and fail for قرجي. The three returns
    // stay separate because a clerk *does* choose which of them happened.
    case ViewOrders = 'orders.view';
    case ManageOrders = 'orders.manage';
    case DiscountOrders = 'orders.discount';
    // Its own grant rather than the discount's: one gives money away and the other asks the
    // customer for more, and a business may reasonably trust a role with exactly one of them.
    case AddOrderAdditionalCost = 'orders.additional_cost';
    case ManageOrderDesigns = 'orders.designs.manage';
    // The warehouse's own grant: it weighs the goods, names the shelf they leave from, and hands
    // the order to the press. Separate from the two production statuses beside it because a
    // different desk does it.
    case MoveOrderToReadyToPrint = 'orders.status.ready_to_print';
    case MoveOrderToDesigning = 'orders.status.designing';
    case MoveOrderToPrinting = 'orders.status.printing';
    case MoveOrderToReady = 'orders.status.ready';
    case MoveOrderToShortage = 'orders.status.shortage';
    case DispatchOrders = 'orders.status.dispatch';
    case MarkOrdersDelivered = 'orders.status.delivered';
    case SettleOrders = 'orders.status.settled';
    case RecordCourierReturn = 'orders.status.returned_courier';
    case RecordCarrierReturn = 'orders.status.returned_carrier';
    case RecordOfficeReturn = 'orders.status.returned_office';
    case ResendOrders = 'orders.status.resend';
    case CancelOrders = 'orders.status.cancelled';

    // The money ledger on an order. Four, and the splits that matter are the last two: money
    // going *out* — a refund to the customer, or an entry cancelled as a mistake — is a
    // different decision from money coming in. Taking a deposit is a receptionist's daily work;
    // putting a hand back into the drawer belongs to whoever answers for it.
    //
    // **And forgiving a debt is a third decision again**, which is why it is not folded into the
    // one above it: a refund hands back money the business already holds, while a write-off
    // decides that money it is owed will never arrive. The second is the only one of the four
    // that turns a shortfall into a loss, and it belongs to whoever answers for the books rather
    // than to everyone who may open the drawer.
    //
    // Viewing is separate from `orders.view` on purpose: the person printing the bags sees the
    // order and has no business with what the customer has paid.
    case ViewOrderPayments = 'orders.payments.view';
    case RecordOrderPayments = 'orders.payments.record';
    case ReverseOrderPayments = 'orders.payments.reverse';
    case WriteOffOrderPayments = 'orders.payments.write_off';

    // What a unit of production standard-costs at — labour, machine runtime, overhead. Applied
    // automatically when an order enters printing (see ApplyManufacturingRates), so this pair
    // guards only the admin screen that maintains the rate table itself, the same split
    // purchase_orders.* draws between paperwork and the ledger it feeds.
    case ViewManufacturingCostRates = 'manufacturing_cost_rates.view';
    case ManageManufacturingCostRates = 'manufacturing_cost_rates.manage';

    // Stock. One pair covers warehouses, balances and the ledger: whoever may move stock between
    // two warehouses is necessarily administering both, so splitting them would produce a
    // permission that cannot usefully be granted alone. Reading is separate because taking an
    // order needs to know whether stock exists, while moving it is the storekeeper's job.
    case ViewInventory = 'inventory.view';
    case ManageInventory = 'inventory.manage';
    // Its own grant rather than part of `inventory.manage`: correcting what stock is carried at
    // changes the book value of the business without a shelf being touched, which is a different
    // trust level from recording a transfer somebody can walk over and verify.
    case RevalueStock = 'inventory.revalue';

    // Vendors. Its own pair rather than folded into inventory.*: agreeing terms with a supplier
    // and receiving a shipment they sent are different jobs, the same split customers.* draws
    // between the person and what they buy. Posting a stock arrival itself stays under
    // inventory.* — see StockArrivalController — because it is squarely part of the ledger.
    case ViewVendors = 'vendors.view';
    case ManageVendors = 'vendors.manage';

    // Purchase orders. Drafting, editing, sending and cancelling the paperwork is its own pair,
    // the same reasoning vendors.* carries — but *receiving* against one stays under
    // inventory.manage, not this pair: see PurchaseOrderController::receiveArrival(). Posting a
    // shipment is squarely part of the ledger regardless of which door it came in through, and
    // splitting it out here would let someone who may only draft orders also post stock, or the
    // reverse, neither of which this pair is meant to grant.
    case ViewPurchaseOrders = 'purchase_orders.view';
    case ManagePurchaseOrders = 'purchase_orders.manage';

    // The audit trail. One permission, not a pair: nothing writes to it by hand, so there is
    // nothing to manage — and reading it is its own decision, because it exposes every change
    // anyone has made to records the reader may not otherwise be allowed to see.
    case ViewActivityLogs = 'logs.view';

    // Profit & loss. Read-only — the report is built entirely from figures every other context
    // already computes and caches (order totals, cost of goods sold, the payment ledger) — but
    // it is the one screen that puts revenue and cost side by side, which is a different
    // sensitivity from being allowed to see either alone.
    case ViewProfitAndLossReport = 'reports.pnl.view';

    public function label(): string
    {
        return match ($this) {
            self::ViewUsers => 'عرض المستخدمين',
            self::ManageUsers => 'إدارة المستخدمين وأدوارهم',
            self::ManageUserSalaries => 'عرض رواتب الموظفين وتعديلها',
            self::ManageRoles => 'إدارة الأدوار والصلاحيات',
            self::ViewCustomers => 'عرض العملاء',
            self::ManageCustomers => 'إضافة وتعديل العملاء',
            self::ModerateComments => 'تعديل وحذف ملاحظات الآخرين',
            self::ViewBusinessFields => 'عرض مجالات العمل',
            self::ManageBusinessFields => 'إضافة وتعديل مجالات العمل',
            self::ViewProducts => 'عرض المنتجات والأسعار',
            self::ManageProducts => 'إضافة وتعديل المنتجات والأسعار',
            self::ViewDeliveryLocations => 'عرض مدن ومناطق التوصيل',
            self::ManageDeliveryLocations => 'إضافة وتعديل مدن ومناطق التوصيل',
            self::ViewShippingCompanies => 'عرض شركات التوصيل',
            self::ManageShippingCompanies => 'إضافة وتعديل شركات التوصيل',
            self::ViewOrders => 'عرض الطلبيات',
            self::ManageOrders => 'إضافة وتعديل الطلبيات',
            self::DiscountOrders => 'منح خصم على الطلبية',
            self::AddOrderAdditionalCost => 'إضافة تكلفة إضافية على الطلبية',
            self::ManageOrderDesigns => 'إدارة تصاميم الطلبية واعتمادها',
            self::MoveOrderToReadyToPrint => 'تحويل الطلبية إلى جاهزة للطباعة',
            self::MoveOrderToDesigning => 'تحويل الطلبية إلى قيد التصميم',
            self::MoveOrderToPrinting => 'تحويل الطلبية إلى قيد الطباعة',
            self::MoveOrderToReady => 'تحويل الطلبية إلى جاهزة',
            self::MoveOrderToShortage => 'تحويل الطلبية إلى نواقص',
            self::DispatchOrders => 'تسليم الطلبية للتوصيل أو للاستلام من المكتب',
            self::MarkOrdersDelivered => 'تأكيد استلام العميل للطلبية',
            self::SettleOrders => 'تسوية مبلغ الطلبية',
            self::RecordCourierReturn => 'تسجيل راجع لدى المندوب',
            self::RecordCarrierReturn => 'تسجيل راجع لدى شركة التوصيل',
            self::RecordOfficeReturn => 'تسجيل راجع مكتب',
            self::ResendOrders => 'إعادة إرسال طلبية راجعة',
            self::CancelOrders => 'إلغاء الطلبية',

            self::ViewOrderPayments => 'عرض دفعات الطلبية',
            self::RecordOrderPayments => 'تسجيل دفعة على الطلبية',
            self::ReverseOrderPayments => 'إلغاء دفعة أو ردّ مبلغ',
            self::WriteOffOrderPayments => 'شطب فرق مبلغ الطلبية',
            self::ViewManufacturingCostRates => 'عرض معدلات تكلفة التصنيع',
            self::ManageManufacturingCostRates => 'إدارة معدلات تكلفة التصنيع',

            self::ViewInventory => 'عرض المخازن والأرصدة والحركات',
            self::ManageInventory => 'إدارة المخازن وتسجيل حركات المخزون',
            self::RevalueStock => 'تعديل تكلفة دفعات المخزون',
            self::ViewVendors => 'عرض الموردين',
            self::ManageVendors => 'إضافة وتعديل الموردين',
            self::ViewPurchaseOrders => 'عرض أوامر الشراء',
            self::ManagePurchaseOrders => 'إنشاء وتعديل أوامر الشراء وإرسالها وإلغاؤها',
            self::ViewActivityLogs => 'عرض سجل النشاطات',
            self::ViewProfitAndLossReport => 'عرض تقرير الأرباح والخسائر',
        };
    }

    /**
     * Used to group the catalogue in a permissions screen.
     */
    public function group(): string
    {
        return match ($this) {
            self::ViewUsers, self::ManageUsers, self::ManageUserSalaries,
            self::ManageRoles => 'الصلاحيات والمستخدمون',
            self::ViewCustomers, self::ManageCustomers,
            self::ModerateComments => 'الملاحظات',
            self::ViewBusinessFields, self::ManageBusinessFields => 'مجالات العمل',
            self::ViewProducts, self::ManageProducts => 'المنتجات',
            self::ViewDeliveryLocations, self::ManageDeliveryLocations => 'مدن ومناطق التوصيل',
            self::ViewShippingCompanies, self::ManageShippingCompanies => 'شركات التوصيل',
            self::ViewOrders, self::ManageOrders, self::DiscountOrders,
            self::AddOrderAdditionalCost,
            self::ManageOrderDesigns => 'الطلبيات',
            self::MoveOrderToReadyToPrint,
            self::MoveOrderToDesigning, self::MoveOrderToPrinting, self::MoveOrderToReady,
            self::MoveOrderToShortage, self::DispatchOrders, self::MarkOrdersDelivered,
            self::SettleOrders, self::RecordCourierReturn, self::RecordCarrierReturn,
            self::RecordOfficeReturn, self::ResendOrders,
            self::CancelOrders => 'حالات الطلبيات',

            self::ViewOrderPayments, self::RecordOrderPayments,
            self::ReverseOrderPayments, self::WriteOffOrderPayments => 'مدفوعات الطلبيات',

            self::ViewManufacturingCostRates,
            self::ManageManufacturingCostRates => 'معدلات تكلفة التصنيع',

            self::ViewInventory, self::ManageInventory,
            self::RevalueStock => 'المخازن والمخزون',
            self::ViewVendors, self::ManageVendors => 'الموردون',
            self::ViewPurchaseOrders, self::ManagePurchaseOrders => 'أوامر الشراء',
            self::ViewActivityLogs => 'سجل النشاطات',
            self::ViewProfitAndLossReport => 'التقارير المالية',
        };
    }

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return array_map(fn (self $permission) => $permission->value, self::cases());
    }
}
