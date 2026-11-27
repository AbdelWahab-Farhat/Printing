<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * Every reason an instant sale is refused (INSTANT-ORDERS-PLAN.md), each with the sentence the
 * counter employee reads and the field it belongs to.
 *
 * One class rather than a dozen: they are all the same kind of answer — «this sale cannot go
 * ahead, and here is why» — and none is caught on its own anywhere.
 */
final class InstantOrderRefused extends DomainException
{
    /**
     * @param  array<string, list<string>>  $errors
     */
    private function __construct(string $message, private readonly array $errors)
    {
        parent::__construct($message);
    }

    /**
     * @param  list<string>|null  $lines
     */
    private static function on(string $field, string $message, ?array $lines = null): self
    {
        return new self($message, [$field => $lines ?? [$message]]);
    }

    public static function notABranch(): self
    {
        return self::on('branch_id', 'مكان الاستلام يجب أن يكون مكتب استلام');
    }

    public static function branchInactive(string $branch): self
    {
        return self::on('branch_id', "الفرع «{$branch}» غير نشط ولا يقبل طلبات جديدة");
    }

    public static function notYourBranch(string $branch): self
    {
        return self::on('branch_id', "لست مصرحاً بالعمل في «{$branch}»");
    }

    public static function branchHasNoWarehouse(string $branch): self
    {
        return self::on('branch_id', "لم يُحدَّد مخزن افتراضي لـ«{$branch}» — راجع إعدادات الفروع");
    }

    public static function branchHasNoAccount(string $branch, string $method): self
    {
        return self::on('fields.payment_method', "لم يُحدَّد حساب {$method} لـ«{$branch}» — راجع إعدادات الفروع");
    }

    public static function productNotEligible(int $index, string $product, string $reason): self
    {
        return self::on("items.{$index}.product_id", "«{$product}» {$reason}");
    }

    /**
     * @param  list<string>  $lines  one sentence per short product, in the form the plan gives:
     *                               «أكياس شحن 35×40 — مخزن بريمولا: المطلوب 10 كجم، المتاح 7 كجم»
     */
    public static function shortfall(array $lines): self
    {
        return self::on(
            'items',
            count($lines) === 1 ? 'الكمية غير متوفرة: '.$lines[0] : 'الكميات غير متوفرة لبعض المنتجات',
            $lines,
        );
    }

    public static function customerInactive(string $name): self
    {
        return self::on('customer.phone', "العميل «{$name}» معطَّل ولا تُسجَّل له طلبات");
    }

    public static function needsFullPayment(string $remaining): self
    {
        return self::on('fields.payment_amount', "الطلب الفوري يُسلَّم بعد قبض كامل المبلغ — المتبقي {$remaining} د.ل");
    }

    public static function moreThanOrdered(string $product): self
    {
        return self::on('fields', "لا يُسلَّم من «{$product}» أكثر من الكمية المطلوبة");
    }

    public static function accountChoiceNeedsPermission(): self
    {
        return self::on('fields.payment_account_id', 'لا تملك صلاحية اختيار حساب غير حساب الفرع');
    }

    public static function notEditable(): self
    {
        return self::on('status', 'الطلب الفوري يُعدَّل وهو «جديدة» فقط');
    }

    public static function notInstant(): self
    {
        return self::on('order', 'هذه ليست طلبية فورية');
    }

    public static function editedThroughItsOwnForm(): self
    {
        return self::on('order', 'الطلب الفوري يُعدَّل من شاشة الطلب الفوري');
    }

    /**
     * @return array<string, list<string>>
     */
    public function fieldErrors(): array
    {
        return $this->errors;
    }
}
