<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Investor;

use App\Domain\Investor\Queries\InvestorProfitSources;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Which of the three profit gates to open — a readable 422 rather than an empty sheet read as
 * «no orders behind this number».
 */
class InvestorProfitSourcesRequest extends FormRequest
{
    /** Access is declared on the route; there is nothing extra to decide here. */
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
            // awaiting_delivery · pending · available — the gates on his profit card, in order.
            'gate' => ['required', 'string', Rule::in(InvestorProfitSources::GATES)],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'gate.required' => 'حدد بوابة الربح',
            'gate.in' => 'بوابة الربح غير صحيحة',
        ];
    }

    public function gate(): string
    {
        return (string) $this->validated('gate');
    }
}
