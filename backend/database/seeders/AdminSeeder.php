<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class AdminSeeder extends Seeder
{
    /**
     * Seeds the account used to try the API from /docs/api during local development.
     *
     * Idempotent — safe to re-run without duplicating the account.
     */
    public function run(): void
    {
        User::query()->updateOrCreate(
            ['email' => 'admin@printing.ly'],
            [
                'name' => 'المدير',
                'phone' => '0910000000',
                'password' => 'password',
                'email_verified_at' => now(),
            ],
        );
    }
}
