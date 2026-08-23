<?php

declare(strict_types=1);

namespace App\Domain\Order\DTOs;

use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\Order\Enums\TransitionFieldType;
use App\Domain\Order\Support\TransitionFields;
use Illuminate\Validation\Rule;

/**
 * One thing a status change asks the person making it for.
 *
 * **The description and the validation are the same object.** {@see toArray()} is what the app
 * draws and {@see rules()} is what the request accepts, both read off these properties — so a
 * form cannot offer a field the endpoint would reject, and a field cannot quietly stop being
 * required on one side only.
 *
 * Built by {@see TransitionFields}, which knows *which* fields a
 * particular order owes for a particular move. This class knows nothing about orders.
 */
final class TransitionField
{
    private function __construct(
        public readonly string $key,
        public readonly TransitionFieldType $type,
        public readonly string $label,
        public readonly bool $required,
        public readonly bool $multiple = false,
        public readonly bool $multiline = false,
        public readonly ?string $hint = null,
        public readonly ?float $min = null,
        public readonly ?float $max = null,
        public readonly ?string $value = null,
        /**
         * The choices, for the one type that carries its own — see
         * {@see TransitionFieldType::PaymentMethod}.
         *
         * @var list<array{value: string, label: string}>
         */
        public readonly array $options = [],
        /**
         * The field this one becomes required by: empty is fine on its own, and refused the
         * moment [$requiredWith] is answered.
         *
         * **A rule with no home anywhere else.** «طريقة الدفع» is meaningless without an amount
         * and mandatory with one — the ledger will not take an entry lacking it — and neither
         * `required` nor `nullable` can say that. Written here rather than in the FormRequest so
         * the app can hold the same rule off the same description.
         */
        public readonly ?string $requiredWith = null,
    ) {}

    public static function text(
        string $key,
        string $label,
        bool $required = false,
        bool $multiline = false,
        ?string $hint = null,
    ): self {
        return new self(
            key: $key,
            type: TransitionFieldType::Text,
            label: $label,
            required: $required,
            multiline: $multiline,
            hint: $hint,
        );
    }

    /**
     * A quantity, with the bounds this particular order puts on it.
     *
     * [$max] is a fact about the order rather than a rule — what was ordered of one size — so
     * it travels with the field and is enforced from the same place it is drawn.
     *
     * [$value] is what the box opens holding. **An answer, not a placeholder:** the field that
     * asks what arrived of a shortage opens filled with the whole of it, because that is what
     * leaving «نواقص» nearly always means, and a clerk who agrees taps once. Left null by every
     * field with no obvious answer — an empty box that suggests nothing is honest, one that
     * suggests a wrong number is not.
     */
    public static function number(
        string $key,
        string $label,
        bool $required = false,
        ?float $min = 0,
        ?float $max = null,
        ?string $hint = null,
        ?string $value = null,
    ): self {
        return new self(
            key: $key,
            type: TransitionFieldType::Number,
            label: $label,
            required: $required,
            hint: $hint,
            min: $min,
            max: $max,
            value: $value,
        );
    }

    /**
     * How the money just taken was handed over.
     *
     * **The choices are passed in rather than read off `PaymentMethod`**, because the list is
     * narrower here than the business's: a method obliging a receipt cannot be offered on a
     * screen that uploads no files. {@see TransitionFields} decides which survive, and both the
     * picker and the rule below are built from what it decided — so the two cannot disagree.
     *
     * @param  list<PaymentMethod>  $methods
     */
    public static function paymentMethod(
        string $key,
        string $label,
        array $methods,
        ?string $requiredWith = null,
        ?string $hint = null,
        ?string $value = null,
    ): self {
        return new self(
            key: $key,
            type: TransitionFieldType::PaymentMethod,
            label: $label,
            required: false,
            hint: $hint,
            value: $value,
            options: array_values(array_map(
                fn (PaymentMethod $method) => [
                    'value' => $method->value,
                    'label' => $method->label(),
                ],
                $methods,
            )),
            requiredWith: $requiredWith,
        );
    }

    public static function customerDesigns(
        string $key,
        string $label,
        bool $required = false,
        ?string $hint = null,
    ): self {
        return new self(
            key: $key,
            type: TransitionFieldType::CustomerDesigns,
            label: $label,
            required: $required,
            multiple: true,
            hint: $hint,
        );
    }

    /**
     * One of the carriers the business deals with.
     *
     * No options travel with it — see {@see TransitionFieldType::ShippingCompany}.
     */
    public static function shippingCompany(
        string $key,
        string $label,
        bool $required = false,
        ?string $hint = null,
    ): self {
        return new self(
            key: $key,
            type: TransitionFieldType::ShippingCompany,
            label: $label,
            required: $required,
            hint: $hint,
        );
    }

    /**
     * A warehouse, chosen from the ones the business maintains.
     *
     * No options travel with it — see {@see TransitionFieldType::Warehouse}.
     */
    public static function warehouse(
        string $key,
        string $label,
        bool $required = false,
        ?string $hint = null,
    ): self {
        return new self(
            key: $key,
            type: TransitionFieldType::Warehouse,
            label: $label,
            required: $required,
            hint: $hint,
        );
    }

