<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\User;

use Illuminate\Foundation\Http\FormRequest;

/**
 * «راتب تلقائي» — whether the monthly run posts this employee's salary. EMPLOYEE-WALLET-DESIGN §١٤.
 *
 * Behind `users.salary`, like the salary itself.
 */
class SetUserAutoSalaryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function rules(): array
    {
        return [
            'auto_salary' => ['required', 'boolean'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return ['auto_salary' => 'راتب تلقائي'];
    }
}
