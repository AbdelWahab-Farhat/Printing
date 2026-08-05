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
    case ManageRoles = 'roles.manage';

    // Customers
    case ViewCustomers = 'customers.view';
    case ManageCustomers = 'customers.manage';

    // Catalogue
    case ViewProducts = 'products.view';
    case ManageProducts = 'products.manage';

    // Delivery map — cities and the regions inside them share one pair: a region is never
    // administered by anyone who is not also administering its city.
    case ViewDeliveryLocations = 'cities.view';
    case ManageDeliveryLocations = 'cities.manage';

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
    case ManageOrderDesigns = 'orders.designs.manage';
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

    // The audit trail. One permission, not a pair: nothing writes to it by hand, so there is
    // nothing to manage — and reading it is its own decision, because it exposes every change
    // anyone has made to records the reader may not otherwise be allowed to see.
    case ViewActivityLogs = 'logs.view';

    public function label(): string
    {
        return match ($this) {
            self::ViewUsers => 'عرض المستخدمين',
            self::ManageUsers => 'إدارة المستخدمين وأدوارهم',
            self::ManageRoles => 'إدارة الأدوار والصلاحيات',
            self::ViewCustomers => 'عرض العملاء',
            self::ManageCustomers => 'إضافة وتعديل العملاء',
            self::ViewProducts => 'عرض المنتجات والأسعار',
            self::ManageProducts => 'إضافة وتعديل المنتجات والأسعار',
            self::ViewDeliveryLocations => 'عرض مدن ومناطق التوصيل',
            self::ManageDeliveryLocations => 'إضافة وتعديل مدن ومناطق التوصيل',
            self::ViewOrders => 'عرض الطلبيات',
            self::ManageOrders => 'إضافة وتعديل الطلبيات',
            self::DiscountOrders => 'منح خصم على الطلبية',
            self::ManageOrderDesigns => 'إدارة تصاميم الطلبية واعتمادها',
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
            self::ViewActivityLogs => 'عرض سجل النشاطات',
        };
    }

    /**
     * Used to group the catalogue in a permissions screen.
     */
    public function group(): string
    {
        return match ($this) {
            self::ViewUsers, self::ManageUsers, self::ManageRoles => 'الصلاحيات والمستخدمون',
            self::ViewCustomers, self::ManageCustomers => 'العملاء',
            self::ViewProducts, self::ManageProducts => 'المنتجات',
            self::ViewDeliveryLocations, self::ManageDeliveryLocations => 'مدن ومناطق التوصيل',
            self::ViewOrders, self::ManageOrders, self::DiscountOrders,
            self::ManageOrderDesigns => 'الطلبيات',
            self::MoveOrderToDesigning, self::MoveOrderToPrinting, self::MoveOrderToReady,
            self::MoveOrderToShortage, self::DispatchOrders, self::MarkOrdersDelivered,
            self::SettleOrders, self::RecordCourierReturn, self::RecordCarrierReturn,
            self::RecordOfficeReturn, self::ResendOrders,
            self::CancelOrders => 'حالات الطلبيات',
            self::ViewActivityLogs => 'سجل النشاطات',
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
