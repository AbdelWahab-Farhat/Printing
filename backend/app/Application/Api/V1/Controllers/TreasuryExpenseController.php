<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Resources\TreasuryMovementResource;
use App\Application\Controller;
use App\Domain\Treasury\TreasuryService;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * «المصاريف» — the expenses of every account on one page, so nobody opens each account to find
 * them. TREASURY-DESIGN §٢١. Behind `treasury.view`: it reads every account.
 */
class TreasuryExpenseController extends Controller
{
    use ResponseTrait;

    public function __construct(private readonly TreasuryService $treasury) {}

    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
            'category_id' => ['nullable', 'integer'],
            'account_id' => ['nullable', 'integer'],
        ]);

        $perPage = min(max((int) $request->integer('per_page', 20), 1), 100);

        $expenses = $this->treasury->expenses($filters, $perPage);

        return $this->successWithPagination(
            TreasuryMovementResource::collection($expenses['page']),
            // What the whole filtered period adds up to — not this page's rows.
            extraMeta: ['expenses_total' => $expenses['total']],
        );
    }
}
