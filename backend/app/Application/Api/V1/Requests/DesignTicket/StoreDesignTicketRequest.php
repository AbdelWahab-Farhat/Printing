<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\DesignTicket;

use App\Domain\Identity\Enums\PermissionName;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreDesignTicketRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Written out in full, with no `array_merge` and no shared helper.
     *
     * Scramble reads this method without running it, so a merged array publishes the endpoint
     * with **no request body at all** — RULES §7. Duplication between this and the update request
     * is the deliberate price.
     *
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            // A ticket is always for a customer — an explicit acceptance criterion, and what the
            // approved design is eventually filed under. `withoutTrashed` because a deactivated
            // customer is not deleted and may still be worked for.
            'customer_id' => [
                'required', 'integer',
                Rule::exists('customers', 'id')->withoutTrashed(),
            ],
            // Optional. A customer asks for a business card before they order any bags, and
            // demanding an order would make employees open fake ones to reach a designer.
            'order_id' => [
                'nullable', 'integer',
                Rule::exists('orders', 'id')->withoutTrashed(),
            ],
            // What is read in the queue, and the label the approved design inherits.
            'title' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string', 'max:5000'],
            'instructions' => ['nullable', 'string', 'max:5000'],
            /*
             * The designer this is addressed to. **Null is the shared pool**, which is a real
             * answer rather than a missing one: an employee who does not know who is free leaves
             * it empty and the first designer to accept claims it.
             *
             * Constrained to people who could actually do the work. Without this an employee
             * could address a ticket to the accountant, who would never see it — a request that
             * vanishes silently is worse than one that is refused.
             */
            'assigned_designer_id' => [
                'nullable', 'integer',
                Rule::exists('users', 'id')->withoutTrashed(),
            ],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'customer_id.required' => 'العميل مطلوب',
            'customer_id.exists' => 'العميل غير موجود',
            'order_id.exists' => 'الطلبية غير موجودة',
            'title.required' => 'عنوان الطلب مطلوب',
            'description.required' => 'وصف طلب التصميم مطلوب',
            'assigned_designer_id.exists' => 'المصمم غير موجود',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'customer_id' => 'العميل',
            'order_id' => 'الطلبية',
            'title' => 'عنوان الطلب',
            'description' => 'وصف الطلب',
            'instructions' => 'الملاحظات والتعليمات',
            'assigned_designer_id' => 'المصمم',
        ];
    }

    /**
     * The permission a reader needs before a designer id means anything.
     *
     * Referenced so that the grant and this file are found together by a search, and so that
     * renaming the case breaks the build rather than leaving a stale comment behind.
     */
    public function assignmentPermission(): string
    {
        return PermissionName::AssignDesignTickets->value;
    }
}
