<?php

declare(strict_types=1);

namespace App\Domain\Carrier\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * These orders cannot go out in one parcel.
 *
 * **A parcel has one door, one phone and one person who owes for it**, and Nawris reports it
 * delivered or returned as a whole — there is no partial delivery in their vocabulary. So the
 * orders in it must share a customer, a destination and a recipient phone, or a refusal at one
 * door would send another customer's goods back with it.
 *
 * Refused before any HTTP call, and for the whole group: sending the orders that do match and
 * leaving the rest would be a grouping nobody chose.
 */
final class OrdersCannotShareAParcel extends DomainException
{
    public static function tooFew(): self
    {
        return new self('الطرد المشترك يحتاج طلبيتين على الأقل');
    }

    public static function repeated(string $code): self
    {
        return new self("الطلبية {$code} مكررة في الطرد نفسه");
    }

    public static function differentCustomer(string $code): self
    {
        return new self("الطلبية {$code} لزبون آخر، والطرد المشترك لزبون واحد");
    }

    public static function differentDestination(string $code): self
    {
        return new self("الطلبية {$code} إلى مدينة أو منطقة أخرى، والطرد المشترك يذهب إلى عنوان واحد");
    }

    public static function differentPhone(string $code): self
    {
        return new self("الطلبية {$code} برقم مستلم آخر، والطرد المشترك يُسلَّم لرقم واحد");
    }
}
