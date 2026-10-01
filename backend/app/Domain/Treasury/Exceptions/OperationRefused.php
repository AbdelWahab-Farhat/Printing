<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Exceptions;

use App\Domain\Treasury\Enums\OperationType;
use App\Support\Exceptions\DomainException;

/**
 * An operation the treasury will not write, each for a reason it names.
 */
final class OperationRefused extends DomainException
{
    public function __construct(string $message, private readonly ?string $field = null)
    {
        parent::__construct($message);
    }

    public static function openingExists(string $account): self
    {
        return new self("لـ«{$account}» رصيد افتتاحي مسجَّل — صحّحه بجرد الحساب", 'to_account_id');
    }

    /**
     * حسابٌ تحرّك قبل أن يُفتتح — بعد استيراد المدفوعات القديمة مثلاً. افتتاحٌ فوق حركاته يعدّ
     * مالها مرّتين؛ والعدُّ الذي يصحّحه هو «جرد الحساب»، يكتب الفرقَ وحده.
     */
    public static function accountHasMovements(string $account): self
    {
        return new self(
            "«{$account}» عليه حركات مسجّلة — يُضبط رصيده بـ«جرد الحساب» لا برصيد افتتاحي",
            'to_account_id',
        );
    }

    public static function balanceUnchanged(string $account): self
    {
        return new self("الرصيد المعدود يطابق رصيد «{$account}» — لا فرق يُسجَّل", 'counted_balance');
    }

    public static function categoryNeedsEmployee(string $category): self
    {
        return new self("تصنيف «{$category}» يتطلب تحديد الموظف", 'employee_id');
    }

    public static function categoryInactive(string $category): self
    {
        return new self("تصنيف «{$category}» معطَّل", 'category_id');
    }

    public static function notReversible(string $type): self
    {
        return new self("عملية «{$type}» لا تُعكس من هنا");
    }

    public static function isAReversal(): self
    {
        return new self('هذه العملية عكسٌ لغيرها — تُعكس العملية الأصلية لا عكسها');
    }

    public static function alreadyReversed(): self
    {
        return new self('هذه العملية معكوسة مسبقاً');
    }

    /**
     * مالٌ يدويّ مؤرَّخٌ قبل آخر نقطة عدٍّ للحساب — افتتاحه أو آخر جردٍ له.
     */
    public static function beforeCheckpoint(
        string $account,
        OperationType $checkpoint,
        string $at,
        string $field = 'occurred_at',
    ): self {
        $floor = $checkpoint === OperationType::Opening
            ? "رصيده الافتتاحي ({$at})"
            : "آخر جردٍ له ({$at}) — الجرد يشهد بما كان فيه يومها";

        return new self("لا تُسجَّل حركة يدوية على «{$account}» قبل {$floor}", $field);
    }

    public static function locked(string $until, string $field = 'occurred_at'): self
    {
        return new self("الحسابات مقفلة حتى {$until} — لا تُسجَّل عملية يدوية بتاريخٍ قبله", $field);
    }

    public static function sameAccount(): self
    {
        return new self('لا يُحوَّل من حساب إلى نفسه', 'to_account_id');
    }

    public static function reasonRequired(): self
    {
        return new self('السبب مطلوب عند السحب', 'notes');
    }

    public function fieldErrors(): array
    {
        return $this->field === null ? [] : [$this->field => [$this->getMessage()]];
    }
}
