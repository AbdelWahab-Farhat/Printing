<?php

declare(strict_types=1);

namespace App\Domain\Audit\Enums;

use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductImage;
use App\Domain\Catalog\Models\ProductPriceTier;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Customer\Models\BusinessField;
use App\Domain\Customer\Models\Customer;
use App\Domain\Customer\Models\CustomerDesign;
use App\Domain\Customer\Models\CustomerShop;
use App\Domain\Delivery\Models\City;
use App\Domain\Delivery\Models\Region;
use App\Domain\Delivery\Models\ShippingCompany;
use App\Domain\Identity\Models\Role;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Inventory\Models\WarehouseStock;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderDesign;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Order\Models\OrderStatusTransition;
use App\Domain\Vendor\Models\StockArrival;
use App\Domain\Vendor\Models\StockArrivalItem;
use App\Domain\Vendor\Models\Vendor;
use App\Providers\AppServiceProvider;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\Relation;

/**
 * Every kind of record the audit trail can describe — and the application's morph map.
 *
 * `activity_log.subject_type` is a *published* value: clients read it, and rows written today
 * will still be read years from now. A PHP class name is the wrong thing to publish. It leaks
 * `App\Domain\Catalog\Models\Product` into the API, and the day a model moves between contexts
 * every historical row silently stops resolving. The alias is ours to keep stable.
 *
 * Registered as Laravel's morph map in {@see AppServiceProvider}, so it governs
 * *every* polymorphic column — the audit trail's subject and causer, Sanctum's `tokenable`, and
 * Spatie's `model_has_roles`. That is why adding a case here is not optional bookkeeping:
 * `ModelConventionsTest` fails the build when a domain model is missing one.
 *
 * The map is not enforced (`Relation::morphMap`, not `enforceMorphMap`). An unmapped model
 * keeps working with its class name rather than throwing at runtime — the test is a better
 * place to catch the omission than a 500 in front of a user.
 */
enum AuditSubject: string
{
    // Identity
    case User = 'user';
    case Role = 'role';

    // Customers
    case Customer = 'customer';
    case CustomerShop = 'customer_shop';
    case CustomerDesign = 'customer_design';
    case BusinessField = 'business_field';

    // Catalogue
    case Product = 'product';
    case ProductVariant = 'product_variant';
    case ProductPriceTier = 'product_price_tier';
    case ProductImage = 'product_image';

    // Orders
    case Order = 'order';
    case OrderItem = 'order_item';
    case OrderDesign = 'order_design';
    case OrderStatusTransition = 'order_status_transition';
    case OrderPayment = 'order_payment';

    // Delivery map
    case City = 'city';
    case Region = 'region';
    case ShippingCompany = 'shipping_company';

    // Inventory
    case Warehouse = 'warehouse';
    case WarehouseStock = 'warehouse_stock';
    case StockMovement = 'stock_movement';

    // Vendors
    case Vendor = 'vendor';
    case StockArrival = 'stock_arrival';
    case StockArrivalItem = 'stock_arrival_item';

    /**
     * @return class-string<Model>
     */
    public function modelClass(): string
    {
        return match ($this) {
            self::User => User::class,
            self::Role => Role::class,
            self::Customer => Customer::class,
            self::CustomerShop => CustomerShop::class,
            self::CustomerDesign => CustomerDesign::class,
            self::BusinessField => BusinessField::class,
            self::Product => Product::class,
            self::ProductVariant => ProductVariant::class,
            self::ProductPriceTier => ProductPriceTier::class,
            self::ProductImage => ProductImage::class,
            self::Order => Order::class,
            self::OrderItem => OrderItem::class,
            self::OrderDesign => OrderDesign::class,
            self::OrderStatusTransition => OrderStatusTransition::class,
            self::OrderPayment => OrderPayment::class,
            self::City => City::class,
            self::Region => Region::class,
            self::ShippingCompany => ShippingCompany::class,
            self::Warehouse => Warehouse::class,
            self::WarehouseStock => WarehouseStock::class,
            self::StockMovement => StockMovement::class,
            self::Vendor => Vendor::class,
            self::StockArrival => StockArrival::class,
            self::StockArrivalItem => StockArrivalItem::class,
        };
    }

    /**
     * What to call this kind of record in a history screen.
     */
    public function label(): string
    {
        return match ($this) {
            self::User => 'مستخدم',
            self::Role => 'دور',
            self::Customer => 'عميل',
            self::CustomerShop => 'محل عميل',
            self::CustomerDesign => 'تصميم عميل',
            self::BusinessField => 'مجال عمل',
            self::Product => 'منتج',
            self::ProductVariant => 'مقاس منتج',
            self::ProductPriceTier => 'شريحة سعر',
            self::ProductImage => 'صورة منتج',
            self::Order => 'طلبية',
            self::OrderItem => 'بند طلبية',
            self::OrderDesign => 'تصميم طلبية',
            self::OrderStatusTransition => 'انتقال حالة طلبية',
            self::OrderPayment => 'دفعة طلبية',
            self::City => 'مدينة',
            self::Region => 'منطقة',
            self::ShippingCompany => 'شركة توصيل',
            self::Warehouse => 'مخزن',
            self::WarehouseStock => 'رصيد مخزني',
            self::StockMovement => 'حركة مخزنية',
            self::Vendor => 'مورد',
            self::StockArrival => 'توريد',
            self::StockArrivalItem => 'بند توريد',
        };
    }

    /**
     * The map Laravel is handed at boot: alias => class.
     *
     * @return array<string, class-string<Model>>
     */
    public static function morphMap(): array
    {
        $map = [];

        foreach (self::cases() as $subject) {
            $map[$subject->value] = $subject->modelClass();
        }

        return $map;
    }

    /**
     * The alias a model is stored under. Reads it from the live morph map rather than from this
     * enum, so a model that somehow escaped registration is reported as whatever the database
     * would actually hold for it.
     */
    public static function aliasFor(Model $model): string
    {
        return $model->getMorphClass();
    }

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return array_map(fn (self $subject) => $subject->value, self::cases());
    }

    /**
     * Whether the given alias is one this application publishes. Used to reject a filter naming
     * a subject type that cannot exist, rather than quietly returning an empty page.
     */
    public static function isKnown(string $alias): bool
    {
        return self::tryFrom($alias) !== null;
    }

    /**
     * Registers the map with Eloquent. Called once, from the service provider.
     */
    public static function register(): void
    {
        Relation::morphMap(self::morphMap());
    }
}
