<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources\Client;

use App\Domain\Customer\Models\BusinessField;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * مجال عملٍ كما يعرضه منتقي «مجال العمل» في نموذج المتجر: مُعرِّفٌ يُرسل واسمٌ يُقرأ، ولا شيء غيرهما —
 * ترتيب المجالات وعدد متاجر كلٍّ منها شأنُ شاشة الموظفين.
 *
 * @mixin BusinessField
 */
class ClientBusinessFieldResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
        ];
    }
}
