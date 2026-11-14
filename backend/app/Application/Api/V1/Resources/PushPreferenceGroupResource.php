<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Notification\DTOs\PushPreferenceGroup;
use App\Domain\Notification\DTOs\PushSwitch;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One notification type on an employee's push settings, with its switches.
 *
 * A type that is one switch has a single entry in `switches` whose `scope` is `""`. The app
 * draws that as one row, and a type with several — `order.status` — as a heading with a row per
 * status.
 *
 * @mixin PushPreferenceGroup
 */
class PushPreferenceGroupResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'type' => $this->type->value,
            'label' => $this->type->label(),
            'icon' => $this->type->icon(),
            'switches' => array_map(fn (PushSwitch $switch) => [
                'scope' => $switch->scope,
                'label' => $switch->label,
                'push' => $switch->push,
            ], $this->switches),
        ];
    }
}
