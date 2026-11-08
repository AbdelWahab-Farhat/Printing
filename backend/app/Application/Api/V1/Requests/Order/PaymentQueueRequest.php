<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Order;

use App\Domain\Order\Enums\OrderPaymentType;
use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\Order\Queries\PaymentSettlementQueue;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * فلاترُ قائمتَي «مراجعة وتسوية الدفعات». الصلاحية على كل مسار؛ وما لا يخصّ إحدى القائمتين تتجاهله.
 */
class PaymentQueueRequest extends FormRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            /** قائمة التسوية وحدها: `pending` أو `settled`. */
            'state' => ['nullable', Rule::in([PaymentSettlementQueue::PENDING, PaymentSettlementQueue::SETTLED])],
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
            /** حيث نزل المال: النورس، «مصرف علي»… */
            'account_id' => ['nullable', 'integer'],
            /** الموظف الذي سجّل القيد. */
            'recorded_by' => ['nullable', 'integer'],
            /** قائمة المراجعة وحدها: `payment` أو `refund`. */
            'type' => ['nullable', Rule::in([OrderPaymentType::Payment->value, OrderPaymentType::Refund->value])],
            /** طريقة الدفع. */
            'method' => ['nullable', Rule::enum(PaymentMethod::class)],
            /** أقلّ مبلغ للقيد كاملاً. */
            'amount_min' => ['nullable', 'numeric', 'min:0'],
            /** أعلى مبلغ للقيد كاملاً. */
            'amount_max' => ['nullable', 'numeric', 'min:0', Rule::when($this->filled('amount_min'), ['gte:amount_min'])],
            /** «مسوّاة» وحدها: الحساب الذي سُوّيت إليه. */
            'to_account_id' => ['nullable', 'integer'],
            /** «مسوّاة» وحدها: الموظف الذي سوّاها. */
            'settled_by' => ['nullable', 'integer'],
            /** جزءٌ من رقم الطلبية أو من اسم الزبون. */
            'q' => ['nullable', 'string', 'max:100'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'amount_max.gte' => 'الحدّ الأعلى للمبلغ أقلّ من الحدّ الأدنى',
            'method.enum' => 'طريقة الدفع غير معروفة',
        ];
    }
}
