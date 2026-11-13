<?php

declare(strict_types=1);

namespace App\Domain\Notification\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Identity\Models\User;
use App\Domain\Notification\Enums\NotificationType;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Carbon;

/**
 * One push switch for one employee — Docs/notifications/PUSH-PREFERENCES.md.
 *
 * **Audited, unlike the rest of this context.** Notifications and device tokens are system
 * consequences; this row is a person's decision about another person's phone, and «who turned
 * off settlement pushes for this employee?» needs an answer.
 *
 * Flipped in place rather than deleted and recreated, so the history reads as one switch going
 * off and on, not as rows appearing and vanishing.
 *
 * @property int $id
 * @property int $user_id
 * @property NotificationType $type
 * @property string $scope
 * @property bool $push
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 */
class NotificationPreference extends Model implements HasAuditTrail
{
    use Auditable, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'type' => NotificationType::class,
            'push' => 'boolean',
        ];
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
