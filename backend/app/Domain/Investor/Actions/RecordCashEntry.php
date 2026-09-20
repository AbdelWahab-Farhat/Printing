<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Models\InvestmentCashEntry;
use App\Domain\Investor\Support\Money;
use DateTimeInterface;

/**
 * البابُ الوحيد الذي يدخل منه صفٌّ إلى خزينة الصندوق.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحة ٤.
 *
 * **ولماذا بابٌ واحد.** الخزينةُ دفترٌ يُعدّ بورقة: «كم في الصندوق نقداً» سؤالٌ يُسأل عند كل
 * شراءٍ وكل سحب. وصفٌّ يدخلها من طريقٍ جانبيّ بلا مصدرٍ يسمّيه هو دينارٌ لا يعرف أحدٌ من أين
 * جاء — ولذلك {@see CashEntryType::isRecordableByHand()} كاذبةٌ على كل نوع.
 *
 * **والتكرارُ لا يضاعف.** مستمعٌ يعمل مرّتين — أو موظّفٌ يضغط الزرَّ مرّتين — يصل بالمصدر نفسه،
 * فيُقرأ الصفُّ القائم ويُعاد كما هو. والفهرسُ الفريد `(source_type, source_id, source_sequence)`
 * هو الحارسُ الذي لا ينساه أحد: هذا الفحصُ يُخرج صفّاً بدل استثناءٍ يظهر للمستخدم.
 */
final class RecordCashEntry
{
    public function __invoke(
        CashEntryType $type,
        string $amount,
        string $sourceType,
        int $sourceId,
        ?int $actorId = null,
        ?DateTimeInterface $occurredAt = null,
        int $sourceSequence = 1,
        ?string $notes = null,
    ): InvestmentCashEntry {
        $standing = InvestmentCashEntry::query()
            ->where('source_type', $sourceType)
            ->where('source_id', $sourceId)
            ->where('source_sequence', $sourceSequence)
            ->first();

        if ($standing !== null) {
            return $standing;
        }

        $entry = new InvestmentCashEntry;
        $entry->type = $type;
        $entry->amount = Money::round($amount);
        $entry->source_type = $sourceType;
        $entry->source_id = $sourceId;
        $entry->source_sequence = $sourceSequence;
        $entry->occurred_at = $occurredAt ?? now();
        $entry->notes = $notes;
        $entry->recorded_by = $actorId;
        $entry->save();

        return $entry;
    }

    /**
     * يُبطل صفّاً قائماً بصفٍّ يحمل مبلغَه كما هو.
     *
     * الشريحة ٠ب: الصلاحيةُ كانت معرَّفةً بلا مسار. والعكسُ **لا يُعكس** — «عكسُ عكسٍ متاهةٌ بلا
     * أرضية»، والفهرسُ الفريد خلف `reverses_entry_id` يمنع الثاني على كل حال.
     */
    public function reverse(InvestmentCashEntry $entry, ?int $actorId, ?string $notes = null): InvestmentCashEntry
    {
        $reversal = new InvestmentCashEntry;
        $reversal->type = CashEntryType::Reversal;
        $reversal->amount = (string) $entry->amount;
        $reversal->reverses_entry_id = $entry->getKey();
        $reversal->occurred_at = now();
        $reversal->notes = $notes;
        $reversal->recorded_by = $actorId;
        $reversal->save();

        return $reversal;
    }
}
