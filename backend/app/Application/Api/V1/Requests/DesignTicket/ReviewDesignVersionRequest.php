<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\DesignTicket;

use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ReviewDesignVersionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Two verdicts, and «بانتظار المراجعة» is not one of them.
     *
     * `DesignSubmissionStatus::verdicts()` rather than `values()`: `proposed` is where a version
     * arrives, never somewhere a person sends one, and offering it would let a reviewer put a
     * version back into a state it was already in while stamping their name on the review.
     *
     * **`note` is `required_if` rather than merely validated in the action.** The action refuses
     * it too — a console caller has no FormRequest — but a 422 with the message under the textarea
     * is what the reviewer actually needs, rather than a domain error in a toast.
     *
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'verdict' => [
                'required',
                'string',
                Rule::in(array_map(
                    fn (DesignSubmissionStatus $status) => $status->value,
                    DesignSubmissionStatus::verdicts(),
                )),
            ],
            'note' => [
                'required_if:verdict,'.DesignSubmissionStatus::ChangesRequested->value,
                'nullable',
                'string',
                'min:3',
                'max:2000',
            ],
        ];
    }

    /**
     * The verdict as the enum, so the controller never re-parses a string the rules already
     * proved.
     */
    public function verdict(): DesignSubmissionStatus
    {
        return DesignSubmissionStatus::from((string) $this->validated('verdict'));
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'verdict.required' => 'حدّد الموافقة أو طلب التعديل',
            'verdict.in' => 'قيمة غير صالحة',
            'note.required_if' => 'اكتب ما المطلوب تعديله',
            'note.min' => 'الملاحظة قصيرة جداً',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'verdict' => 'القرار',
            'note' => 'الملاحظة',
        ];
    }
}
