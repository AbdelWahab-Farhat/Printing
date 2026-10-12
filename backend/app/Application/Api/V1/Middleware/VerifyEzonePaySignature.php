<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Middleware;

use App\Domain\OnlinePayment\Gateway\OnlinePaymentGateway;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

/**
 * The only thing in front of EzonePay's webhook: its `X-Signature` over the raw body, checked in
 * constant time by the gateway. **Fails closed** — no secret configured, no header, or a mismatch
 * is a 401. The expected signature is never logged (Primula logged it on a mismatch).
 */
class VerifyEzonePaySignature
{
    public function __construct(private readonly OnlinePaymentGateway $gateway) {}

    public function handle(Request $request, Closure $next): Response
    {
        if (! $this->gateway->verifyWebhook($request->getContent(), $request->header('X-Signature'))) {
            Log::channel('ezone')->warning('webhook signature refused', ['ip' => $request->ip()]);

            return response()->json([
                'status' => false,
                'message' => 'غير مصرّح',
                'data' => null,
            ], 401);
        }

        return $next($request);
    }
}
