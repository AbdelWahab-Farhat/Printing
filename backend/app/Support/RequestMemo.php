<?php

declare(strict_types=1);

namespace App\Support;

use Closure;
use Illuminate\Http\Request;
use WeakMap;

/**
 * جوابٌ يُحسب مرّةً واحدة لكل طلب HTTP، ثم يُعاد من الذاكرة حتى ينتهي الطلب.
 *
 * **لماذا لا `singleton` ولا `scoped`.** الحاوية لا تُفرغ ما هو `scoped` بين طلبين إلا في
 * الطوابير وOctane؛ وفي الاختبار تمرّ طلباتٌ كثيرة على حاويةٍ واحدة، فيقرأ الطلبُ الثاني جوابَ
 * الأول وقد تغيّرت القاعدة بينهما. المفتاحُ هنا **كائنُ الطلب نفسه** في `WeakMap`: طلبٌ جديد
 * كائنٌ جديد بذاكرةٍ فارغة، والقديم يُنسى مع كائنه.
 *
 * **ولا ذاكرةَ خارج طلبٍ له مسار.** عاملُ الطابور وأمرُ الكونسول يعيشان طويلاً على كائن طلبٍ
 * واحدٍ مصطنع، وذاكرةٌ عليه تحمل جواب مهمّةٍ إلى التي بعدها — فهناك يُحسب الجواب كل مرّة.
 *
 * لِما لا يتغيّر داخل الطلب الواحد فقط: قائمةُ حساباتٍ تُبنى منها حقولُ الشاشة، لا رصيدٌ يكتبه
 * الطلبُ نفسُه.
 */
final class RequestMemo
{
    /** @var WeakMap<Request, array<string, mixed>>|null */
    private static ?WeakMap $memo = null;

    /**
     * @template T
     *
     * @param  Closure(): T  $compute
     * @return T
     */
    public static function remember(string $key, Closure $compute): mixed
    {
        $request = app()->bound('request') ? app('request') : null;

        if (! $request instanceof Request || $request->route() === null) {
            return $compute();
        }

        self::$memo ??= new WeakMap;
        $remembered = self::$memo[$request] ?? [];

        if (! array_key_exists($key, $remembered)) {
            $remembered[$key] = $compute();
            self::$memo[$request] = $remembered;
        }

        return $remembered[$key];
    }
}
