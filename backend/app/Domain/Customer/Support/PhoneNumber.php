<?php

declare(strict_types=1);

namespace App\Domain\Customer\Support;

/**
 * One spelling for a Libyan phone number, so «٠٩١ ٢٣٤ ٥٦٧٨», «+218912345678» and «0912345678»
 * find the same customer (INSTANT-ORDERS-PLAN.md §3).
 *
 * The stored form is the one the customer form already enforces: digits only, the local
 * «0…» prefix. Normalising never guesses beyond the country code — a number that is not Libyan
 * keeps its digits as they are.
 */
final class PhoneNumber
{
    private const ARABIC_DIGITS = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩', '۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

    private const LATIN_DIGITS = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    public static function normalise(string $typed): string
    {
        $digits = preg_replace('/\D+/', '', str_replace(self::ARABIC_DIGITS, self::LATIN_DIGITS, $typed)) ?? '';

        if (str_starts_with($digits, '00218')) {
            return '0'.substr($digits, 5);
        }

        if (str_starts_with($digits, '218') && strlen($digits) === 12) {
            return '0'.substr($digits, 3);
        }

        // «912345678» — a mobile typed without its leading zero.
        if (strlen($digits) === 9 && str_starts_with($digits, '9')) {
            return '0'.$digits;
        }

        return $digits;
    }

    /** The same shape the customer form accepts: 9 to 15 digits. */
    public static function isValid(string $normalised): bool
    {
        return preg_match('/^\d{9,15}$/', $normalised) === 1;
    }

    /**
     * Every spelling an older row may have been saved under, for an exact lookup that still finds
     * a customer typed before this rule existed.
     *
     * @return list<string>
     */
    public static function storedForms(string $normalised): array
    {
        $forms = [$normalised];

        if (str_starts_with($normalised, '0') && strlen($normalised) === 10) {
            $local = substr($normalised, 1);
            $forms[] = $local;
            $forms[] = '218'.$local;
            $forms[] = '00218'.$local;
        }

        return array_values(array_unique($forms));
    }
}
