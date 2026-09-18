<?php

declare(strict_types=1);

namespace App\Domain\Comment\Actions;

use App\Domain\Comment\Contracts\Commentable;
use App\Domain\Comment\Events\CommentPosted;
use App\Domain\Comment\Models\Comment;
use App\Domain\Identity\Models\User;
use Illuminate\Database\Eloquent\Model;

/**
 * تُكتب الملاحظة، وتُنسب إلى كاتبها، ويُعلَن أنها كُتبت.
 *
 * **الأسطر الأربعة الأولى كانت في المتحكّم، وانتقلت إلى هنا لأجل السطر الخامس.** الحدثُ هو
 * السبب: لا يُطلق حدثٌ واحد في هذا التطبيق من طبقة `Application` — كلُّها من `Actions` — ونقلُ
 * الكتابة أرخصُ من كسر تلك القاعدة، وهو أيضاً ما تطلبه RULES §3 من المتحكّمات أصلاً.
 *
 * **`user_id` تُختم هنا ولا تُملأ من الطلب أبداً.** الملاحظة منسوبة، والنسبةُ التي لا يستطيع أحد
 * أن يضعها هي النسبةُ التي لا يستطيع أحد أن يزوّرها — قاعدةُ {@see Comment} الوحيدة.
 *
 * **ولا شيء هنا يسأل هل المحادثة مفتوحة.** ذلك سؤالٌ عن *السجلّ* لا عن الملاحظة، ويُسأل عند الباب
 * في `CommentController::refuseUnlessOpen()` قبل أن يصل شيء إلى هنا — وموضعُه هناك لأن جوابه
 * يُرفَض به التعديلُ والحذفُ أيضاً، وهما لا يمرّان بهذا الصنف.
 */
final readonly class PostComment
{
    /**
     * @param  Commentable&Model  $owner  العقدُ يقول «يجوز التعليق عليه»، و`Model` تقول «له صفٌّ
     *                                    يُربط به» — والاثنان لازمان، ولا يحمل أيٌّ منهما وحده
     *                                    ما يكفي لـ`associate()`
     */
    public function handle(Commentable&Model $owner, string $body, User $author): Comment
    {
        $comment = new Comment(['body' => $body]);
        $comment->commentable()->associate($owner);
        $comment->author()->associate($author);
        $comment->save();

        // بعد الحفظ لا قبله: المعرِّف لا يوجد قبله، و«النوع» يُقرأ من الصفّ نفسه فيكون الاسمَ
        // المستعار الذي كُتب فعلاً لا الذي نظنّ أنه كُتب.
        CommentPosted::dispatch(
            (int) $comment->getKey(),
            (string) $comment->commentable_type,
            (int) $comment->commentable_id,
            (int) $author->getKey(),
        );

        return $comment;
    }
}
