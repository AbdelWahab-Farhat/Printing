<?php

declare(strict_types=1);

namespace App\Domain\Customer\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use Database\Factories\CustomerCommentFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * One thing a member of staff wrote about a customer.
 *
 * **`user_id` is not fillable, and that is the model's one rule.** A note is attributed, and
 * attribution is what makes it worth reading — «قال محمد إنه لا يردّ إلا على واتساب» can be
 * followed up; «مكتوب أنه لا يردّ» cannot. The author is stamped from the authenticated user
 * when the row is created and has no path to change afterwards, so a mass-assignment from a
 * request body can never sign somebody else's name to a sentence.
 *
 * Who may change one lives here rather than in the controller: the same question is asked twice
 * — once to refuse the request, once to tell the app whether to draw the button — and two copies
 * of an authorization rule is one copy too many. See {@see isChangeableBy()}.
 */
#[UseFactory(CustomerCommentFactory::class)]
#[Fillable(['body'])]
class CustomerComment extends Model implements HasAuditTrail
{
    /** @use HasFactory<CustomerCommentFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, mixed>
     */
    protected function casts(): array
    {
        return ['edited_at' => 'datetime'];
    }

    /**
     * @return BelongsTo<Customer, $this>
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /**
     * Its own history and nothing else — a note owns no other record.
     *
     * @return array<string, list<int|string>>
     */
    public function auditTrailSubjects(): array
    {
        return [$this->getMorphClass() => [$this->getKey()]];
    }

    /**
     * Whether this reader may rewrite or remove this note.
     *
     * **Its author, or somebody the business has explicitly made a moderator.** Deliberately not
     * `customers.manage`: correcting a customer's phone number and rewriting a colleague's
     * sentence under their name are different powers, and a business that wants to grant one
     * without the other has no way to say so if they share a permission.
     *
     * The administrator passes through the gate in `AppServiceProvider`, which answers `true`
     * for every permission — so no case is needed for them here.
     */
    public function isChangeableBy(?User $user): bool
    {
        if ($user === null) {
            return false;
        }

        return $this->user_id === $user->getKey()
            || $user->can(PermissionName::ModerateCustomerComments->value);
    }
}
