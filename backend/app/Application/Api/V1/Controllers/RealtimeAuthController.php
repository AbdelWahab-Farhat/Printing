<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Requests\Realtime\AuthorizeChannelRequest;
use App\Application\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Broadcast;

/**
 * البثّ الحيّ
 *
 * التوقيعُ الذي يدخل به الهاتفُ قناةً خاصة على خادم Reverb.
 *
 * **بابٌ واحد بمسارين**: `broadcasting/auth` تحت `auth:sanctum` للموظفين، و
 * `client/broadcasting/auth` تحت `auth:customer` للعملاء. الحارسُ على المسار يقرّر من يطرق،
 * والقناةُ في routes/channels.php تقرّر من يدخل — ولا يُكرَّر أيٌّ من القرارين هنا.
 *
 * **الجوابُ خارج المغلّف، وهو الاستثناء الوحيد في هذا الـ API.** بروتوكولُ Pusher يقرأ
 * `{"auth": "…"}` حرفياً، وعميلُه في التطبيقين لا يعرف `{status, message, data}`. أما الرفض
 * فيبقى في المغلّف كالعادة: ٤٠١ و٤٠٣ و٤٢٢ يرسمها bootstrap/app.php.
 */
class RealtimeAuthController extends Controller
{
    /**
     * توقيع قناة خاصة
     *
     * يرسل عميلُ Pusher رقمَ مقبسه واسمَ القناة، ويعود بالتوقيع الذي يقدّمه لخادم Reverb.
     */
    public function __invoke(AuthorizeChannelRequest $request): JsonResponse
    {
        return response()->json(Broadcast::auth($request));
    }
}
