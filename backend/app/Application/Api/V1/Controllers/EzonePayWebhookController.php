<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Controller;
use App\Domain\OnlinePayment\Actions\RecordGatewayWebhook;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Payment webhooks
 *
 * Where EzonePay says a payment was made — CUSTOMER-WALLET §٥.
 *
 * **Keep, queue, answer** — the Nawris webhook's shape: every signed body is stored once and the
 * work is `ProcessEzonePayWebhook`'s, which asks EzonePay about the transaction before crediting
 * anything. Answers `{"status": true, "message": "Received"}`, the body EzonePay expects.
 */
class EzonePayWebhookController extends Controller
{
    public function __invoke(Request $request, RecordGatewayWebhook $record): JsonResponse
    {
        $record('ezone', $request->getContent(), (array) $request->json()->all());

        return response()->json(['status' => true, 'message' => 'Received']);
    }
}
