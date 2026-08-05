<?php

declare(strict_types=1);

namespace App\Domain\Order\DTOs;

use App\Domain\Order\Enums\TransitionFieldType;
use App\Domain\Order\Support\TransitionFields;

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
     */
    public static function number(
        string $key,
        string $label,
        bool $required = false,
        ?float $min = 0,
        ?float $max = null,
        ?string $hint = null,
    ): self {
        return new self(
            key: $key,
            type: TransitionFieldType::Number,
            label: $label,
            required: $required,
            hint: $hint,
            min: $min,
            max: $max,
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
        };
    }
}
