<?php

declare(strict_types=1);

namespace App\Domain\Customer\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Customer\Actions\SyncCustomerSocialLinks;
use Database\Factories\CustomerSocialLinkFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * رابطُ تواصلٍ للعميل — صفحته على فيسبوك أو حسابه على إنستغرام أو أيّ رابطٍ آخر.
 *
 * ملكُ عميله كالمحل: لا حياة له وحده، ويُدار من خلال العميل — `PUT /customers/{customer}` عند
 * الموظفين و`PUT /client/social-links` عند العميل، وكلاهما يزامن المجموعة كلّها
 * ({@see SyncCustomerSocialLinks}).
 *
 * يُسجَّل في سجل التعديلات، ويُقرأ سجلّه من `GET /customers/{customer}/logs` لا من مسارٍ له، كالمحل.
 */
#[UseFactory(CustomerSocialLinkFactory::class)]
#[Fillable(['url'])]
class CustomerSocialLink extends Model
{
    /** @use HasFactory<CustomerSocialLinkFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return BelongsTo<Customer, $this>
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }
}
