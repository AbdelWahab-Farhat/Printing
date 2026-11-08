<?php

declare(strict_types=1);

namespace App\Domain\Order\Queries;

use App\Domain\Delivery\Models\City;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderPaymentType;
use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Enums\OperationType;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Collection;

/**
 * ما تعرضه ورقة الفلتر في «مراجعة وتسوية الدفعات».
 *
 * **«نوع الدفعة» أزرارٌ بلغة المحلّ، وبعضها طريقةٌ وبعضها حساب** (طلب صاحب العمل ٢٠٢٦-١١-٠٧):
 * «حوالة» طريقة دفع، أمّا «كاش نورس» و«مكتب قرجي» فكلاهما طريقته كاش، والحساب هو الفرق. لذلك يحمل
 * كلُّ زرٍّ `method` أو `account_id`، وتُرسله الورقة كما هو. **والأكثر استعمالاً أوّلاً**، من القيود
 * الحيّة نفسها لا من ترتيبٍ مكتوب (طلبُه أيضاً، ٢٠٢٦-١١-٠٧).
 *
 * **حسابات المكاتب وحدها أزرار**: لكل موظفٍ قد يكون حساب، والبقية في «حساب آخر» من `accounts`.
 *
 * **أسماءٌ لا أرصدة**: المراجع لا يحمل صلاحية الخزينة ولا `users.view`.
 */
final class PaymentFilterOptions
{
    public function __construct(private readonly TreasuryService $treasury) {}

    /**
     * @return array{kinds: list<array{label: string, method: ?string, account_id: ?int}>, accounts: list<array<string, mixed>>, recorders: list<array{id: int, name: string}>, settlers: list<array{id: int, name: string}>}
     */
    public function all(): array
    {
        return [
            'kinds' => $this->kinds(),
            'accounts' => $this->treasury->settlementAccounts()['sources'],
            'recorders' => $this->people(OrderPayment::query()
                ->whereIn('type', [OrderPaymentType::Payment->value, OrderPaymentType::Refund->value])
                ->select('recorded_by')),
            'settlers' => $this->people(TreasuryOperation::query()
                ->where('type', OperationType::Settlement->value)
                ->whereNotNull('order_payment_id')
                ->select('recorded_by')),
        ];
    }

    /**
     * @return list<array{label: string, method: ?string, account_id: ?int}>
     */
    private function kinds(): array
    {
        $byMethod = $this->usesBy('method');
        $byAccount = $this->usesBy('treasury_account_id');

        return collect([
            $this->method(PaymentMethod::BankTransfer),
            ...$this->nawris(),
            ...$this->offices(),
            $this->method(PaymentMethod::Libyana),
            $this->method(PaymentMethod::BankCard),
        ])
            // ترتيبُ PHP ثابت، فالتعادل يُبقي ترتيب القائمة أعلاه: طلبَ صاحب العمل، ونظامٌ جديدٌ بلا دفعات.
            ->sortByDesc(fn (array $kind): int => (int) ($kind['method'] === null
                ? $byAccount->get($kind['account_id'], 0)
                : $byMethod->get($kind['method'], 0)))
            ->values()
            ->all();
    }

    /**
     * كم قيداً لكل قيمة من [$column]، من القيود التي تظهر في القائمتين: الملغى لم يحصل، والقديم بلا
     * حساب يعرف طريقته ولا يعرف مكتبه، فلو حُسب لتقدّمت الطرق على المكاتب بما لا يُقارَن.
     *
     * @return Collection<int|string, int>
     */
    private function usesBy(string $column): Collection
    {
        return OrderPayment::query()
            ->whereIn('type', [OrderPaymentType::Payment->value, OrderPaymentType::Refund->value])
            ->whereDoesntHave('reversal')
            ->whereNotNull('treasury_account_id')
            ->groupBy($column)
            ->toBase()
            ->selectRaw("{$column} as used_key, count(*) as uses")
            ->pluck('uses', 'used_key');
    }

    /**
     * @return array{label: string, method: string, account_id: null}
     */
    private function method(PaymentMethod $method): array
    {
        return ['label' => $method->label(), 'method' => $method->value, 'account_id' => null];
    }

    /**
     * @return list<array{label: string, method: null, account_id: int}>
     */
    private function nawris(): array
    {
        return TreasuryAccount::query()
            ->active()
            ->where('system_code', TreasuryAccount::NAWRIS)
            ->get()
            ->map(fn (TreasuryAccount $account) => $this->account('كاش نورس', $account))
            ->values()
            ->all();
    }

    /**
     * @return list<array{label: string, method: null, account_id: int}>
     */
    private function offices(): array
    {
        $accounts = TreasuryAccount::query()
            ->active()
            ->where('kind', AccountKind::Cash->value)
            ->whereNotNull('pickup_city_id')
            ->orderByDesc('is_default')
            ->orderBy('name')
            ->get();

        $cities = City::query()->whereIn('id', $accounts->pluck('pickup_city_id'))->pluck('name', 'id');

        return $accounts
            ->map(fn (TreasuryAccount $account) => $this->account(
                $this->officeLabel((string) $cities->get($account->pickup_city_id), $account),
                $account,
            ))
            ->values()
            ->all();
    }

    /**
     * «إستلام مكتب(قرجي)» تصير «مكتب قرجي». مكتبٌ سُمّي بغير هذا الشكل يبقى باسم حسابه.
     */
    private function officeLabel(string $city, TreasuryAccount $account): string
    {
        return preg_match('/\((.+)\)/u', $city, $office) === 1 ? 'مكتب '.$office[1] : (string) $account->name;
    }

    /**
     * @return array{label: string, method: null, account_id: int}
     */
    private function account(string $label, TreasuryAccount $account): array
    {
        return ['label' => $label, 'method' => null, 'account_id' => (int) $account->id];
    }

    /**
     * مَن وقّع على قيدٍ يظهر في القائمتين، ومن تَرَك العمل معهم: دفعاته باقية، فلا بدّ أن يبقى اسمه.
     *
     * @template TModel of \Illuminate\Database\Eloquent\Model
     *
     * @param  Builder<TModel>  $signatures
     * @return list<array{id: int, name: string}>
     */
    private function people(Builder $signatures): array
    {
        return User::withTrashed()
            ->whereIn('id', $signatures)
            ->orderBy('name')
            ->get(['id', 'name'])
            ->map(fn (User $user) => ['id' => (int) $user->id, 'name' => (string) $user->name])
            ->values()
            ->all();
    }
}
