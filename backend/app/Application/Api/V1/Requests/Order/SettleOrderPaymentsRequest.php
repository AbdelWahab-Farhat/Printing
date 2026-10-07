<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Order;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * «تسوية دفعة» — one payment or several, and where their money went.
 *
 * The permission is on the route (`orders.payments.settle`). Whether each payment may be settled
 * — a refund, a reversed payment, an order already «تم التسوية» — is a fact about the row, and
 * the action refuses it under `payments.{i}.payment_id`.
 */
class SettleOrderPaymentsRequest extends FormRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            /** The payments to settle — all of them, or none. */
            'payments' => ['required', 'array', 'min:1', 'max:100'],
            'payments.*.payment_id' => [
                'required',
                'integer',
                'distinct',
                Rule::exists('order_payments', 'id')->whereNull('deleted_at'),
            ],
            /** What Nawris or the driver kept of this payment — only on money held in custody. */
            'payments.*.fee' => ['nullable', 'numeric', 'min:0', 'max:9999999.99'],
            /** Where they all went. Empty: each to its own automatic account. */
            'account_id' => ['nullable', 'integer'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'payments' => 'الدفعات',
            'payments.*.payment_id' => 'الدفعة',
            'payments.*.fee' => 'ما احتفظ به الناقل',
            'account_id' => 'الحساب',
        ];
    }

    /**
     * @return list<array{payment_id: int, fee: ?string}>
     */
    public function rows(): array
    {
        return array_values(array_map(fn (array $row): array => [
            'payment_id' => (int) $row['payment_id'],
            'fee' => isset($row['fee']) && $row['fee'] !== '' ? (string) $row['fee'] : null,
        ], $this->validated('payments')));
    }
}
