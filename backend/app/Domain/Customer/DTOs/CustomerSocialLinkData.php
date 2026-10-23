<?php

declare(strict_types=1);

namespace App\Domain\Customer\DTOs;

final readonly class CustomerSocialLinkData
{
    public function __construct(
        public string $url,
        /** موجودٌ حين يُعدَّل رابطٌ قائم، وnull لرابطٍ جديد. */
        public ?int $id = null,
    ) {}

    /**
     * @param  array<string, mixed>  $link  عنصرٌ واحد من مصفوفة `social_links` بعد التحقق منها.
     */
    public static function fromArray(array $link): self
    {
        return new self(
            url: trim((string) $link['url']),
            id: isset($link['id']) ? (int) $link['id'] : null,
        );
    }

    /**
     * @param  array<int, array<string, mixed>>  $links
     * @return list<self>
     */
    public static function listFromArray(array $links): array
    {
        return array_values(array_map(self::fromArray(...), $links));
    }
}
