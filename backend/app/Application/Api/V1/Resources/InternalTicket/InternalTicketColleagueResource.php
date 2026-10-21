<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources\InternalTicket;

use App\Domain\Identity\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * زميلٌ في ورقة «مع مَن؟»: اسمُه ودورُه، وكم تذكرةً مفتوحةً بيني وبينه.
 *
 * @mixin User
 */
class InternalTicketColleagueResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'employee_code' => $this->employee_code,
            'roles' => $this->roles->pluck('name')->values()->all(),
            'open_tickets_with_me' => (int) $this->getAttribute('open_tickets_with_me'),
        ];
    }
}
