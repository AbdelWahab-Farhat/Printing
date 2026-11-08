<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Requests\Order\PaymentFilterOptionsRequest;
use App\Application\Controller;
use App\Domain\Order\OrderService;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;

/**
 * Payment filter options
 *
 * ما تعرضه ورقة الفلتر في «مراجعة وتسوية الدفعات».
 */
class OrderPaymentFilterController extends Controller
{
    use ResponseTrait;

    public function __construct(private readonly OrderService $orders) {}

    /**
     * The filter options
     *
     * `kinds`: أزرار «نوع الدفعة»، كلٌّ منها يحمل `method` أو `account_id`. `accounts`: كل حسابٍ
     * يمكن أن تكون الدفعة فيه. `recorders`: مَن سجّل قيداً. `settlers`: مَن سوّى دفعة. أسماءٌ لا أرصدة.
     */
    public function options(PaymentFilterOptionsRequest $request): JsonResponse
    {
        return $this->success($this->orders->paymentFilterOptions());
    }
}
