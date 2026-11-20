<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The second and later images of a design version (DESIGN-VERSION-IMAGES.md §4).
 *
 * **Face 1 stays on the version row.** Every rule on `design_ticket_files` — one row per version
 * number, one approved version per ticket, the completion shape on `design_tickets` — keeps
 * reading one row per version, and a version uploaded before this table existed is simply a
 * version with no extra faces.
 *
 * A face follows its version: withdrawing a version soft-deletes the version row, and its faces
 * stay readable behind it exactly as its own file does.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('design_ticket_file_faces', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('design_ticket_file_id')->constrained('design_ticket_files')->cascadeOnDelete();

            // 2, 3, … — face 1 is the version row itself.
            $table->unsignedSmallInteger('position');

            // The same columns, sized the same, as the version row's own file.
            $table->string('disk', 30);
            $table->string('path', 1024);
            $table->string('original_filename')->nullable();
            $table->string('mime_type', 100);
            $table->unsignedBigInteger('size_bytes');
            $table->char('checksum', 64);
            $table->unsignedInteger('width_px')->nullable();
            $table->unsignedInteger('height_px')->nullable();

            // The library design this face became on approval. Null until then.
            $table->foreignId('customer_design_id')->nullable()->constrained('customer_designs')->nullOnDelete();

            $table->timestamps();
            // Every domain model soft-deletes (ModelConventionsTest). Nothing deletes a face
            // today — it follows its version — but a deletion is the one change the audit trail
            // could not undo.
            $table->softDeletes();

            $table->unique(['design_ticket_file_id', 'position']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('design_ticket_file_faces');
    }
};
