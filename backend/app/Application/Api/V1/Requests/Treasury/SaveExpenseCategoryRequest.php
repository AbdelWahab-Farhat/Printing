<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Treasury;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Both create and edit: the name is required on create and optional on edit.
 */
class SaveExpenseCategoryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => [$this->isMethod('post') ? 'required' : 'sometimes', 'string', 'max:100'],
            'requires_employee' => ['sometimes', 'boolean'],
            'is_active' => ['sometimes', 'boolean'],
            'sort_order' => ['sometimes', 'integer', 'min:0', 'max:65535'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'اسم التصنيف مطلوب',
            'name.max' => 'اسم التصنيف طويل جداً',
        ];
    }

    public function attributes(): array
    {
        return [
            'name' => 'اسم التصنيف',
            'requires_employee' => 'يتطلب موظفاً',
            'is_active' => 'مفعّل',
            'sort_order' => 'الترتيب',
        ];
    }
}
