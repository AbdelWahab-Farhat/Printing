<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            // Roles first — the accounts below are assigned roles as they are created.
            RoleSeeder::class,
            AdminSeeder::class,
            CatalogSeeder::class,
            DeliveryLocationSeeder::class,
            BusinessFieldSeeder::class,
            // Warehouses only. Stock arrives by being recorded, never by being seeded.
            InventorySeeder::class,
        ]);
    }
}
