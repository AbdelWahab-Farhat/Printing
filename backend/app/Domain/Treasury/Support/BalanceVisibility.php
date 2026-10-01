<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Support;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Treasury\Models\TreasuryAccount;

/**
 * أيرى هذا الشخصُ رصيدَ هذا الحساب؟ — القاعدةُ نفسُها التي تفتح الحساب للقراءة.
 *
 * من يحمل `treasury.view` يرى كلَّ حساب، ومن الحسابُ باسمه يرى حسابه. فرسالةُ رفضٍ تذكر الرصيد
 * لا تكشف لأحدٍ ما لا يراه أصلاً على شاشته — موظّفٌ يسجّل ولا يرى الحسابات يعرف أن المال لا يكفي،
 * ولا يعرف كم في الخزنة.
 */
final class BalanceVisibility
{
    public function allows(TreasuryAccount $account, ?int $viewerId): bool
    {
        if ($viewerId === null) {
            return false;
        }

        $viewer = User::query()->find($viewerId);

        return $viewer !== null
            && ($viewer->can(PermissionName::ViewTreasury->value) || $account->isHeldBy($viewer));
    }
}
