<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Treasury\Models\ExpenseCategory;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin ExpenseCategory
 */
class ExpenseCategoryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'code' => $this->code,
            'is_system' => $this->isSystem(),
            'requires_employee' => (bool) $this->requires_employee,
            'is_active' => (bool) $this->is_active,
            'sort_order' => (int) $this->sort_order,
        ];
    }
}
