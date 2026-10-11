<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\PurchaseOrder;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

/**
 * Receiving a shipment against a purchase order.
 *
 * Deliberately the same shape as `StoreStockArrivalRequest`'s items, minus `vendor_id` and
 * `warehouse_id` — both are already fixed by the order itself, so re-sending them would only
 * invite a payload that disagrees with the order it names.
 *
 * Whether *this* order may currently receive anything, and whether the line was ordered at all,
 * are domain questions — see `PurchaseOrderNotReceivable` and `StockItemNotOnPurchaseOrder` —
 * because both depend on state this request cannot see without reading the database twice. A
 * quantity larger than what remains on order is *not* one of them: a supplier who overships is
 * booked in whole, surplus included.
 */
class ReceivePurchaseOrderArrivalRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            // The vendor's own document number. Optional: some shipments arrive without one.
            'invoice_number' => ['nullable', 'string', 'max:100'],

            'notes' => ['nullable', 'string', 'max:1000'],

            'items' => ['required', 'array', 'min:1'],

            'items.*.stock_item_id' => [
                'required', 'integer', 'distinct',
                Rule::exists('stock_items', 'id')->whereNull('deleted_at'),
            ],

            // `gt:0`, not `min:0` — a line of nothing is not a delivery, the same rule
            // StoreStockArrivalRequest holds. Whole numbers are enforced separately, per
            // product, when the line is posted to the ledger.
            'items.*.quantity' => ['required', 'numeric', 'gt:0', 'max:999999999.999'],

            // What was paid on the lorry's arrival — delivery, porters, customs — spread over
            // what this shipment brought (PURCHASE-ORDER-ARRIVAL-COSTS.md). `gt:0`: a cost of
            // nothing paid on arrival is not one. Who was paid as on the order form: absent is the
            // vendor's bill, else a drawer or a manual «التزام».
            'additional_costs' => ['nullable', 'array', 'max:20'],
            'additional_costs.*.name' => ['required', 'string', 'max:255'],
            'additional_costs.*.amount' => ['required', 'numeric', 'gt:0', 'max:999999999999.99'],
            'additional_costs.*.treasury_account_id' => [
                'nullable', 'integer',
                Rule::exists('treasury_accounts', 'id')->whereNull('deleted_at'),
            ],
        ];
    }

    /**
     * Charging a cost to an account is spending from it — {@see CostAccountGrant}. The
     * storekeeper who receives may lack that grant, and then names no account.
     *
     * @return array<int, callable>
     */
    public function after(): array
    {
        return [
            fn (Validator $validator) => CostAccountGrant::check(
                $validator,
                $this->user(),
                $this->input('additional_costs'),
            ),
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'invoice_number.max' => 'رقم الفاتورة طويل جداً',
            'notes.max' => 'الملاحظات طويلة جداً',
            'items.required' => 'يجب إضافة بند واحد على الأقل',
            'items.min' => 'يجب إضافة بند واحد على الأقل',
            'items.*.stock_item_id.required' => 'المادة مطلوبة',
            'items.*.stock_item_id.exists' => 'المادة المحددة غير موجودة',
            'items.*.stock_item_id.distinct' => 'لا يمكن تكرار نفس المادة أكثر من مرة في الشحنة',
            'items.*.quantity.required' => 'الكمية مطلوبة',
            'items.*.quantity.numeric' => 'الكمية يجب أن تكون رقماً',
            'items.*.quantity.gt' => 'الكمية يجب أن تكون أكبر من صفر',
            'items.*.quantity.max' => 'الكمية أكبر من الحد المسموح',
            'additional_costs.max' => 'عدد التكاليف أكبر من المسموح',
            'additional_costs.*.name.required' => 'اسم التكلفة مطلوب',
            'additional_costs.*.name.max' => 'اسم التكلفة طويل جداً',
            'additional_costs.*.amount.required' => 'قيمة التكلفة مطلوبة',
            'additional_costs.*.amount.numeric' => 'قيمة التكلفة يجب أن تكون رقماً',
            'additional_costs.*.amount.gt' => 'قيمة التكلفة يجب أن تكون أكبر من صفر',
            'additional_costs.*.amount.max' => 'قيمة التكلفة أكبر من الحد المسموح',
            'additional_costs.*.treasury_account_id.exists' => 'الحساب المحدد غير موجود',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'invoice_number' => 'رقم الفاتورة',
            'notes' => 'الملاحظات',
            'items' => 'البنود',
            'items.*.stock_item_id' => 'المادة',
            'items.*.quantity' => 'الكمية',
            'additional_costs' => 'تكاليف الوصول',
            'additional_costs.*.name' => 'اسم التكلفة',
            'additional_costs.*.amount' => 'قيمة التكلفة',
            'additional_costs.*.treasury_account_id' => 'الحساب الذي دُفعت منه',
        ];
    }
}
