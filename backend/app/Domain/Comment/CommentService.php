<?php

declare(strict_types=1);

namespace App\Domain\Comment;

use App\Application\Api\V1\Controllers\CommentController;
use App\Domain\Comment\Actions\PostComment;
use App\Domain\Comment\Contracts\Commentable;
use App\Domain\Comment\Models\Comment;
use App\Domain\Identity\Models\User;
use Illuminate\Database\Eloquent\Model;

/**
 * بابُ سياق الملاحظات — ومن ورائه فعلٌ واحد اليوم.
 *
 * **الكتابةُ وحدها تمرّ من هنا، والقراءةُ والتعديلُ والحذف ما تزال في المتحكّم.** وهذا نصفُ بابٍ
 * عن قصد لا عن سهو: الكتابةُ هي وحدها التي صار لها ما تعلنه، والثلاثةُ الباقية أربعةُ أسطر في
 * {@see CommentController} لا يكسبها نقلُها شيئاً اليوم.
 * وحين يحتاج التعديلُ أو الحذفُ إلى حدثٍ — «عُدّلت ملاحظةٌ كنتَ قد قرأتها» — فموضعُهما هنا،
 * والباب مفتوح.
 *
 * والبابُ لا منطقَ فيه: كلُّ تابعٍ يسلّم إلى `Action` (RULES §3).
 */
final readonly class CommentService
{
    public function __construct(private PostComment $post) {}

    /**
     * @param  Commentable&Model  $owner  السجلُّ الذي تُكتب الملاحظة عليه
     */
    public function post(Commentable&Model $owner, string $body, User $author): Comment
    {
        return $this->post->handle($owner, $body, $author);
    }
}