    /**
     * What the app renders.
     *
     * Every key is always present, `null` included: a client that has to distinguish "absent"
     * from "false" is a client written against one server's mood.
     *
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'key' => $this->key,
            'type' => $this->type->value,
            'label' => $this->label,
            'required' => $this->required,
            'multiple' => $this->multiple,
            'multiline' => $this->multiline,
            'hint' => $this->hint,
            'min' => $this->min,
            'max' => $this->max,
            // What the box opens holding, and null for almost every field. An app too old to
            // know the key simply opens empty, which is what it did before the key existed.
            'value' => $this->value,
            // Empty for every type that fetches its own list. An app that reads it blindly draws
            // no picker for those, which is exactly what it drew before the key existed.
            'options' => $this->options,
            // The key that makes this one mandatory, or null. Sent so the app can grey its own
            // button on the same rule the endpoint enforces, rather than keeping a second copy.
            'required_with' => $this->requiredWith,
        ];
    }

    /**
     * What the request accepts, keyed for the `fields` bag.
     *
     * Ownership is deliberately *not* checked here: a design belonging to another customer is
     * refused by the domain when it is attached, in the same transaction as the move, so there
     * is one answer to that question rather than two that can disagree.
     *
     * @return array<string, array<int, string>>
     */
    public function rules(): array
    {
        $presence = $this->required ? 'required' : 'nullable';

        // Not merged into [$presence]: `nullable` says "an empty answer passes the rules below",
        // and `required_with` is an *implicit* rule Laravel runs whether or not the value came —
        // which is the whole point. The two say different things and both have to be said.
        $conditional = $this->requiredWith === null ? [] : ["required_with:fields.{$this->requiredWith}"];

        return match ($this->type) {
            TransitionFieldType::Text => [
                "fields.{$this->key}" => [$presence, 'string', 'max:1000'],
            ],
            TransitionFieldType::Number => [
                "fields.{$this->key}" => array_values(array_filter([
                    $presence,
                    'numeric',
                    $this->min === null ? null : "min:{$this->min}",
                    $this->max === null ? null : "max:{$this->max}",
                ])),
            ],
            TransitionFieldType::CustomerDesigns => [
                "fields.{$this->key}" => [$presence, 'array', ...($this->required ? ['min:1'] : [])],
                "fields.{$this->key}.*" => ['integer'],
            ],
            // Exactly the list the picker was handed, so a method left off the screen is a
            // method the endpoint has never heard of either.
            TransitionFieldType::PaymentMethod => [
                "fields.{$this->key}" => [
                    $presence,
                    ...$conditional,
                    'string',
                    Rule::in(array_column($this->options, 'value')),
                ],
            ],

            // withoutTrashed: a carrier removed from the list may not be chosen for a new
            // dispatch, which is the same answer the picker gives.
            TransitionFieldType::ShippingCompany => [
                "fields.{$this->key}" => [
                    $presence,
                    'integer',
                    Rule::exists('shipping_companies', 'id')->withoutTrashed(),
                ],
            ],

            // whereNull('deleted_at'), the same exists-rule purchase orders already use for a
            // warehouse: a deleted one may not be chosen for a new deduction.
            TransitionFieldType::Warehouse => [
                "fields.{$this->key}" => [
                    $presence,
                    'integer',
                    Rule::exists('warehouses', 'id')->whereNull('deleted_at'),
                ],
            ],
        };
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return match ($this->type) {
            TransitionFieldType::CustomerDesigns => [
                "fields.{$this->key}.required" => "{$this->label} مطلوبة",
                "fields.{$this->key}.min" => "{$this->label} مطلوبة",
            ],
            TransitionFieldType::Text => [
                "fields.{$this->key}.required" => "{$this->label} مطلوب",
            ],
            TransitionFieldType::Number => [
                "fields.{$this->key}.required" => "{$this->label} مطلوب",
                "fields.{$this->key}.numeric" => "{$this->label} يجب أن يكون رقماً",
                "fields.{$this->key}.max" => "{$this->label} أكبر مما في الطلبية",
            ],
            TransitionFieldType::PaymentMethod => [
                "fields.{$this->key}.required" => "{$this->label} مطلوبة",
                "fields.{$this->key}.required_with" => "{$this->label} مطلوبة مع المبلغ",
                "fields.{$this->key}.in" => "{$this->label} غير متاحة في تغيير الحالة",
            ],
            TransitionFieldType::ShippingCompany => [
                "fields.{$this->key}.required" => "{$this->label} مطلوبة",
                "fields.{$this->key}.exists" => 'شركة التوصيل المختارة غير موجودة',
            ],
            TransitionFieldType::Warehouse => [
                "fields.{$this->key}.required" => "{$this->label} مطلوب",
                "fields.{$this->key}.exists" => 'المخزن المختار غير موجود',
            ],
        };
    }
}
