<?php

declare(strict_types=1);

namespace App\Domain\Customer\Support;

/**
 * «ألوان الطباعة» — the inks a design is printed in, as a list of `{name, code, hex}`.
 *
 * - **name** is required: «أحمر الشعار» is how two people on the floor talk about it.
 * - **code** is the authority: `PANTONE 186 C`, a CMYK mix — what the press matches.
 * - **hex** is a swatch for the screen and nothing more. Phones disagree about colour, so a
 *   swatch is a way to tell two entries apart at a glance, never the shade to print.
 *
 * One shape for four columns — the design, its copy on an order, the ticket's brief and a
 * designer's version — so every one of them is written through {@see normalise()} and read back
 * identical. That is what lets a copy be compared with its source by `===`.
 */
final class PrintColors
{
    /** More than this is a photograph, not a spot-colour job. */
    public const MAX = 12;

    public const NAME_MAX = 60;

    public const CODE_MAX = 60;

    /** `#RRGGBB`, the only form the app's picker writes. */
    public const HEX_PATTERN = '/^#[0-9A-Fa-f]{6}$/';

    /**
     * The stored form of whatever arrived — already validated, or read back out of the column.
     *
     * Blanks become null and the swatch is upper-cased, so `#e4002b` and `#E4002B` are one
     * value. An entry with no name is dropped rather than refused: validation has already
     * refused it on the way in, and a row read back from the database must not fail to load.
     * **An empty list is null**, so «no colors» has exactly one representation.
     *
     * @return list<array{name: string, code: string|null, hex: string|null}>|null
     */
    public static function normalise(mixed $colors): ?array
    {
        if (! is_array($colors)) {
            return null;
        }

        $list = [];

        foreach ($colors as $color) {
            if (! is_array($color)) {
                continue;
            }

            $name = self::textOrNull($color['name'] ?? null);

            if ($name === null) {
                continue;
            }

            $hex = self::textOrNull($color['hex'] ?? null);

            $list[] = [
                'name' => $name,
                'code' => self::textOrNull($color['code'] ?? null),
                'hex' => $hex !== null && preg_match(self::HEX_PATTERN, $hex) === 1
                    ? strtoupper($hex)
                    : null,
            ];
        }

        return $list === [] ? null : $list;
    }

    /**
     * The same list with every code taken off — what a customer is allowed to say.
     *
     * The customer chooses the name and the swatch; the code is staff's. Applied in the domain
     * rather than trusted to validation, so no request shape can carry one through.
     *
     * @return list<array{name: string, code: null, hex: string|null}>|null
     */
    public static function withoutCodes(mixed $colors): ?array
    {
        $list = self::normalise($colors);

        if ($list === null) {
            return null;
        }

        // Spelled out rather than `['code' => null] + $color`: the key order is part of the shape,
        // and a copy is compared with its source by `===`.
        return array_map(
            fn (array $color): array => ['name' => $color['name'], 'code' => null, 'hex' => $color['hex']],
            $list,
        );
    }

    /**
     * One line a person reads — «أحمر الشعار (PANTONE 186 C)، أسود النص».
     *
     * What the history shows for a change to the list, where the raw JSON would otherwise be.
     *
     * @param  array<int, mixed>|null  $colors
     */
    public static function describe(?array $colors): ?string
    {
        $list = self::normalise($colors);

        if ($list === null) {
            return null;
        }

        return implode('، ', array_map(
            fn (array $color): string => $color['code'] === null
                ? $color['name']
                : "{$color['name']} ({$color['code']})",
            $list,
        ));
    }

    /**
     * Whether a list says what the press needs: at least one colour, and every colour carries its
     * swatch or its press code. A name alone («أزرق») is how the wrong shade got printed, so it
     * does not count. See PRINT-COLORS.md §9.
     *
     * @param  array<int, mixed>|null  $colors
     */
    public static function isComplete(?array $colors): bool
    {
        $list = self::normalise($colors);

        if ($list === null) {
            return false;
        }

        foreach ($list as $color) {
            if ($color['hex'] === null && $color['code'] === null) {
                return false;
            }
        }

        return true;
    }

    private static function textOrNull(mixed $value): ?string
    {
        if (! is_string($value) && ! is_numeric($value)) {
            return null;
        }

        $text = trim((string) $value);

        return $text !== '' ? $text : null;
    }
}
