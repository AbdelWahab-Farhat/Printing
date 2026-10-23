<?php

declare(strict_types=1);

namespace App\Domain\Customer\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * مُعرِّفُ رابطٍ أُرسل لعميلٍ لا يملكه.
 *
 * عبر HTTP يردّه الـFormRequest قبل أن يصل إلى هنا، فهذا حارسُ كلّ مستدعٍ آخر — كما
 * {@see ShopDoesNotBelongToCustomer} للمحلات. بدونه كانت المزامنة ستُنشئ رابطاً مكرّراً بصمت.
 */
final class SocialLinkDoesNotBelongToCustomer extends DomainException
{
    public static function make(int $linkId, int $customerId): self
    {
        return new self("الرابط رقم {$linkId} لا ينتمي للعميل رقم {$customerId}");
    }
}
