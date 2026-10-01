<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * An edit to an account that would leave some money path with nowhere to land.
 */
final class AccountChangeRefused extends DomainException
{
    public function __construct(string $message, private readonly string $field)
    {
        parent::__construct($message);
    }

    public static function defaultCannotBeSwitchedOff(string $account): self
    {
        return new self("«{$account}» هو الحساب الافتراضي لنوعه — عيّن غيره افتراضياً أولاً", 'is_active');
    }

    public static function defaultCannotBeUnset(string $account): self
    {
        return new self("لا بد لكل نوع من حساب افتراضي — عيّن حساباً آخر افتراضياً بدل «{$account}»", 'is_default');
    }

    /** طلبٌ واحد يجعله افتراضياً ويعطّله — والافتراضيُّ لا يكون معطَّلاً أبداً. */
    public static function defaultAndOffAtOnce(string $account): self
    {
        return new self(
            "لا يُجعل «{$account}» افتراضياً ويُعطَّل في الطلب نفسه — الافتراضي يبقى مفعّلاً",
            'is_active',
        );
    }

    /**
     * المعطَّلُ لا يظهر في منتقٍ ولا يستقبل حركة يدوية، فمالٌ فيه يصير مالاً لا يصله أحد. بلا رقم:
     * من يدير الحسابات قد لا يرى أرصدتها.
     */
    public static function stillHoldsMoney(string $account): self
    {
        return new self(
            "لا يُعطَّل «{$account}» ورصيده ليس صفراً — انقل ما فيه أو اضبطه بـ«جرد الحساب» أولاً",
            'is_active',
        );
    }

    public static function systemCannotBeSwitchedOff(string $account): self
    {
        return new self("«{$account}» حساب يعتمد عليه النظام ولا يُعطَّل", 'is_active');
    }

    public static function custodyCannotBeDefault(): self
    {
        return new self('حساب العهدة لا يكون افتراضياً — المال لا يُفترض أن ينتهي فيه', 'is_default');
    }

    public static function payableCannotBeDefault(): self
    {
        return new self('حساب الالتزام لا يكون افتراضياً — لا مال ينزل فيه', 'is_default');
    }

    public static function vendorPayableIsManagedByTheVendor(string $account): self
    {
        return new self("«{$account}» حساب مورد — يتبع المورد في اسمه وحالته", 'name');
    }

    public static function onlyCustodySettles(): self
    {
        return new self('«تُسوّى إلى» لحسابات العهدة وحدها', 'settles_into_account_id');
    }

    public static function cannotSettleInto(string $account): self
    {
        return new self("لا تُسوّى العهدة إلى «{$account}» — يلزم حساب مفعّل غير عهدة", 'settles_into_account_id');
    }

    public static function onlyCashServesAnOffice(): self
    {
        return new self('خزنة مكتب الاستلام تكون حساباً نقدياً', 'pickup_city_id');
    }

    public static function cannotCollectInto(string $account, string $kind, string $field): self
    {
        return new self("لا يُجمع «{$kind}» في «{$account}» — يلزم حساب مفعّل من النوع نفسه", $field);
    }

    public function fieldErrors(): array
    {
        return [$this->field => [$this->getMessage()]];
    }
}
