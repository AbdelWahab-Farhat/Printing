<?php

declare(strict_types=1);

namespace App\Domain\Treasury\DTOs;

use App\Domain\Treasury\Enums\AccountKind;

/**
 * An account as the accounts screen sends it. `kind` is read on create only — an account's kind
 * decides which payments may land in it, so changing it later would re-file its past.
 *
 * Every field but the name is optional on update, and absent means "leave it": `has*` records
 * whether the key was sent at all, since a sent `null` holder means "no longer anybody's".
 */
final readonly class AccountData
{
    public function __construct(
        public ?string $name,
        public ?AccountKind $kind,
        public ?int $holderUserId,
        public bool $hasHolder,
        public ?bool $isDefault,
        public ?bool $isActive,
        public ?string $notes,
        public bool $hasNotes,
        // Custody only: where its money goes at settlement. A sent null clears it.
        public ?int $settlesIntoAccountId = null,
        public bool $hasSettlesInto = false,
        // «يُجمَع عند التسوية» — false keeps its order money where it landed (§١٨).
        public ?bool $isCollected = null,
        // Cash only: the «استلام مكتب» branch this box serves (§١٩). A sent null unlinks it.
        public ?int $pickupCityId = null,
        public bool $hasPickupCity = false,
    ) {}

    /**
     * @param  array<string, mixed>  $validated
     */
    public static function fromArray(array $validated): self
    {
        $notes = array_key_exists('notes', $validated) ? trim((string) ($validated['notes'] ?? '')) : '';

        return new self(
            name: isset($validated['name']) ? trim((string) $validated['name']) : null,
            kind: isset($validated['kind']) ? AccountKind::from((string) $validated['kind']) : null,
            holderUserId: isset($validated['holder_user_id']) ? (int) $validated['holder_user_id'] : null,
            hasHolder: array_key_exists('holder_user_id', $validated),
            isDefault: isset($validated['is_default']) ? (bool) $validated['is_default'] : null,
            isActive: isset($validated['is_active']) ? (bool) $validated['is_active'] : null,
            notes: $notes !== '' ? $notes : null,
            hasNotes: array_key_exists('notes', $validated),
            settlesIntoAccountId: isset($validated['settles_into_account_id'])
                ? (int) $validated['settles_into_account_id']
                : null,
            hasSettlesInto: array_key_exists('settles_into_account_id', $validated),
            isCollected: isset($validated['is_collected']) ? (bool) $validated['is_collected'] : null,
            pickupCityId: isset($validated['pickup_city_id']) ? (int) $validated['pickup_city_id'] : null,
            hasPickupCity: array_key_exists('pickup_city_id', $validated),
        );
    }
}
