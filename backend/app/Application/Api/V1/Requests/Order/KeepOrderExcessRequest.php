<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Order;

use Illuminate\Foundation\Http\FormRequest;

/**
 * «اعتبار الزائد إيراداً». No amount: the whole excess the order holds is kept, and whoever wants
 * to hand part of it back refunds that first. The permission is on the route.
 */
class KeepOrderExcessRequest extends FormRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            /** Why it stays — «الزبون لم يطلب الباقي», for whoever reads the ledger later. */
            'notes' => ['nullable', 'string', 'max:1000'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'notes.max' => 'الملاحظات طويلة جداً',
        ];
    }
}
