<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Actions;

use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Events\DesignTicketProgressed;
use App\Domain\DesignTicket\Exceptions\DesignerCannotReviewOwnWork;
use App\Domain\DesignTicket\Exceptions\DesignReviewRequiresNote;
use App\Domain\DesignTicket\Exceptions\DesignTicketIsClosed;
use App\Domain\DesignTicket\Exceptions\DesignTicketPayChanged;
use App\Domain\DesignTicket\Exceptions\DesignVersionAlreadyReviewed;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Models\DesignTicketFile;
use App\Domain\EmployeeWallet\EmployeeWalletService;
use App\Domain\Identity\Enums\EmployeeServiceType;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Actions\AttachApprovedTicketDesigns;
use Illuminate\Support\Facades\DB;

/**
 * The employee's verdict on one version — and, when it is «موافقة», the end of the ticket.
 *
 * **Approving is not a status change followed by some bookkeeping; it is one fact with four
 * parts**, which is why they share a transaction: the version is sealed, the artwork lands on the
 * customer's account, the ticket closes, and the row that closed it is named. The database
 * refuses any partial version of that through `design_tickets_completion_shape` — «مكتمل» with no
 * `approved_customer_design_id` cannot be written at all. That constraint is what makes the
 * brief's headline promise unrepresentable when wrong rather than a step somebody can forget.
 *
 * **The reviewer may not be the uploader**, and this is the one guard that is not about
 * correctness. Withholding `design_tickets.review` from the designer role is necessary and not
 * sufficient — an administrator holds every permission by rule — so the separation of execution
 * from approval has to be a domain refusal or it is not real. `ConfirmDepositReceipt` draws the
 * same line in the same place for the same reason.
 *
 * **A version is judged once.** Changing a verdict afterwards would erase the reason the next
 * version exists, and that trail is the entire value of keeping versions at all.
 *
 * **A change request must say what to change.** The whole point of a revision round is the words.
 *
 * **والأجرُ جزءٌ خامس من الحقيقة نفسها** (SERVICE-PAY-DESIGN §٤): يدخل محفظة رافع النسخة المعتمدة في
 * المعاملة نفسها، فلا تكتمل تذكرةٌ ويضيع أجرها، ولا يُدفع عن اعتمادٍ تراجع. ولأن المال صار يتبع هذا
 * الفعل، فالفحوص كلُّها تحت قفل التذكرة: موافقتان في اللحظة نفسها كانتا تمرّان معاً.
 *
 * **ويستلمه مَن رفع النسخة لا مَن يحمل التذكرة**: نسخةٌ معلّقة تبقى بعد الإعادة إلى الطابور، وقد تُعتمد
 * وغيرُ راسمها يحمل التذكرة.
 */
final class ReviewDesignVersion
{
    public function __construct(
        private readonly PromoteApprovedDesign $promote,
        private readonly EmployeeWalletService $wallet,
        private readonly AttachApprovedTicketDesigns $attachToOrder,
    ) {}

    /**
     * @param  string|null  $confirmedPay  المبلغ الذي قرأه المعتمد في نافذة التأكيد، `0` إن لم يقرأ
     *                                     أجراً. `null` من نسخةٍ قديمة لا تعرفه، فلا يُقارَن.
     *
     * @throws DesignTicketIsClosed
     * @throws DesignVersionAlreadyReviewed
     * @throws DesignerCannotReviewOwnWork
     * @throws DesignReviewRequiresNote
     * @throws DesignTicketPayChanged
     */
    public function __invoke(
        DesignTicket $ticket,
        DesignTicketFile $version,
        DesignSubmissionStatus $verdict,
        ?string $note = null,
        ?User $actor = null,
        ?string $confirmedPay = null,
    ): DesignTicketFile {
        return DB::transaction(function () use ($ticket, $version, $verdict, $note, $actor, $confirmedPay): DesignTicketFile {
            DesignTicket::query()->whereKey($ticket->getKey())->lockForUpdate()->firstOrFail();

            $ticket->refresh();
            $version->refresh();

            if (! $ticket->isOpen()) {
                throw DesignTicketIsClosed::make($ticket->status);
            }

            if ($version->status?->isReviewed() === true) {
                throw DesignVersionAlreadyReviewed::make((int) $version->version, $version->status);
            }

            // Before the note check, so somebody reviewing their own work is told the real reason
            // rather than being sent to write a note that will be refused anyway.
            if ($actor !== null
                && $version->uploaded_by_user_id !== null
                && (int) $version->uploaded_by_user_id === (int) $actor->getKey()) {
                throw DesignerCannotReviewOwnWork::make();
            }

            $note = $note === null ? null : (trim($note) !== '' ? trim($note) : null);

            if ($verdict->requiresNote() && $note === null) {
                throw DesignReviewRequiresNote::make();
            }

            // لا يُدفع غير ما وافق عليه: الأجرُ يُكتب والنافذة مفتوحة.
            if ($verdict === DesignSubmissionStatus::Approved
                && $confirmedPay !== null
                && bccomp($this->payOn($ticket), $confirmedPay, 2) !== 0) {
                throw DesignTicketPayChanged::make();
            }

            $version->forceFill([
                'status' => $verdict,
                'review_note' => $note,
                'reviewed_at' => now(),
                'reviewed_by' => $actor?->getKey(),
            ])->save();

            $status = $verdict === DesignSubmissionStatus::Approved
                ? DesignTicketStatus::Completed
                : DesignTicketStatus::ChangesRequested;

            $attributes = ['status' => $status];

            if ($verdict === DesignSubmissionStatus::Approved) {
                $design = ($this->promote)($ticket, $version);

                $attributes['completed_at'] = now();
                $attributes['approved_by_user_id'] = $actor?->getKey();
                $attributes['approved_customer_design_id'] = $design->getKey();
            }

            $ticket->forceFill($attributes)->save();

            if ($verdict === DesignSubmissionStatus::Approved) {
                $this->pay($ticket, $version, $actor);

                // «تصميم طلبية»: the approved design goes onto its order in the same transaction,
                // approved there too (PRINT-COLORS.md §11). An order that does not take artwork
                // right now gets it when it next does; an archived one gets nothing.
                $order = $ticket->order_id === null ? null : $ticket->order()->first();

                if ($order !== null && ! $order->trashed()) {
                    ($this->attachToOrder)($order, $actor);
                }
            }

            DesignTicketProgressed::dispatch(
                (int) $ticket->getKey(),
                $status,
                $actor === null ? null : (int) $actor->getKey(),
            );

            return $version->refresh();
        });
    }

    private function payOn(DesignTicket $ticket): string
    {
        return (string) ($ticket->designer_pay ?? '0');
    }

    /** بلا أجر لا سطر ولا عملية، وتكتمل التذكرة كما كانت. */
    private function pay(DesignTicket $ticket, DesignTicketFile $version, ?User $actor): void
    {
        $payee = $version->uploaded_by_user_id ?? $ticket->designerId();

        if ($payee === null || bccomp($this->payOn($ticket), '0', 2) <= 0) {
            return;
        }

        $this->wallet->payForService(
            (int) $payee,
            EmployeeServiceType::Design,
            $this->payOn($ticket),
            "design-ticket:{$ticket->getKey()}",
            "أجر تصميم {$ticket->code}",
            $actor,
        );
    }
}
