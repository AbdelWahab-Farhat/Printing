<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\InternalTicket;

use App\Domain\InternalTicket\Enums\InternalTicketStatus;
use App\Domain\InternalTicket\Queries\InternalTicketFilters;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * فلاترُ قائمة «الموظفين»، كقائمة بريمولا الداخلية.
 */
class ListInternalTicketsRequest extends FormRequest
{
    private const DEFAULT_PER_PAGE = 20;

    private const MAX_PER_PAGE = 50;

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
            // «تذاكري» أو «الكل». الثانيةُ للمدير وحده؛ لغيره تُقرأ «تذاكري» مهما أرسل.
            'scope' => ['nullable', Rule::in(['mine', 'all'])],
            'status' => ['nullable', Rule::enum(InternalTicketStatus::class)],
            // كودُ التذكرة، أو عنوانها، أو اسمُ أحد طرفيها.
            'search' => ['nullable', 'string', 'max:100'],
            'category_id' => ['nullable', 'integer'],
            // تذاكرُ موظفٍ بعينه، أيَّ طرفٍ كان.
            'user_id' => ['nullable', 'integer'],
            'unread' => ['nullable', 'boolean'],
            'order_id' => ['nullable', 'integer'],
            'customer_id' => ['nullable', 'integer'],
            'sort' => ['nullable', Rule::in([InternalTicketFilters::SORT_LATEST, InternalTicketFilters::SORT_OLDEST_ACTIVITY])],
            'per_page' => ['nullable', 'integer', 'min:1'],
        ];
    }

    public function filters(bool $mayReadAll): InternalTicketFilters
    {
        return InternalTicketFilters::fromArray($this->validated(), $mayReadAll);
    }

    /** طلبٌ لا يُعقل يُقصّ إلى الحدّ، لا يُرفض. */
    public function perPage(): int
    {
        return min(max((int) $this->integer('per_page', self::DEFAULT_PER_PAGE), 1), self::MAX_PER_PAGE);
    }
}
