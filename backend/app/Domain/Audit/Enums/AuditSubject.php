<?php

declare(strict_types=1);

namespace App\Domain\Audit\Enums;

use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductImage;
use App\Domain\Catalog\Models\ProductPriceTier;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Customer\Models\Customer;
use App\Domain\Customer\Models\CustomerShop;
use App\Domain\Delivery\Models\City;
use App\Domain\Delivery\Models\Region;
use App\Domain\Identity\Models\Role;
use App\Domain\Identity\Models\User;
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

    // Catalogue
    case Product = 'product';
    case ProductVariant = 'product_variant';
    case ProductPriceTier = 'product_price_tier';
    case ProductImage = 'product_image';

    // Delivery map
    case City = 'city';
    case Region = 'region';

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
            self::Product => Product::class,
            self::ProductVariant => ProductVariant::class,
            self::ProductPriceTier => ProductPriceTier::class,
            self::ProductImage => ProductImage::class,
            self::City => City::class,
            self::Region => Region::class,
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
            self::Product => 'منتج',
            self::ProductVariant => 'مقاس منتج',
            self::ProductPriceTier => 'شريحة سعر',
            self::ProductImage => 'صورة منتج',
            self::City => 'مدينة',
            self::Region => 'منطقة',
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
