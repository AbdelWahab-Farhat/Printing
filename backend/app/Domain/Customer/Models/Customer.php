<?php

declare(strict_types=1);

namespace App\Domain\Customer\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Comment\Concerns\HasComments;
use App\Domain\Comment\Models\Comment;
use App\Domain\Customer\Actions\AllocateCustomerIdentifier;
use Database\Factories\CustomerFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * A customer of the printing business.
 *
 * `code` is deliberately absent from the fillable list: it is allocated by
 * {@see AllocateCustomerIdentifier} and must never be
 * settable from a request.
 *
 * Soft deleting does not change the standing rule that a customer is *deactivated*, never
 * deleted — there is still no destroy route. It is the floor under that rule: if one is ever
 * removed, by a console command or a future endpoint, the row and its history survive.
 */
#[UseFactory(CustomerFactory::class)]
#[Fillable(['name', 'phone', 'is_active'])]
class Customer extends Model implements HasAuditTrail
{
    /** @use HasFactory<CustomerFactory> */
    use Auditable, HasComments, HasFactory, SoftDeletes;

    /**
     * Everything {@see CustomerShopResource} renders about a shop.
     *
     * Named once because five call sites load it — create, update, show, activation and the
     * list — and a relation added to the resource but forgotten at one of them is not a broken
     * response, it is a silent query per row that nobody notices until the list is slow.
     *
     * @var list<string>
     */
    public const SHOP_RELATIONS = ['shops.businessField', 'shops.city', 'shops.region'];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            // Not a column: {@see \App\Domain\Customer\Queries\CustomerListQuery} selects it as
            // a subquery when the list is sorted by it, and a cast is what turns the string the
            // driver hands back into the date the resource formats. Absent on every other path,
            // which is why the resource asks `whenHas` before reading it.
            'last_order_at' => 'datetime',
        ];
    }

    /**
     * @return HasMany<CustomerShop, $this>
     */
    /**
     * The artwork this customer wants printed — an image or a PDF each.
     *
     * Newest first: the design somebody is looking for is nearly always the one just uploaded.
     *
     * @return HasMany<CustomerDesign, $this>
     */
    public function designs(): HasMany
    {
        return $this->hasMany(CustomerDesign::class)->latest('id');
    }

    public function shops(): HasMany
    {
        return $this->hasMany(CustomerShop::class);
    }

    /**
     * A customer's history includes their shops', because a shop is not a record anyone opens
     * on its own — it is edited through the customer, and "we moved their شارع الجمهورية branch"
     * is part of that customer's story.
     *
     * `withTrashed`, deliberately: a shop that was removed is precisely the change someone
     * reading the history is looking for.
     *
     * @return array<string, list<int|string>>
     */
    public function auditTrailSubjects(): array
    {
        return [
            $this->getMorphClass() => [$this->getKey()],
            (new CustomerShop)->getMorphClass() => $this->shops()->withTrashed()->pluck('id')->all(),
            // `withTrashed` deliberately: "who removed the logo we were printing?" is exactly
            // the question this history exists to answer, and a removed design is the only kind
            // anyone asks about.
            (new CustomerDesign)->getMorphClass() => $this->designs()->withTrashed()->pluck('id')->all(),
            // Same reasoning, and the same `withTrashed`: «من حذف الملاحظة؟» is a question about
            // this customer, and a removed note is the only kind anyone goes looking for.
            (new Comment)->getMorphClass() => $this->comments()->withTrashed()->pluck('id')->all(),
        ];
    }
}
