<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Per-employee push settings — Docs/notifications/PUSH-PREFERENCES.md.
 *
 * **Sparse.** A missing row means «push on», which is how every employee stood before this
 * table existed. So nobody's phone changes on deploy, and a notification type added next year
 * needs no row and no migration.
 *
 * - `type`: a published `NotificationType` value (`order.status`).
 * - `scope`: narrows a type — today only the order status an `order.status` notification
 *   reached. An empty string, not NULL, for «the whole type», so the unique index below holds:
 *   Postgres treats NULLs as distinct and would let two rows for the same switch exist.
 * - `push`: false silences the phone. The bell is never switched off.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notification_preferences', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')->constrained('users')->restrictOnDelete();

            $table->string('type', 60);
            $table->string('scope', 40)->default('');
            $table->boolean('push')->default(true);

            $table->timestamps();
            $table->softDeletes()->index();
        });

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX notification_preferences_user_type_scope_unique
            ON notification_preferences (user_id, type, scope)
            WHERE deleted_at IS NULL
        SQL);
    }

    public function down(): void
    {
        Schema::dropIfExists('notification_preferences');
    }
};
