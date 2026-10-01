<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Treasury\Enums\AccountKind;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Carbon;

/**
 * «إعدادات المالية» — one row, seeded by its migration with every switch where the system already
 * stood. Read through `TreasuryService::settings()`, written through `UpdateTreasurySettings`.
 *
 * @property bool $own_account_first
 * @property bool $block_overdraft
 * @property bool $withdrawal_needs_reason
 * @property bool $ask_carrier_fee
 * @property ?Carbon $locked_until
 * @property bool $collect_cash
 * @property ?int $collect_cash_into_id
 * @property bool $collect_bank
 * @property ?int $collect_bank_into_id
 * @property bool $collect_wallet
 * @property ?int $collect_wallet_into_id
 */
#[Fillable([
    'own_account_first', 'block_overdraft', 'withdrawal_needs_reason', 'ask_carrier_fee', 'locked_until',
    'collect_cash', 'collect_cash_into_id', 'collect_bank', 'collect_bank_into_id', 'collect_wallet', 'collect_wallet_into_id',
])]
class TreasurySetting extends Model implements HasAuditTrail
{
    use Auditable, SoftDeletes;

    public const SINGLETON_ID = 1;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'own_account_first' => 'boolean',
            'block_overdraft' => 'boolean',
            'withdrawal_needs_reason' => 'boolean',
            'ask_carrier_fee' => 'boolean',
            'locked_until' => 'date',
            'collect_cash' => 'boolean',
            'collect_bank' => 'boolean',
            'collect_wallet' => 'boolean',
        ];
    }

    /** The row, which the migration guarantees exists. */
    public static function current(): self
    {
        return self::query()->findOrFail(self::SINGLETON_ID);
    }

    /**
     * Whether «التجميع عند التسوية» is on for this kind, and the account it names — null for the
     * kind's default. Custody is never collected: settlement is what empties it.
     *
     * @return array{on: bool, into: ?int}
     */
    public function collectionFor(AccountKind $kind): array
    {
        return match ($kind) {
            AccountKind::Cash => ['on' => (bool) $this->collect_cash, 'into' => $this->collect_cash_into_id],
            AccountKind::Bank => ['on' => (bool) $this->collect_bank, 'into' => $this->collect_bank_into_id],
            AccountKind::Wallet => ['on' => (bool) $this->collect_wallet, 'into' => $this->collect_wallet_into_id],
            AccountKind::Custody => ['on' => false, 'into' => null],
        };
    }

    /** Whether a hand operation on this day would fall inside the locked period. */
    public function locks(Carbon $day): bool
    {
        return $this->locked_until !== null && $day->copy()->startOfDay()->lte($this->locked_until);
    }
}
