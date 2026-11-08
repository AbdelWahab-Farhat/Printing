<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Order;

use App\Domain\Identity\Enums\PermissionName;
use Illuminate\Foundation\Http\FormRequest;

/**
 * خياراتُ الفلتر لمن يراجع أو يسوّي: تكفي إحدى الصلاحيتين، لأنّ كليهما يرى الورقة نفسها.
 */
class PaymentFilterOptionsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->canAny([
            PermissionName::ReviewOrderPayments->value,
            PermissionName::SettleOrderPayments->value,
        ]) === true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [];
    }
}
