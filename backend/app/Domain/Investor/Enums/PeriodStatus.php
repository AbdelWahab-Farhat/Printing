<?php

declare(strict_types=1);

namespace App\Domain\Investor\Enums;

/**
 * أين الفترةُ من عمرها — وحالتان لا ثالثة.
 *
 * **لا «مسودة» ولا «ملغاة».** الفترةُ لا تُنشأ بقرارٍ إنسانٍ لتُراجَع قبل اعتمادها؛ تُفتح آلياً
 * حين تُقفَل سابقتُها، فليس ثمّة لحظةٌ تكون فيها موجودةً وغيرَ عاملة. وإلغاؤها أشدّ استحالة:
 * الزمنُ مضى، والطلبيات التي وقعت فيها وقعت.
 *
 * و`Closed` **ليست حالةً تُبلَغ من نقطةِ تغييرِ حالة** — هي نتيجةُ `CloseInvestmentPeriod`
 * وحدها، بالانضباط نفسه الذي تمشي عليه `PurchaseOrderStatus::Completed` و`DealStatus::Closed`:
 * لها شروطٌ تُفحص، وفعلٌ يفحصها، فعرضُها كخيارٍ ثم رفضُه بابٌ لسوء فهم.
 */
enum PeriodStatus: string
{
    /** تستقبل الطلبيات والمشتريات والمصاريف، ولها وحدها هذه الصفة في أيّ لحظة. */
    case Open = 'open';

    /** حُسبت أرقامُها وجُمِّدت، وأُفرِج عن أرباحها إلى محافظ أصحابها. */
    case Closed = 'closed';

    public function label(): string
    {
        return match ($this) {
            self::Open => 'مفتوحة',
            self::Closed => 'مغلقة',
        };
    }

    /** أتقبل قيداً جديداً — ربحاً أو مصروفاً أو إيداعاً؟ */
    public function acceptsPostings(): bool
    {
        return $this === self::Open;
    }
}
