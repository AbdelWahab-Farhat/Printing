<?php

declare(strict_types=1);

namespace App\Domain\Order\Enums;

/**
 * Which kind of sale an order is — INSTANT-ORDERS-PLAN.md §2.
 *
 * **Normal** is every order the shop has ever taken: the booking cycle, unchanged.
 *
 * **Instant** is a counter sale of plain stock at a branch. It uses the same customers, products,
 * stock, treasury and order tables, but walks its own short road (جديدة → تم الاستلام → تم
 * التسوية, or جديدة → إلغاء تام — see {@see OrderStatus::allowedNext()}), takes its stock off the
 * shelf the moment it is created, and is moved by its own permissions.
 *
 * Set once at creation and never changed: an instant order is not turned into a delivery one
 * (owner's decision, 2026-11-26) — it is cancelled and a normal order is taken instead.
 */
enum OrderType: string
{
    case Normal = 'normal';
    case Instant = 'instant';

    public function label(): string
    {
        return match ($this) {
            self::Normal => 'عادية',
            self::Instant => 'فورية',
        };
    }

    public function isInstant(): bool
    {
        return $this === self::Instant;
    }
}
