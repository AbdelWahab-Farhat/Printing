<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Customer\Enums\DesignKind;
use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Enums\DesignTicketFileKind;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Models\DesignTicketFile;
use App\Domain\Identity\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<DesignTicketFile>
 */
class DesignTicketFileFactory extends Factory
{
    /** @var class-string<DesignTicketFile> */
    protected $model = DesignTicketFile::class;

    /**
     * A brief by default — the employee's reference file, which is what a ticket has before
     * anybody has drawn anything.
     *
     * `version` and `status` are absent, and must be: the CHECK constraint refuses a brief that
     * carries either.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $uuid = Str::uuid()->toString();

        return [
            'design_ticket_id' => DesignTicket::factory(),
            'kind' => DesignTicketFileKind::Brief,
            'disk' => 'local',
            'path' => "design-tickets/1/{$uuid}.png",
            'original_filename' => 'logo.png',
            'mime_type' => 'image/png',
            'file_kind' => DesignKind::Image,
            'size_bytes' => 512_000,
            // Unique per row: the promotion into the customer's library is idempotent on this,
            // and a fixed value would make two different drafts promote to one design.
            'checksum' => hash('sha256', $uuid),
            'width_px' => 1200,
            'height_px' => 1600,
            'uploaded_by_user_id' => User::factory(),
        ];
    }

    /**
     * A designer's version, waiting on a verdict.
     *
     * The number is given rather than counted, because a factory that counted would collide with
     * the partial unique index the moment a test made two in the same breath.
     */
    public function submission(int $version = 1): static
    {
        return $this->state(fn (): array => [
            'kind' => DesignTicketFileKind::Submission,
            'version' => $version,
            'status' => DesignSubmissionStatus::Proposed,
        ]);
    }

    public function pdf(): static
    {
        return $this->state(fn (): array => [
            'original_filename' => 'artwork.pdf',
            'mime_type' => 'application/pdf',
            'file_kind' => DesignKind::Pdf,
            // A PDF has pages, not pixels.
            'width_px' => null,
            'height_px' => null,
        ]);
    }
}
