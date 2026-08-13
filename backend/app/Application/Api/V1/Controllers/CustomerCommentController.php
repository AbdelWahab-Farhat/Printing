<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Controllers\Concerns\ReadsAuditTrail;
use App\Application\Api\V1\Requests\Audit\ActivityLogFilterRequest;
use App\Application\Api\V1\Requests\Customer\StoreCustomerCommentRequest;
use App\Application\Api\V1\Requests\Customer\UpdateCustomerCommentRequest;
use App\Application\Api\V1\Resources\CustomerCommentResource;
use App\Application\Controller;
use App\Domain\Audit\AuditService;
use App\Domain\Customer\Exceptions\CommentBelongsToSomebodyElse;
use App\Domain\Customer\Models\Customer;
use App\Domain\Customer\Models\CustomerComment;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Customer comments
 *
 * What staff write to each other about a customer — «يفضّل التسليم صباحاً», «لا يردّ إلا على
 * واتساب». Things that are true of the person and have no field in the form, which today are
 * said out loud and leave with whoever heard them.
 *
 * **Writing one costs `customers.view` and nothing more.** A note is a working tool, not a
 * privilege: anyone who may look a customer up may leave the next person a sentence about them.
 *
 * **Changing one is «its author, or a moderator».** Rewriting a colleague's sentence under their
 * name is a different power from correcting a customer's phone number, so it has its own
 * permission — `customers.comments.moderate` — rather than riding on `customers.manage`. Each
 * row carries `can_edit` and `can_delete` for the reader asking, so the app draws the buttons
 * without holding a second copy of the rule.
 *
 * Deleting is soft: the list loses the note, the history keeps it, and
 * `/comments/{comment}/logs` still answers who wrote what and who removed it.
 */
class CustomerCommentController extends Controller
{
    use ReadsAuditTrail, ResponseTrait;

    /**
     * List a customer's comments
     *
     * Newest first — a note is read to catch up, so the last thing said is the first thing
     * shown. Not paginated: a customer accumulates notes at the speed of conversation, and the
     * day one has hundreds is the day this grows a cursor.
     */
    public function index(Customer $customer): JsonResponse
    {
        return $this->success(
            CustomerCommentResource::collection($customer->comments()->with('author')->get()),
        );
    }

    /**
     * Leave a comment
     *
     * The author is the signed-in user and is never read from the body: a note is attributed,
     * and attribution nobody can set is attribution nobody can forge.
     */
    public function store(StoreCustomerCommentRequest $request, Customer $customer): JsonResponse
    {
        $comment = new CustomerComment($request->validated());
        $comment->customer()->associate($customer);
        $comment->author()->associate($request->user());
        $comment->save();

        return $this->created(
            new CustomerCommentResource($comment->load('author')),
            'تمت إضافة الملاحظة',
        );
    }

    /**
     * Rewrite a comment
     *
     * Its author, or somebody holding `customers.comments.moderate`. Anyone else is refused with
     * 403. Stamps `edited_at`, so a note that changed says so — a sentence that quietly becomes
     * a different sentence is worse than no note at all.
     */
    public function update(
        UpdateCustomerCommentRequest $request,
        Customer $customer,
        CustomerComment $comment,
    ): JsonResponse {
        $this->refuseUnlessChangeable($request, $comment);

        $comment->fill($request->validated());

        // Only when the text actually moved. Re-sending the same sentence is not an edit, and
        // stamping it would put «عُدّلت» under a note nobody changed.
        if ($comment->isDirty('body')) {
            $comment->edited_at = now();
        }

        $comment->save();

        return $this->success(
            new CustomerCommentResource($comment->load('author')),
            'تم تعديل الملاحظة',
        );
    }

    /**
     * Remove a comment
     *
     * Soft — the row leaves the list and stays in the history, which is what makes «من حذف
     * الملاحظة؟» answerable at all.
     */
    public function destroy(Request $request, Customer $customer, CustomerComment $comment): JsonResponse
    {
        $this->refuseUnlessChangeable($request, $comment);

        $comment->delete();

        return $this->successMessage('تم حذف الملاحظة');
    }

    /**
     * A comment's history
     *
     * Behind `logs.view` like every other history: reading one shows what everybody has done,
     * which is a different decision from being allowed to read the record.
     */
    public function logs(
        ActivityLogFilterRequest $request,
        Customer $customer,
        CustomerComment $comment,
        AuditService $audit,
    ): JsonResponse {
        return $this->auditTrailResponse($request, $comment, $audit);
    }

    /**
     * The one authorization rule, asked in the one place both write endpoints pass through.
     *
     * The rule itself lives on the model — the resource asks it too, to fill `can_edit` — so
     * there is exactly one sentence in the codebase saying who may change a note.
     */
    private function refuseUnlessChangeable(Request $request, CustomerComment $comment): void
    {
        if (! $comment->isChangeableBy($request->user())) {
            throw CommentBelongsToSomebodyElse::make();
        }
    }
}
