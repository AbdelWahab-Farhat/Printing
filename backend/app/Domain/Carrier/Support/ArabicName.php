<?php

declare(strict_types=1);

namespace App\Domain\Carrier\Support;

/**
 * One spelling of an Arabic place name, so two lists written by different people can be compared.
 *
 * **Only the differences nobody means.** «الزاوية» and «الزاويه» are the same town; so are
 * «إجدابيا» and «اجدابيا», and «طرابلس  الكبرى» with two spaces. None of those is a decision
 * somebody made — they are the keyboard, the hamza, and a stray space. Everything else is left
 * exactly as written, because a normaliser that reaches further starts merging places that are
 * genuinely different.
 *
 * **The carrier's own routing suffix goes too.** Most of their list reads «اجدابيا(s444)»,
 * «الخمس(S7)», «يفرن (s15)» — a branch code appended to the town, not part of its name. Leaving
 * it in left 87 of our 95 cities unmatched against a list that plainly contained them. **Their
 * areas bracket it squarely** — «إقزير[S5]» — which is why both pairs are matched here and not
 * just the one the cities happened to use.
 *
 * **Not a fuzzy match.** There is no edit distance here on purpose: a nearest-neighbour match on
 * city names sends parcels to the wrong town, and the failure is silent — the parcel simply
 * arrives somewhere else. Names that do not agree after this are reported for a human.
 */
final class ArabicName
{
    /** The vowel marks and the tatweel, none of which change which town is meant. */
    private const STRIPPED = ['ً', 'ٌ', 'ٍ', 'َ', 'ُ', 'ِ', 'ّ', 'ْ', 'ٰ', 'ـ'];

    /** The letters typed a dozen ways for one sound. */
    private const FOLDED = [
        'أ' => 'ا', 'إ' => 'ا', 'آ' => 'ا', 'ٱ' => 'ا',
        'ة' => 'ه',
        'ى' => 'ي', 'ئ' => 'ي',
        'ؤ' => 'و',
    ];

    public static function normalize(?string $name): string
    {
        $name = trim((string) $name);

        if ($name === '') {
            return '';
        }

        // Their branch code, round or square, in either alphabet's brackets. Anchored to the end
        // so a genuine parenthetical mid-name — if one ever appears — is left alone.
        $name = (string) preg_replace('/\s*[(（\[［][^)）\]］]*[)）\]］]\s*$/u', '', $name);

        $name = str_replace(self::STRIPPED, '', $name);
        $name = strtr($name, self::FOLDED);

        // Any run of whitespace is one space — including the non-breaking kind that arrives in
        // data pasted out of a browser, and the underscore they join words with: their suburbs
        // are «ضواحي_طرابلس» where ours are «ضواحي طرابلس».
        $name = (string) preg_replace('/[\s_]+/u', ' ', str_replace("\u{00A0}", ' ', $name));

        return trim($name);
    }

    /**
     * The same name with «ال» off the front of every word.
     *
     * **A second exact comparison, not a fuzzy one.** «قصر الخيار» and «قصر خيار» are one place
     * written by two people; nothing here measures distance or picks a nearest neighbour. It is
     * used only after {@see normalize} has failed to find anything, and only when exactly one of
     * their names collapses to it — two that collapse together are reported rather than chosen
     * between, because «البيضاء» and «بيضاء» could be two towns.
     */
    public static function withoutArticles(?string $name): string
    {
        $words = explode(' ', self::normalize($name));

        // Left alone when the word *is* «ال…» and nothing else would remain.
        $stripped = array_map(
            static fn (string $word): string => mb_strlen($word) > 3 && str_starts_with($word, 'ال')
                ? mb_substr($word, 2)
                : $word,
            $words,
        );

        return implode(' ', $stripped);
    }
}
