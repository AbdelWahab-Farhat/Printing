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
