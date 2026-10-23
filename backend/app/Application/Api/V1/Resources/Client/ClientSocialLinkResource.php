<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources\Client;

use App\Application\Api\V1\Resources\CustomerSocialLinkResource;
use App\Domain\Customer\Models\CustomerSocialLink;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * رابطُ تواصلٍ من روابط العميل، كما ترسمه شاشة «روابط التواصل».
 *
 * الحقلان نفسهما اللذان يراهما الموظف في {@see CustomerSocialLinkResource}، ولا يُورَث منه للسبب
 * الذي لا يرث لأجله أيُّ موردٍ للعميل توأمَه: ما يراه العميل تقرّره هذه القائمة لا ما يُضاف هناك.
 *
 * @mixin CustomerSocialLink
 */
class ClientSocialLinkResource extends JsonResource
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
