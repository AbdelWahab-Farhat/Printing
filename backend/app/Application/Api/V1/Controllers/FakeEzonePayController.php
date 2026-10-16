<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Controller;
use App\Domain\OnlinePayment\Actions\RecordGatewayWebhook;
use App\Domain\OnlinePayment\Gateway\Fake\FakeEzonePayGateway;
use App\Domain\OnlinePayment\Gateway\OnlinePaymentGateway;
use App\Domain\OnlinePayment\Jobs\ProcessEzonePayWebhook;
use Illuminate\Http\Response;

/**
 * The pretend bank-card page — `EZONE_PAY_DRIVER=fake` only, never in production (the routes are
 * not registered there). CUSTOMER-WALLET §٥.
 *
 * «ادفع» takes the path a real EzonePay webhook takes: the event is kept once by
 * {@see RecordGatewayWebhook}, then worked at once rather than left for a queue worker, so the
 * app's waiting screen turns without one running.
 *
 * @hideFromAPIDocumentation
 */
class FakeEzonePayController extends Controller
{
    public function show(OnlinePaymentGateway $gateway, int $link): Response
    {
        $known = $gateway instanceof FakeEzonePayGateway ? $gateway->link($link) : null;

        if ($known === null) {
            return $this->page('هذا الرابط غير معروف', 'ارجع إلى التطبيق وابدأ من جديد.', null, 404);
        }

        return $this->page(
            'دفع تجريبي',
            "المبلغ: {$known['amount']} د.ل — المرجع {$known['reference']}. لا يُخصم شيء حقيقي.",
            url("/api/v1/fake-ezone/pay/{$link}"),
        );
    }

    public function pay(OnlinePaymentGateway $gateway, RecordGatewayWebhook $record, int $link): Response
    {
        $payload = $gateway instanceof FakeEzonePayGateway ? $gateway->payLink($link) : null;

        if ($payload === null) {
            return $this->page('هذا الرابط غير معروف', 'ارجع إلى التطبيق وابدأ من جديد.', null, 404);
        }

        $body = (string) json_encode($payload);
        $event = $record('ezone', $body, $payload);

        ProcessEzonePayWebhook::dispatchSync((int) $event->getKey());

        return $this->page('تم الدفع', 'ارجع إلى التطبيق — ستُشحن محفظتك خلال ثوانٍ.', null);
    }

    private function page(string $title, string $line, ?string $payTo, int $status = 200): Response
    {
        $title = e($title);
        $line = e($line);
        $button = $payTo === null ? '' : '<form method="post" action="'.e($payTo).'">'
            .'<button type="submit">ادفع</button></form>';

        return response(<<<HTML
            <!doctype html>
            <html lang="ar" dir="rtl">
            <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>{$title}</title>
            <style>
            body { font-family: sans-serif; background: #f5f5f5; margin: 0; padding: 32px 16px; text-align: center; }
            .card { background: #fff; border-radius: 16px; padding: 24px; max-width: 420px; margin: auto; }
            .tag { color: #b45309; font-weight: bold; }
            button { font-size: 20px; padding: 12px 48px; border: 0; border-radius: 12px; background: #0f766e; color: #fff; }
            </style>
            </head>
            <body>
            <div class="card">
            <p class="tag">EzonePay — وضع تجريبي</p>
            <h2>{$title}</h2>
            <p>{$line}</p>
            {$button}
            </div>
            </body>
            </html>
            HTML, $status)->header('Content-Type', 'text/html; charset=utf-8');
    }
}
