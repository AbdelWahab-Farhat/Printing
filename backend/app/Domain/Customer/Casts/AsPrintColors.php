<?php

declare(strict_types=1);

namespace App\Domain\Customer\Casts;

use App\Domain\Customer\Support\PrintColors;
use Illuminate\Contracts\Database\Eloquent\CastsAttributes;
use Illuminate\Database\Eloquent\Model;

/**
 * A `print_colors` column — see {@see PrintColors}.
 *
 * A cast rather than `'array'` for two reasons. Every write is normalised on the way in, so the
 * four columns that hold this shape can never drift apart. And the history recognises the cast:
 * `AuditValueLabels` reads it to show «أحمر الشعار (PANTONE 186 C)» where it would otherwise have
 * nothing to say about an array.
 *
 * @implements CastsAttributes<list<array{name: string, code: string|null, hex: string|null}>|null, mixed>
 */
final class AsPrintColors implements CastsAttributes
{
    public function get(Model $model, string $key, mixed $value, array $attributes): ?array
    {
        if (! is_string($value) || $value === '') {
            return null;
        }

        return PrintColors::normalise(json_decode($value, true));
    }

    public function set(Model $model, string $key, mixed $value, array $attributes): ?string
    {
        $list = PrintColors::normalise($value);

        return $list === null ? null : json_encode($list, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);
    }
}
