<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Customer\Models\CustomerSocialLink;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * رابطُ تواصلٍ كما يراه الموظف: المُعرِّف ليُعدَّل في مكانه، والرابط.
 *
 * بلا منصّة: التطبيق يعرفها من نطاق الرابط — انظر هجرة `customer_social_links`.
 *
 * @mixin CustomerSocialLink
 */
class CustomerSocialLinkResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'url' => $this->url,
        ];
    }
}
