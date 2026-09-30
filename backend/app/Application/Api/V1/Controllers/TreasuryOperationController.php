<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Controllers\Concerns\ReadsAuditTrail;
use App\Application\Api\V1\Requests\Audit\ActivityLogFilterRequest;
use App\Application\Api\V1\Requests\Treasury\ReverseTreasuryOperationRequest;
use App\Application\Api\V1\Requests\Treasury\StoreTreasuryOperationRequest;
use App\Application\Api\V1\Resources\TreasuryOperationResource;
use App\Application\Controller;
use App\Domain\Audit\AuditService;
use App\Domain\Treasury\DTOs\OperationData;
use App\Domain\Treasury\Enums\OperationType;
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Domain\Treasury\TreasuryService;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * Deposits, withdrawals, expenses, transfers, counts and openings — and undoing them.
 */
class TreasuryOperationController extends Controller
{
    use ReadsAuditTrail, ResponseTrait;

    public function __construct(private readonly TreasuryService $treasury) {}

    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'type' => ['nullable', Rule::enum(OperationType::class)],
            'account_id' => ['nullable', 'integer'],
            'category_id' => ['nullable', 'integer'],
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date'],
        ]);

        $perPage = min(max((int) $request->integer('per_page', 20), 1), 100);

        return $this->successWithPagination(
            TreasuryOperationResource::collection($this->treasury->operations($filters, $perPage)),
        );
    }

    public function show(TreasuryOperation $operation): JsonResponse
    {
        return $this->success(new TreasuryOperationResource($this->treasury->loadOperation($operation)));
    }

    public function store(StoreTreasuryOperationRequest $request): JsonResponse
    {
        $operation = $this->treasury->recordOperation(OperationData::fromArray($request->validated()), $request->user());

        return $this->created(
            new TreasuryOperationResource($this->treasury->loadOperation($operation)),
            "تم تسجيل «{$operation->type->label()}»",
        );
    }

    public function reverse(ReverseTreasuryOperationRequest $request, TreasuryOperation $operation): JsonResponse
    {
        $reversal = $this->treasury->reverseOperation(
            $operation,
            (string) $request->validated('reason'),
            $request->user(),
        );

        return $this->created(
            new TreasuryOperationResource($this->treasury->loadOperation($reversal)),
            'تم عكس العملية',
        );
    }

    public function logs(ActivityLogFilterRequest $request, TreasuryOperation $operation, AuditService $audit): JsonResponse
    {
        return $this->auditTrailResponse($request, $operation, $audit);
    }
}
