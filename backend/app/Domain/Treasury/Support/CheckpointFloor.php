<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Support;

use App\Domain\Treasury\Enums\OperationType;
use App\Domain\Treasury\Exceptions\OperationRefused;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryOperation;
use DateTimeInterface;
use Illuminate\Support\Carbon;

/**
 * الأرضيةُ التي لا يُؤرَّخ مالٌ يدويّ تحتها: آخرُ نقطة عدٍّ للحساب.
 *
 * **نقطةُ العدّ** رصيدٌ افتتاحي أو «جرد الحساب»: شهادةُ المالك أن الدرج كان فيه كذا يومها. حركةٌ
 * تُدسّ قبلها تجعل الشهادةَ تكذب بلا أثر — يصير «ما كان يومها» رقماً غير الذي عُدّ. فلا يُؤرَّخ
 * شيءٌ باليد قبل آخرها؛ والجردُ المعكوس لم يعد شهادةً فلا يحرس شيئاً.
 *
 * والآليُّ لا يمرّ من هنا: دفعةٌ أو عكسٌ حدثٌ وقع، ورفضُ تسجيله لا يجعله غيرَ واقع.
 */
final class CheckpointFloor
{
    /**
     * @param  bool  $wholeDay  التاريخُ يومٌ بلا ساعة: يُرفض إن وقع في يومٍ قبل يوم آخر عدٍّ،
     *                          ويمرّ في يومه نفسه — فشراءُ اليوم لا يُردّ لأن الخزنة عُدّت صباحاً
     */
    public function guard(
        TreasuryAccount $account,
        DateTimeInterface $at,
        string $field,
        bool $wholeDay = false,
    ): void {
        $checkpoint = $this->latestOf((int) $account->getKey());

        if ($checkpoint === null) {
            return;
        }

        $moment = Carbon::instance($at);
        $floor = $checkpoint->occurred_at;

        $before = $wholeDay
            ? $moment->toDateString() < $floor->toDateString()
            : $moment->lt($floor);

        if ($before) {
            throw OperationRefused::beforeCheckpoint(
                (string) $account->name,
                $checkpoint->type,
                $floor->format('Y-m-d H:i'),
                $field,
            );
        }
    }

    /** آخرُ افتتاحٍ أو جردٍ قائمٍ للحساب — لا عكسٌ، ولا ما عُكس. */
    public function latestOf(int $accountId): ?TreasuryOperation
    {
        return TreasuryOperation::query()
            ->whereIn('type', [OperationType::Opening->value, OperationType::Adjustment->value])
            ->whereNull('reverses_operation_id')
            ->whereDoesntHave('reversedBy')
            ->where(fn ($q) => $q
                ->where('to_account_id', $accountId)
                ->orWhere('from_account_id', $accountId))
            ->orderByDesc('occurred_at')
            ->orderByDesc('id')
            ->first();
    }
}
