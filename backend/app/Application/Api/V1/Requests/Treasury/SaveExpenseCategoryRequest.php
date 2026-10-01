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

    /**
     * المدخلاتُ بأنواعها: قاعدةُ `boolean` تقبل `0` و`"0"` و`false` معاً وتُبقي كلّاً كما جاء،
     * فيُصبّ هنا مرّةً على الحدّ — ولا يقارن الفعلُ بعدها قيمةً بغير نوعها.
     *
     * @return array{name?: string, requires_employee?: bool, is_active?: bool, sort_order?: int}
     */
    public function values(): array
    {
        $values = $this->validated();

        foreach (['requires_employee', 'is_active'] as $flag) {
            if (array_key_exists($flag, $values)) {
                $values[$flag] = (bool) $values[$flag];
            }
        }

        if (array_key_exists('sort_order', $values)) {
            $values['sort_order'] = (int) $values['sort_order'];
        }

        /**
         * @var array{
         *     name?: string,
         *     requires_employee?: bool,
         *     is_active?: bool,
         *     sort_order?: int
         * } $values
         */
        return $values;
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
