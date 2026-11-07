<?php

declare(strict_types=1);

namespace Tests\Feature\Carrier;

use App\Domain\Carrier\Models\NawrisParcel;
use App\Domain\Carrier\Models\NawrisParcelOrder;
use App\Domain\Carrier\Models\NawrisSettlementImport;
use App\Domain\Carrier\Models\NawrisWebhookEvent;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Notification\Listeners\NotifyWhenOrderStatusChanges;
use App\Domain\Notification\Models\Notification;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Events\OrderStatusChanged;
use App\Domain\Order\Models\Order;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Enums\OperationType;
use App\Domain\Treasury\Models\ExpenseCategory;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryMovement;
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Domain\Treasury\Models\TreasurySetting;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Testing\TestResponse;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use PHPUnit\Framework\Attributes\DataProvider;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * تقرير النورس: معاينة لا تكتب شيئاً، ثم تسوية ما يصلح وتخطّي ما عداه، والمال في مكانه.
 *
 * Arrange - Act - Assert throughout.
 */
class NawrisSettlementImportTest extends TestCase
{
    use RefreshDatabase;

    private const SECRET = 'shared-secret';

    private const PREVIEW = '/api/v1/carrier/settlement-imports/preview';

    private const STORE = '/api/v1/carrier/settlement-imports';

    /** @var array<string, string> */
    private array $headers;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        Storage::fake('local');
        config()->set('services.nawris.webhook_secret', self::SECRET);
        config()->set('services.nawris.webhook_ips', []);
        config()->set('services.nawris.log_channel', 'null');

        $this->user = User::factory()->create();
        $this->user->givePermissionTo(PermissionName::SettleOrders->value);
        $this->headers = ['Authorization' => 'Bearer '.$this->user->createToken('test')->plainTextToken];
    }

    /**
     * ملف إكسل حقيقي، بالترويسات التي يكتبها النورس.
     *
     * @param  list<list<string>>  $rows
     * @param  list<string>  $headings
     */
    private function file(
        array $rows,
        array $headings = ['الحالة', 'الكود', 'اسم المستلم'],
        string $sheet = 'الطرود',
    ): UploadedFile {
        $book = new Spreadsheet;
        $work = $book->getActiveSheet();
        $work->setTitle($sheet);
        $work->fromArray($headings, null, 'A1', true);

        foreach ($rows as $index => $row) {
            $work->fromArray($row, null, 'A'.($index + 2), true);
        }

        $path = tempnam(sys_get_temp_dir(), 'settle').'.xlsx';
        (new Xlsx($book))->save($path);

        return new UploadedFile($path, 'report.xlsx', null, null, true);
    }

    /**
     * @return list<string>
     */
    private function row(Order|string $receiver, string $code = '', string $status = 'تم التسوية'): array
    {
        return [$status, $code, $receiver instanceof Order ? (string) $receiver->code : $receiver];
    }

    private function nawris(): TreasuryAccount
    {
        return TreasuryAccount::query()->where('system_code', TreasuryAccount::NAWRIS)->firstOrFail();
    }

    private function defaultOf(AccountKind $kind): TreasuryAccount
    {
        return TreasuryAccount::query()->where('kind', $kind->value)->where('is_default', true)->firstOrFail();
    }

    private function balance(TreasuryAccount $account): string
    {
        return app(TreasuryService::class)->balanceOf($account);
    }

    private function order(string $total, OrderStatus $status = OrderStatus::OutForDelivery): Order
    {
        return Order::factory()->create([
            'status' => $status,
            'items_total' => $total,
            'delivery_price' => '0.00',
            'grand_total' => $total,
        ]);
    }

    /**
     * طرد واحد، بطلبية أو أكثر، سلّمه النورس فنزل مال كل طلبية في عهدته.
     *
     * @param  list<Order>  $orders
     */
    private function deliver(array $orders, ?string $fee = null): NawrisParcel
    {
        $total = '0.00';

        foreach ($orders as $order) {
            $total = bcadd($total, (string) $order->grand_total, 2);
        }

        $first = $orders[0];

        $parcel = NawrisParcel::factory()->create([
            'reference' => 'ref-'.$first->id,
            'code' => 'CODE-'.$first->id,
            'amount_to_collect' => $total,
            'delivery_price_deducted' => '0.00',
        ]);

        foreach ($orders as $order) {
            NawrisParcelOrder::factory()->create([
                'nawris_parcel_id' => $parcel->id,
                'order_id' => $order->id,
                'amount_to_collect' => $order->grand_total,
            ]);
        }

        NawrisWebhookEvent::factory()->processed()->create([
            'nawris_parcel_id' => $parcel->id,
            'payload' => ['to_status_code' => 4, 'order_price' => $total],
            'status_code' => 4,
        ]);

        $this->withHeaders(['Authorization' => 'Bearer '.self::SECRET])->postJson('/api/v1/webhooks/nawris', [
            'remote_order_id' => $parcel->reference,
            'order_code' => $parcel->code,
            'to_status_code' => 7,
            'to_status_text' => 'تم التسليم',
            'order_price' => $total,
        ])->assertOk();

        // بعد الويب هوك: الأجرة علينا (رقم ويب هوكهم ٢)، وهذا ما يكتبه سجلّ طردٍ نقله النورس إلينا.
        if ($fee !== null) {
            $parcel->forceFill(['carrier_fee' => $fee, 'shipment_on_sender' => 2])->save();
        }

        return $parcel->refresh();
    }

    private function delivered(string $total, ?string $fee = null): Order
    {
        $order = $this->order($total);
        $this->deliver([$order], $fee);

        return $order->refresh();
    }

    private function codeOf(Order $order): string
    {
        return 'CODE-'.$order->id;
    }

    private function preview(UploadedFile $file): TestResponse
    {
        return $this->withHeaders($this->headers)->post(self::PREVIEW, ['file' => $file], ['Accept' => 'application/json']);
    }

    /**
     * «تنفيذ» كما يفعل التطبيق: يعاين أولاً، ويعيد البصمة مع ما كتبه الموظف.
     *
     * @param  array<string, mixed>  $body
     */
    private function settle(array $rows, array $body = []): TestResponse
    {
        $preview = $this->preview($this->file($rows))->assertOk();

        return $this->submit($rows, $body + [
            'fingerprint' => $preview->json('data.fingerprint'),
            'received_amount' => $preview->json('data.expected_received'),
        ]);
    }

    /**
     * @param  list<list<string>>  $rows
     * @param  array<string, mixed>  $body
     */
    private function submit(array $rows, array $body): TestResponse
    {
        return $this->withHeaders($this->headers)->post(
            self::STORE,
            ['file' => $this->file($rows)] + $body + ['client_token' => (string) Str::uuid()],
            ['Accept' => 'application/json'],
        );
    }

    // ── المعاينة ──────────────────────────────────────────────────────────────────────────

    public function test_the_preview_says_what_will_happen_and_writes_nothing(): void
    {
        // Arrange
        $ready = $this->delivered('100.00');
        $moved = TreasuryMovement::query()->count();

        // Act
        $response = $this->preview($this->file([$this->row($ready, $this->codeOf($ready))]));

        // Assert
        $response->assertOk()
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.summary.settled_count', 1)
            ->assertJsonPath('data.summary.rejected_count', 0)
            ->assertJsonPath('data.total_held', '100.00')
            ->assertJsonPath('data.expected_received', '100.00')
            ->assertJsonPath('data.lines.0.outcome', 'settled')
            ->assertJsonPath('data.lines.0.order_code', (string) $ready->code)
            ->assertJsonPath('data.lines.0.held_amount', '100.00');

        $this->assertSame(OrderStatus::Delivered, $ready->refresh()->status);
        $this->assertSame($moved, TreasuryMovement::query()->count());
        $this->assertSame(0, NawrisSettlementImport::query()->count());
    }

    public function test_the_total_counts_only_the_orders_that_will_settle(): void
    {
        // Arrange — مال الطلبية الباقي عليها شيء عند النورس، لكنها لن تُسوّى.
        $ready = $this->delivered('100.00');
        $short = $this->delivered('50.00');
        $short->forceFill(['grand_total' => '70.00'])->save();

        // Act
        $response = $this->preview($this->file([$this->row($ready), $this->row($short)]));

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.summary.settled_count', 1)
            ->assertJsonPath('data.summary.rejected_count', 1)
            ->assertJsonPath('data.total_held', '100.00')
            ->assertJsonPath('data.lines.1.reason_code', 'order_has_balance')
            ->assertJsonPath('data.lines.1.held_amount', '0.00');
    }

    /**
     * @return array<string, array{0: OrderStatus, 1: string}>
     */
    public static function notDelivered(): array
    {
        return [
            'still on the road' => [OrderStatus::OutForDelivery, 'order_not_delivered'],
            'came back' => [OrderStatus::ReturnedCourier, 'order_not_delivered'],
            'not even made' => [OrderStatus::New, 'order_not_delivered'],
        ];
    }

    #[DataProvider('notDelivered')]
    public function test_only_a_delivered_order_settles(OrderStatus $status, string $reason): void
    {
        // Arrange
        $order = $this->order('100.00', $status);

        // Act
        $response = $this->preview($this->file([$this->row($order)]));

        // Assert
        $response->assertOk()->assertJsonPath('data.lines.0.reason_code', $reason);
        $this->assertStringContainsString($status->label(), (string) $response->json('data.lines.0.reason'));
    }

    public function test_a_row_nawris_has_not_settled_does_not_move(): void
    {
        // Arrange
        $order = $this->delivered('100.00');

        // Act
        $response = $this->preview($this->file([$this->row($order, status: 'قيد التوصيل')]));

        // Assert
        $response->assertOk()->assertJsonPath('data.lines.0.reason_code', 'status_not_settled_in_file');
    }

    public function test_an_unknown_order_and_a_deleted_one_are_named(): void
    {
        // Arrange
        $deleted = $this->delivered('100.00');
        $deleted->delete();

        // Act
        $response = $this->preview($this->file([$this->row('99999999'), $this->row($deleted)]));

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.lines.0.reason_code', 'order_not_found')
            ->assertJsonPath('data.lines.1.reason_code', 'order_deleted');
    }

    public function test_an_order_with_no_tie_to_nawris_is_not_settled(): void
    {
        // Arrange — طلبية سُلّمت ودُفعت عندنا، وأصاب رقمها عمود المستلم مصادفة.
        $stray = $this->order('100.00', OrderStatus::Delivered);
        $stray->forceFill(['paid_amount' => '100.00'])->save();

        // Act
        $response = $this->preview($this->file([$this->row($stray)]));

        // Assert
        $response->assertOk()->assertJsonPath('data.lines.0.reason_code', 'not_a_nawris_order');
    }

    // ── المستلم ───────────────────────────────────────────────────────────────────────────

    public function test_a_shared_parcel_splits_into_its_orders(): void
    {
        // Arrange
        $first = $this->order('100.00');
        $second = $this->order('50.00');
        $this->deliver([$first, $second]);

        // Act
        $response = $this->preview($this->file([$this->row("{$first->code}+{$second->code}")]));

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.summary.rows_count', 1)
            ->assertJsonPath('data.summary.orders_count', 2)
            ->assertJsonPath('data.summary.settled_count', 2)
            ->assertJsonPath('data.total_held', '150.00')
            ->assertJsonPath('data.lines.0.row_number', 1)
            ->assertJsonPath('data.lines.1.row_number', 1);
    }

    public function test_one_failing_order_in_a_shared_row_does_not_block_its_sibling(): void
    {
        // Arrange
        $good = $this->delivered('100.00');
        $blocked = $this->order('50.00', OrderStatus::New);

        // Act
        $response = $this->settle([$this->row("{$good->code}+{$blocked->code}")]);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.summary.settled_count', 1)
            ->assertJsonPath('data.summary.rejected_count', 1);

        $this->assertSame(OrderStatus::Settled, $good->refresh()->status);
        $this->assertSame(OrderStatus::New, $blocked->refresh()->status);
    }

    public function test_stray_punctuation_is_cleaned_and_arabic_digits_are_read(): void
    {
        // Arrange
        $dotted = $this->delivered('100.00');
        $arabic = $this->delivered('50.00');
        $written = strtr((string) $arabic->code, ['0' => '٠', '1' => '١', '2' => '٢', '3' => '٣', '4' => '٤', '5' => '٥', '6' => '٦', '7' => '٧', '8' => '٨', '9' => '٩']);

        // Act
        $response = $this->preview($this->file([$this->row("{$dotted->code}."), $this->row($written)]));

        // Assert
        $response->assertOk()->assertJsonPath('data.summary.settled_count', 2);
    }

    public function test_letters_are_never_stripped_down_to_a_stray_number(): void
    {
        // Arrange — في بريمولا صارت «ودان(S16)» الرقمَ 16 فسُوّيت طلبية لا علاقة لها بالشحنة.
        $stray = $this->delivered('100.00');

        // Act
        $response = $this->preview($this->file([$this->row("ودان(S{$stray->code})")]));

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.lines.0.reason_code', 'receiver_not_usable')
            ->assertJsonPath('data.lines.0.order_id', null);
    }

    public function test_two_numbers_with_a_space_between_are_not_glued_into_one(): void
    {
        // Arrange
        $first = $this->delivered('100.00');
        $second = $this->delivered('50.00');

        // Act
        $response = $this->preview($this->file([$this->row("{$first->code} {$second->code}")]));

        // Assert
        $response->assertOk()->assertJsonPath('data.lines.0.reason_code', 'receiver_not_usable');
    }

    public function test_a_useless_receiver_falls_back_to_the_parcel_code(): void
    {
        // Arrange
        $first = $this->order('100.00');
        $second = $this->order('50.00');
        $parcel = $this->deliver([$first, $second]);

        // Act
        $response = $this->preview($this->file([$this->row('زبون ما', (string) $parcel->code)]));

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.summary.settled_count', 2)
            ->assertJsonPath('data.lines.0.warnings.0.code', 'matched_by_code');
    }

    public function test_an_empty_receiver_stays_visible_in_the_report(): void
    {
        // Arrange
        $ready = $this->delivered('100.00');

        // Act
        $response = $this->preview($this->file([$this->row(''), $this->row($ready)]));

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.summary.orders_count', 2)
            ->assertJsonPath('data.lines.0.reason_code', 'receiver_not_usable');
    }

    // ── تنبيهات الكود: تمرّ ولا تمنع ──────────────────────────────────────────────────────

    public function test_a_matching_code_and_a_resend_chain_raise_no_warning(): void
    {
        // Arrange
        $plain = $this->delivered('100.00');
        $resent = $this->delivered('50.00');

        // Act
        $response = $this->preview($this->file([
            $this->row($plain, $this->codeOf($plain)),
            $this->row($resent, $this->codeOf($resent).'NN'),
        ]));

        // Assert
        $response->assertOk()->assertJsonPath('data.summary.warnings_count', 0);
    }

    public function test_a_mismatched_code_still_settles_and_names_both_codes(): void
    {
        // Arrange
        $order = $this->delivered('100.00');

        // Act
        $response = $this->preview($this->file([$this->row($order, '4144131')]));

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.lines.0.outcome', 'settled')
            ->assertJsonPath('data.lines.0.warnings.0.code', 'code_mismatch');

        $this->assertStringContainsString($this->codeOf($order), (string) $response->json('data.lines.0.warnings.0.message'));
    }

    public function test_a_foreign_suffix_on_our_code_is_flagged(): void
    {
        // Arrange
        $order = $this->order('100.00');
        $parcel = $this->deliver([$order]);
        $parcel->forceFill(['code' => '4306969'])->save();

        // Act
        $response = $this->preview($this->file([$this->row($order, '4306969R')]));

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.lines.0.outcome', 'settled')
            ->assertJsonPath('data.lines.0.warnings.0.code', 'code_suffix');
    }

    public function test_a_warning_rides_along_with_a_skipped_order(): void
    {
        // Arrange
        $order = $this->delivered('100.00');
        $this->settle([$this->row($order)])->assertCreated();

        // Act
        $response = $this->preview($this->file([$this->row($order, '4144131')]));

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.lines.0.outcome', 'already_settled')
            ->assertJsonPath('data.lines.0.warnings.0.code', 'code_mismatch');
    }

    // ── التنفيذ والمال ────────────────────────────────────────────────────────────────────

    public function test_settling_moves_the_money_and_records_the_batch(): void
    {
        // Arrange
        $order = $this->delivered('100.00');
        $bank = $this->defaultOf(AccountKind::Bank);
        $before = $this->balance($bank);

        // Act
        $response = $this->settle([$this->row($order, $this->codeOf($order))]);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.summary.settled_count', 1)
            ->assertJsonPath('data.received_amount', '100.00')
            ->assertJsonPath('data.items.0.previous_status', 'delivered')
            ->assertJsonPath('data.imported_by.id', $this->user->id);

        $this->assertSame(OrderStatus::Settled, $order->refresh()->status);
        $this->assertSame('0.00', $this->balance($this->nawris()));
        $this->assertSame(bcadd($before, '100.00', 2), $this->balance($bank));

        $import = NawrisSettlementImport::query()->sole();
        $this->assertSame('report.xlsx', $import->file_name);
        $this->assertSame($this->user->id, $import->imported_by);
    }

    public function test_every_order_is_its_own_operation_named_for_the_batch(): void
    {
        // Arrange
        $first = $this->delivered('100.00');
        $second = $this->delivered('50.00');

        // Act
        $response = $this->settle([$this->row($first), $this->row($second)]);

        // Assert
        $response->assertCreated();

        $operations = TreasuryOperation::query()->where('type', OperationType::Settlement->value)->get();
        $this->assertCount(2, $operations);

        foreach ($operations as $operation) {
            $this->assertStringContainsString('دفعة النورس #'.$response->json('data.id'), (string) $operation->notes);
        }
    }

    public function test_money_moved_to_a_picked_account_names_the_batch_too(): void
    {
        // Arrange — دفعة 1236 الحقيقية: مال الطلبية في الكاش لا عند النورس، وكشف الحساب لم يكن
        // يقول إنها من الملف.
        $order = $this->delivered('100.00');
        $cash = TreasuryAccount::factory()->kind(AccountKind::Cash)->create();
        $picked = TreasuryAccount::factory()->kind(AccountKind::Cash)->create(['name' => 'كاش المسوّي']);

        $this->user->givePermissionTo(PermissionName::RecordOrderPayments->value);
        $order->forceFill(['grand_total' => '150.00'])->save();
        $this->withHeaders($this->headers)->post("/api/v1/orders/{$order->id}/payments", [
            'amount' => '50.00',
            'method' => 'cash',
            'treasury_account_id' => $cash->id,
        ], ['Accept' => 'application/json'])->assertCreated();

        TreasurySetting::current()->forceFill(['pick_settlement_accounts' => true])->save();

        // Act
        $response = $this->settle([$this->row($order)], ['fields' => [
            'settlement_cash_account_id' => $picked->id,
            'settlement_bank_account_id' => $this->defaultOf(AccountKind::Bank)->id,
        ]]);

        // Assert
        $response->assertCreated();

        $notes = TreasuryOperation::query()->where('order_id', $order->id)
            ->where('type', OperationType::Settlement->value)->pluck('notes');

        $this->assertNotEmpty($notes);

        foreach ($notes as $note) {
            $this->assertStringContainsString('دفعة النورس #'.$response->json('data.id'), (string) $note);
        }
    }

    public function test_a_single_settlement_names_no_batch(): void
    {
        // Arrange
        $order = $this->delivered('100.00');
        $this->user->givePermissionTo(PermissionName::ViewOrders->value);

        // Act
        $this->withHeaders($this->headers)
            ->postJson("/api/v1/orders/{$order->id}/status", ['status' => 'settled'])
            ->assertOk();

        // Assert
        $notes = TreasuryOperation::query()->where('order_id', $order->id)->pluck('notes');

        foreach ($notes as $note) {
            $this->assertStringNotContainsString('دفعة النورس', (string) $note);
        }
    }

    public function test_one_order_of_a_batch_can_be_taken_back_alone(): void
    {
        // Arrange
        $first = $this->delivered('100.00');
        $second = $this->delivered('50.00');
        $this->settle([$this->row($first), $this->row($second)])->assertCreated();
        $this->user->givePermissionTo(PermissionName::UnsettleOrders->value);

        // Act
        $response = $this->withHeaders($this->headers)->postJson("/api/v1/orders/{$first->id}/unsettle", ['reason' => 'خطأ']);

        // Assert
        $response->assertOk();
        $this->assertSame(OrderStatus::Delivered, $first->refresh()->status);
        $this->assertSame(OrderStatus::Settled, $second->refresh()->status);
        $this->assertSame('100.00', $this->balance($this->nawris()));
    }

    public function test_a_shortfall_is_booked_as_what_nawris_kept_split_by_each_orders_money(): void
    {
        // Arrange
        $large = $this->delivered('300.00');
        $small = $this->delivered('100.00');
        $bank = $this->defaultOf(AccountKind::Bank);
        $before = $this->balance($bank);

        // Act
        $response = $this->settle([$this->row($large), $this->row($small)], [
            'received_amount' => '380.00',
            'difference_reason' => 'عمولة التحويل',
        ]);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.fee_total', '20.00')
            ->assertJsonPath('data.difference_reason', 'عمولة التحويل')
            ->assertJsonPath('data.items.0.fee_amount', '15.00')
            ->assertJsonPath('data.items.1.fee_amount', '5.00');

        $this->assertSame('0.00', $this->balance($this->nawris()));
        $this->assertSame(bcadd($before, '380.00', 2), $this->balance($bank));

        $category = ExpenseCategory::query()->where('code', ExpenseCategory::CARRIER_FEE)->firstOrFail();
        $this->assertSame(2, TreasuryOperation::query()->where('category_id', $category->id)->count());
    }

    public function test_a_split_that_does_not_divide_evenly_still_adds_up(): void
    {
        // Arrange
        $a = $this->delivered('100.00');
        $b = $this->delivered('100.00');
        $c = $this->delivered('100.00');
        $bank = $this->defaultOf(AccountKind::Bank);
        $before = $this->balance($bank);

        // Act
        $response = $this->settle([$this->row($a), $this->row($b), $this->row($c)], [
            'received_amount' => '290.00',
            'difference_reason' => 'عمولة',
        ]);

        // Assert
        $response->assertCreated()->assertJsonPath('data.fee_total', '10.00');

        $fees = array_map('floatval', array_column((array) $response->json('data.items'), 'fee_amount'));
        $this->assertSame(10.0, round(array_sum($fees), 2));
        $this->assertSame(bcadd($before, '290.00', 2), $this->balance($bank));
    }

    public function test_a_known_fee_opens_the_amount_and_needs_no_reason(): void
    {
        // Arrange — الأجرة علينا: عهدته بالمبلغ كاملاً، وتحويله أقل بأجرته.
        $charged = $this->delivered('100.00', fee: '20.00');
        $plain = $this->delivered('50.00');

        // Act
        $preview = $this->preview($this->file([$this->row($charged), $this->row($plain)]));
        $response = $this->settle([$this->row($charged), $this->row($plain)]);

        // Assert
        $preview->assertOk()
            ->assertJsonPath('data.total_held', '150.00')
            ->assertJsonPath('data.known_fees', '20.00')
            ->assertJsonPath('data.expected_received', '130.00');

        $response->assertCreated()
            ->assertJsonPath('data.fee_total', '20.00')
            ->assertJsonPath('data.difference_reason', null);

        $fees = collect($response->json('data.items'))->keyBy('order_id');
        $this->assertSame('20.00', $fees[$charged->id]['fee_amount']);
        $this->assertSame('0.00', $fees[$plain->id]['fee_amount']);
    }

    public function test_a_known_fee_on_a_shared_parcel_is_shared_by_amount(): void
    {
        // Arrange
        $large = $this->order('300.00');
        $small = $this->order('100.00');
        $this->deliver([$large, $small], fee: '20.00');

        // Act
        $response = $this->preview($this->file([$this->row("{$large->code}+{$small->code}")]));

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.known_fees', '20.00')
            ->assertJsonPath('data.lines.0.fee_amount', '15.00')
            ->assertJsonPath('data.lines.1.fee_amount', '5.00');
    }

    public function test_a_fee_we_owe_but_cannot_name_is_flagged(): void
    {
        // Arrange
        $order = $this->order('100.00');
        $parcel = $this->deliver([$order]);
        $parcel->forceFill(['carrier_fee' => null, 'shipment_on_sender' => 2])->save();

        // Act
        $response = $this->preview($this->file([$this->row($order)]));

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.lines.0.outcome', 'settled')
            ->assertJsonPath('data.lines.0.warnings.0.code', 'fee_unknown');
    }

    public function test_money_from_a_driver_on_the_same_order_is_flagged(): void
    {
        // Arrange
        $order = $this->delivered('100.00');
        $driver = TreasuryAccount::factory()->kind(AccountKind::Custody)->create(['name' => 'سائق']);
        $movement = TreasuryMovement::query()->where('order_id', $order->id)->firstOrFail();

        $copy = $movement->replicate();
        $copy->forceFill(['account_id' => $driver->id, 'amount' => '1.00'])->save();

        // Act
        $response = $this->preview($this->file([$this->row($order)]));

        // Assert
        $response->assertOk()->assertJsonPath('data.lines.0.warnings.0.code', 'other_custody');
    }

    public function test_more_than_nawris_holds_for_these_orders_is_refused(): void
    {
        // Arrange — تحويله يشمل طلبية مُتخطّاة، والمبلغ يُكتب لما سيُسوّى وحده.
        $order = $this->delivered('100.00');

        // Act
        $response = $this->settle([$this->row($order)], ['received_amount' => '120.00']);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors(['received_amount']);
        $this->assertSame(OrderStatus::Delivered, $order->refresh()->status);
        $this->assertSame(0, NawrisSettlementImport::query()->count());
        $this->assertSame('100.00', $this->balance($this->nawris()));
    }

    public function test_less_than_held_with_no_reason_is_refused_and_nothing_moves(): void
    {
        // Arrange
        $order = $this->delivered('100.00');

        // Act
        $response = $this->settle([$this->row($order)], ['received_amount' => '90.00']);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors(['difference_reason']);
        $this->assertSame(OrderStatus::Delivered, $order->refresh()->status);
        $this->assertSame('100.00', $this->balance($this->nawris()));
    }

    public function test_the_amount_is_required_when_nawris_holds_money(): void
    {
        // Arrange
        $order = $this->delivered('100.00');
        $rows = [$this->row($order)];
        $fingerprint = $this->preview($this->file($rows))->json('data.fingerprint');

        // Act
        $response = $this->submit($rows, ['fingerprint' => $fingerprint]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors(['received_amount']);
    }

    public function test_an_order_with_nothing_left_at_nawris_settles_without_an_amount(): void
    {
        // Arrange — سُوّيت دفعتها قبل الطلبية (§٢٣)، فمالها وصل ولا عهدة لها.
        $order = $this->delivered('100.00');
        $this->user->givePermissionTo(PermissionName::SettleOrderPayments->value);

        $payment = $order->payments()->sole();

        $this->withHeaders($this->headers)
            ->postJson('/api/v1/order-payments/settle', ['payments' => [['payment_id' => $payment->id]]])
            ->assertOk();

        $rows = [$this->row($order)];
        $preview = $this->preview($this->file($rows));

        // Act
        $response = $this->submit($rows, ['fingerprint' => $preview->json('data.fingerprint')]);

        // Assert
        $preview->assertJsonPath('data.total_held', '0.00');
        $response->assertCreated()->assertJsonPath('data.summary.settled_count', 1);
        $this->assertSame(OrderStatus::Settled, $order->refresh()->status);
    }

    // ── ما لم يصل ماله ───────────────────────────────────────────────────────────────────

    public function test_an_order_left_out_stays_delivered_with_its_money_at_nawris(): void
    {
        // Arrange — النورس عنده 700 ووصل 400: ما لم يصل ماله لا يُسوّى ولا يصير أجرة.
        $paid = $this->delivered('400.00');
        $waiting = $this->delivered('300.00');
        $bank = $this->defaultOf(AccountKind::Bank);
        $before = $this->balance($bank);

        // Act
        $response = $this->settle([$this->row($paid), $this->row($waiting)], [
            'received_amount' => '400.00',
            'left_out' => [$waiting->id],
        ]);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.summary.settled_count', 1)
            ->assertJsonPath('data.summary.left_out_count', 1)
            ->assertJsonPath('data.total_held', '400.00')
            ->assertJsonPath('data.fee_total', '0.00')
            ->assertJsonPath('data.items.1.outcome', 'left_out')
            ->assertJsonPath('data.items.1.held_amount', '300.00');

        $this->assertSame(OrderStatus::Settled, $paid->refresh()->status);
        $this->assertSame(OrderStatus::Delivered, $waiting->refresh()->status);
        $this->assertSame('300.00', $this->balance($this->nawris()));
        $this->assertSame(bcadd($before, '400.00', 2), $this->balance($bank));
    }

    public function test_the_same_report_settles_what_was_left_once_its_money_arrives(): void
    {
        // Arrange
        $paid = $this->delivered('400.00');
        $waiting = $this->delivered('300.00');
        $rows = [$this->row($paid), $this->row($waiting)];

        $this->settle($rows, ['received_amount' => '400.00', 'left_out' => [$waiting->id]])->assertCreated();

        // Act
        $response = $this->settle($rows);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.summary.settled_count', 1)
            ->assertJsonPath('data.summary.skipped_count', 1)
            ->assertJsonPath('data.received_amount', '300.00');

        $this->assertSame(OrderStatus::Settled, $waiting->refresh()->status);
        $this->assertSame('0.00', $this->balance($this->nawris()));
    }

    public function test_leaving_an_order_out_does_not_make_the_preview_stale(): void
    {
        // Arrange — البصمة تقول ما وعد به الملف، والترك قرار الموظف.
        $paid = $this->delivered('100.00');
        $waiting = $this->delivered('50.00');
        $rows = [$this->row($paid), $this->row($waiting)];
        $preview = $this->preview($this->file($rows));

        // Act
        $response = $this->submit($rows, [
            'fingerprint' => $preview->json('data.fingerprint'),
            'received_amount' => '100.00',
            'left_out' => [$waiting->id],
        ]);

        // Assert
        $response->assertCreated();
    }

    public function test_a_shortfall_on_what_is_left_is_still_a_fee_needing_a_reason(): void
    {
        // Arrange
        $paid = $this->delivered('400.00');
        $waiting = $this->delivered('300.00');

        // Act
        $response = $this->settle([$this->row($paid), $this->row($waiting)], [
            'received_amount' => '390.00',
            'left_out' => [$waiting->id],
        ]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors(['difference_reason']);
        $this->assertSame(OrderStatus::Delivered, $paid->refresh()->status);
    }

    public function test_more_than_the_orders_kept_hold_is_refused(): void
    {
        // Arrange
        $paid = $this->delivered('400.00');
        $waiting = $this->delivered('300.00');

        // Act
        $response = $this->settle([$this->row($paid), $this->row($waiting)], [
            'received_amount' => '700.00',
            'left_out' => [$waiting->id],
        ]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors(['received_amount']);
    }

    public function test_a_known_fee_goes_with_the_order_that_was_left(): void
    {
        // Arrange
        $charged = $this->delivered('100.00', fee: '20.00');
        $plain = $this->delivered('50.00');

        // Act
        $response = $this->settle([$this->row($charged), $this->row($plain)], [
            'received_amount' => '50.00',
            'left_out' => [$charged->id],
        ]);

        // Assert
        $response->assertCreated()->assertJsonPath('data.fee_total', '0.00');
        $this->assertSame('100.00', $this->balance($this->nawris()));
    }

    public function test_a_repeated_order_is_left_out_on_every_row(): void
    {
        // Arrange
        $paid = $this->delivered('100.00');
        $waiting = $this->delivered('50.00');

        // Act
        $response = $this->settle([$this->row($paid), $this->row($waiting), $this->row($waiting)], [
            'received_amount' => '100.00',
            'left_out' => [$waiting->id],
        ]);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.items.1.outcome', 'left_out')
            ->assertJsonPath('data.items.2.outcome', 'left_out')
            ->assertJsonPath('data.summary.skipped_count', 0);
    }

    public function test_only_an_order_that_would_settle_can_be_left_out(): void
    {
        // Arrange
        $paid = $this->delivered('100.00');
        $stranger = $this->order('50.00', OrderStatus::New);

        // Act
        $response = $this->settle([$this->row($paid), $this->row($stranger)], [
            'left_out' => [$stranger->id],
        ]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors(['left_out']);
        $this->assertSame(OrderStatus::Delivered, $paid->refresh()->status);
    }

    public function test_leaving_every_order_out_settles_nothing(): void
    {
        // Arrange
        $order = $this->delivered('100.00');

        // Act
        $response = $this->settle([$this->row($order)], ['left_out' => [$order->id]]);

        // Assert
        $response->assertStatus(422);
        $this->assertSame(0, NawrisSettlementImport::query()->count());
    }

    // ── أسئلة الحسابات ───────────────────────────────────────────────────────────────────

    public function test_the_batch_is_asked_where_the_money_landed(): void
    {
        // Arrange
        $order = $this->delivered('100.00');

        // Act
        $response = $this->preview($this->file([$this->row($order)]));

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.fields.0.key', 'settlement_account_id')
            ->assertJsonPath('data.fields.0.type', 'treasury_account');
    }

    public function test_a_named_account_receives_the_money(): void
    {
        // Arrange
        $order = $this->delivered('100.00');
        $bank = TreasuryAccount::factory()->kind(AccountKind::Bank)->create(['name' => 'مصرف الجمهورية']);

        // Act
        $response = $this->settle([$this->row($order)], ['fields' => ['settlement_account_id' => $bank->id]]);

        // Assert
        $response->assertCreated();
        $this->assertSame('100.00', $this->balance($bank));
    }

    public function test_with_the_pick_switch_on_a_kind_must_be_answered(): void
    {
        // Arrange
        $order = $this->delivered('100.00');
        TreasurySetting::current()->forceFill(['pick_settlement_accounts' => true])->save();

        // Act
        $preview = $this->preview($this->file([$this->row($order)]));
        $refused = $this->settle([$this->row($order)]);

        // Assert
        $preview->assertOk()
            ->assertJsonPath('data.fields.0.key', 'settlement_bank_account_id')
            ->assertJsonPath('data.fields.0.required', true);

        $refused->assertStatus(422)->assertJsonValidationErrors(['fields.settlement_bank_account_id']);
        $this->assertSame(OrderStatus::Delivered, $order->refresh()->status);
    }

    public function test_with_the_pick_switch_on_the_answer_is_where_the_money_goes(): void
    {
        // Arrange
        $order = $this->delivered('100.00');
        $bank = TreasuryAccount::factory()->kind(AccountKind::Bank)->create(['name' => 'مصرف الوحدة']);
        TreasurySetting::current()->forceFill(['pick_settlement_accounts' => true])->save();

        // Act
        $response = $this->settle([$this->row($order)], ['fields' => ['settlement_bank_account_id' => $bank->id]]);

        // Assert
        $response->assertCreated();
        $this->assertSame('100.00', $this->balance($bank));
    }

    public function test_an_account_that_was_not_offered_is_refused(): void
    {
        // Arrange
        $order = $this->delivered('100.00');
        TreasurySetting::current()->forceFill(['pick_settlement_accounts' => true])->save();
        $cash = TreasuryAccount::factory()->kind(AccountKind::Cash)->create();

        // Act
        $response = $this->settle([$this->row($order)], ['fields' => ['settlement_bank_account_id' => $cash->id]]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors(['fields.settlement_bank_account_id']);
    }

    public function test_a_field_the_batch_did_not_ask_is_refused(): void
    {
        // Arrange
        $order = $this->delivered('100.00');

        // Act
        $response = $this->settle([$this->row($order)], ['fields' => ['settlement_cash_account_id' => 1]]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors(['fields.settlement_cash_account_id']);
    }

    // ── ما تغيّر، والتكرار ────────────────────────────────────────────────────────────────

    public function test_a_preview_gone_stale_stops_everything(): void
    {
        // Arrange — المعاينة وعدت بطلبيتين، وإحداهما سُوّيت يدوياً قبل الضغط.
        $first = $this->delivered('100.00');
        $second = $this->delivered('50.00');
        $rows = [$this->row($first), $this->row($second)];
        $preview = $this->preview($this->file($rows));

        $second->forceFill(['status' => OrderStatus::Settled])->save();

        // Act
        $response = $this->submit($rows, [
            'fingerprint' => $preview->json('data.fingerprint'),
            'received_amount' => '150.00',
        ]);

        // Assert
        $response->assertStatus(409)->assertJsonPath('status', false);
        $this->assertSame(OrderStatus::Delivered, $first->refresh()->status);
        $this->assertSame(0, NawrisSettlementImport::query()->count());
    }

    public function test_an_order_that_became_ready_after_the_preview_stops_it_too(): void
    {
        // Arrange
        $first = $this->delivered('100.00');
        $late = $this->order('50.00');
        $rows = [$this->row($first), $this->row($late)];
        $preview = $this->preview($this->file($rows));

        $this->deliver([$late]);

        // Act
        $response = $this->submit($rows, [
            'fingerprint' => $preview->json('data.fingerprint'),
            'received_amount' => '100.00',
        ]);

        // Assert
        $response->assertStatus(409);
        $this->assertSame(OrderStatus::Delivered, $first->refresh()->status);
    }

    public function test_the_same_token_twice_is_one_batch(): void
    {
        // Arrange
        $order = $this->delivered('100.00');
        $rows = [$this->row($order)];
        $preview = $this->preview($this->file($rows));
        $body = [
            'fingerprint' => $preview->json('data.fingerprint'),
            'received_amount' => '100.00',
            'client_token' => (string) Str::uuid(),
        ];

        // Act
        $first = $this->submit($rows, $body);
        $second = $this->submit($rows, $body);

        // Assert
        $first->assertCreated();
        $second->assertCreated()->assertJsonPath('data.id', $first->json('data.id'));
        $this->assertSame(1, NawrisSettlementImport::query()->count());
        $this->assertSame(1, TreasuryOperation::query()->where('type', OperationType::Settlement->value)->count());
    }

    public function test_uploading_the_same_report_later_settles_only_what_was_fixed(): void
    {
        // Arrange — تحويل واحد، وطلبية تأخر تسجيلها فسُوّيت في رفعة ثانية.
        $ready = $this->delivered('100.00');
        $late = $this->order('50.00');
        $rows = [$this->row($ready), $this->row($late)];

        $this->settle($rows)->assertCreated()->assertJsonPath('data.summary.rejected_count', 1);
        $this->deliver([$late]);

        // Act
        $response = $this->settle($rows);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.summary.settled_count', 1)
            ->assertJsonPath('data.summary.skipped_count', 1)
            ->assertJsonPath('data.total_held', '50.00');

        $this->assertSame(OrderStatus::Settled, $late->refresh()->status);
        $this->assertSame('0.00', $this->balance($this->nawris()));
    }

    public function test_an_order_repeated_in_the_file_is_settled_once(): void
    {
        // Arrange
        $order = $this->delivered('100.00');

        // Act
        $response = $this->settle([$this->row($order), $this->row($order)]);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.summary.settled_count', 1)
            ->assertJsonPath('data.summary.skipped_count', 1)
            ->assertJsonPath('data.total_held', '100.00');
    }

    public function test_a_file_with_nothing_to_settle_is_refused(): void
    {
        // Arrange
        $rows = [$this->row('99999999')];
        $preview = $this->preview($this->file($rows));

        // Act
        $response = $this->submit($rows, ['fingerprint' => $preview->json('data.fingerprint')]);

        // Assert
        $response->assertStatus(422);
        $this->assertSame(0, NawrisSettlementImport::query()->count());
    }

    public function test_a_failure_in_the_middle_takes_back_the_whole_batch(): void
    {
        // Arrange — الرفض يأتي من `SettleCustody` في الطلبية الثانية، بعد أن سُوّيت الأولى.
        $first = $this->delivered('100.00');
        $second = $this->delivered('50.00');
        $inactive = TreasuryAccount::factory()->kind(AccountKind::Bank)->create(['is_active' => false]);
        $rows = [$this->row($first), $this->row($second)];

        // Act
        $response = $this->settle($rows, ['fields' => ['settlement_account_id' => $inactive->id]]);

        // Assert
        $response->assertStatus(422);
        $this->assertSame(OrderStatus::Delivered, $first->refresh()->status);
        $this->assertSame(OrderStatus::Delivered, $second->refresh()->status);
        $this->assertSame('150.00', $this->balance($this->nawris()));
        $this->assertSame(0, NawrisSettlementImport::query()->count());
    }

    // ── الجرس ─────────────────────────────────────────────────────────────────────────────

    public function test_each_settled_order_says_it_was_part_of_a_batch(): void
    {
        // Arrange
        $order = $this->delivered('100.00');
        Event::fake([OrderStatusChanged::class]);

        // Act
        $this->settle([$this->row($order)])->assertCreated();

        // Assert
        Event::assertDispatched(
            OrderStatusChanged::class,
            fn (OrderStatusChanged $event) => $event->orderId === $order->id && $event->partOfABatch,
        );
    }

    public function test_a_batch_rings_no_bell_per_order(): void
    {
        // Arrange
        $order = $this->order('100.00', OrderStatus::Settled);
        $listener = app(NotifyWhenOrderStatusChanges::class);
        $event = fn (bool $batch) => new OrderStatusChanged((int) $order->id, OrderStatus::Delivered, OrderStatus::Settled, null, $batch);

        // Act
        $listener->handle($event(true));
        $afterBatch = Notification::query()->count();

        $listener->handle($event(false));
        $afterSingle = Notification::query()->count();

        // Assert — والطلبية المفردة ما زالت تُعلَن، فالصمت للدفعة وحدها.
        $this->assertSame(0, $afterBatch);
        $this->assertSame(1, $afterSingle);
    }

    // ── الملف نفسه ────────────────────────────────────────────────────────────────────────

    public function test_the_nawris_report_is_read_as_it_is_with_its_extra_columns(): void
    {
        // Arrange — ترويسات التقرير الحقيقي، وأعمدتنا مبعثرة بينها.
        $order = $this->delivered('100.00');

        $file = $this->file(
            [[$this->codeOf($order), 'تم التسوية', 'مرتجع', (string) $order->code, 'ودان(S16)', '122']],
            ['الكود', 'الحالة', 'نوع المرتجع', 'اسم المستلم', 'المدينة', 'المبلغ المورد'],
        );

        // Act
        $response = $this->preview($file);

        // Assert
        $response->assertOk()->assertJsonPath('data.summary.settled_count', 1);
    }

    public function test_a_sheet_with_another_name_is_found_by_its_headers(): void
    {
        // Arrange
        $order = $this->delivered('100.00');

        // Act
        $response = $this->preview($this->file([$this->row($order)], sheet: 'ورقة1'));

        // Assert
        $response->assertOk()->assertJsonPath('data.summary.settled_count', 1);
    }

    public function test_headers_with_spaces_and_tatweel_still_match(): void
    {
        // Arrange
        $order = $this->delivered('100.00');

        // Act
        $response = $this->preview($this->file([$this->row($order)], ['  الـحـالـة ', 'الكود', 'اسم  المستلم']));

        // Assert
        $response->assertOk()->assertJsonPath('data.summary.settled_count', 1);
    }

    public function test_a_missing_header_is_named(): void
    {
        // Act
        $response = $this->preview($this->file([['تم التسوية', '1']], ['الحالة', 'الكود']));

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors(['file']);
        $this->assertStringContainsString('اسم المستلم', (string) $response->json('errors.file.0'));
    }

    public function test_headers_with_no_rows_are_refused(): void
    {
        // Act
        $response = $this->preview($this->file([]));

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors(['file']);
    }

    public function test_a_corrupt_workbook_is_refused_not_a_crash(): void
    {
        // Arrange — امتداد صحيح ومحتوى لا يُقرأ.
        $path = tempnam(sys_get_temp_dir(), 'bad').'.xlsx';
        file_put_contents($path, "PK\x03\x04 this is not a workbook");
        $file = new UploadedFile($path, 'report.xlsx', 'application/zip', null, true);

        // Act
        $response = $this->withHeaders($this->headers)
            ->post(self::PREVIEW, ['file' => $file], ['Accept' => 'application/json']);

        // Assert
        $response->assertStatus(422);
    }

    public function test_something_that_is_not_excel_is_refused(): void
    {
        // Arrange
        $file = UploadedFile::fake()->create('report.pdf', 10, 'application/pdf');

        // Act
        $response = $this->preview($file);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors(['file']);
    }

    public function test_no_file_at_all_is_refused(): void
    {
        // Act
        $response = $this->withHeaders($this->headers)->postJson(self::PREVIEW, []);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors(['file']);
    }

    /**
     * @return array<string, array{0: array<string, mixed>, 1: string}>
     */
    public static function badSubmissions(): array
    {
        return [
            'no token' => [['fingerprint' => str_repeat('a', 64), 'client_token' => ''], 'client_token'],
            'not a uuid' => [['fingerprint' => str_repeat('a', 64), 'client_token' => 'nope'], 'client_token'],
            'no fingerprint' => [['client_token' => 'b0000000-0000-4000-8000-000000000000', 'fingerprint' => ''], 'fingerprint'],
            'negative amount' => [['fingerprint' => str_repeat('a', 64), 'received_amount' => '-1'], 'received_amount'],
            'reason too long' => [['fingerprint' => str_repeat('a', 64), 'difference_reason' => str_repeat('س', 501)], 'difference_reason'],
        ];
    }

    /**
     * @param  array<string, mixed>  $body
     */
    #[DataProvider('badSubmissions')]
    public function test_a_malformed_submission_is_refused(array $body, string $field): void
    {
        // Act
        $response = $this->submit([$this->row('1')], $body);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors([$field]);
    }

    public function test_the_template_is_a_workbook_the_reader_accepts_and_settles_nothing(): void
    {
        // Act
        $response = $this->withHeaders($this->headers)->get('/api/v1/carrier/settlement-imports/template');

        $path = tempnam(sys_get_temp_dir(), 'tpl').'.xlsx';
        file_put_contents($path, $response->streamedContent());

        $preview = $this->preview(new UploadedFile($path, 'template.xlsx', null, null, true));

        // Assert
        $response->assertOk();
        $this->assertStringContainsString('spreadsheetml', (string) $response->headers->get('content-type'));
        $preview->assertOk()
            ->assertJsonPath('data.summary.settled_count', 0)
            ->assertJsonPath('data.lines.1.reason_code', 'order_not_found');
    }

    // ── الصلاحية ──────────────────────────────────────────────────────────────────────────

    public function test_a_guest_is_refused(): void
    {
        // Act
        $response = $this->postJson(self::PREVIEW, []);

        // Assert
        $response->assertStatus(401);
    }

    public function test_an_employee_without_the_settlement_permission_is_refused_everywhere(): void
    {
        // Arrange
        $order = $this->delivered('100.00');
        $other = User::factory()->create();
        $headers = ['Authorization' => 'Bearer '.$other->createToken('test')->plainTextToken];

        // Act
        $preview = $this->withHeaders($headers)->post(self::PREVIEW, ['file' => $this->file([$this->row($order)])], ['Accept' => 'application/json']);
        $store = $this->withHeaders($headers)->post(self::STORE, ['file' => $this->file([$this->row($order)])], ['Accept' => 'application/json']);
        $template = $this->withHeaders($headers)->getJson('/api/v1/carrier/settlement-imports/template');
        $list = $this->withHeaders($headers)->getJson(self::STORE);

        // Assert
        $preview->assertForbidden();
        $store->assertForbidden();
        $template->assertForbidden();
        $list->assertForbidden();
        $this->assertSame(OrderStatus::Delivered, $order->refresh()->status);
    }

    // ── الدفعات ───────────────────────────────────────────────────────────────────────────

    public function test_past_batches_are_listed_newest_first_without_their_lines(): void
    {
        // Arrange
        $older = $this->settle([$this->row($this->delivered('100.00'))])->json('data.id');
        $newer = $this->settle([$this->row($this->delivered('50.00'))])->json('data.id');

        // Act
        $response = $this->withHeaders($this->headers)->getJson(self::STORE.'?per_page=500');

        // Assert
        $response->assertOk()
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.0.id', $newer)
            ->assertJsonPath('data.1.id', $older)
            ->assertJsonPath('meta.per_page', 100);

        $this->assertArrayNotHasKey('items', (array) $response->json('data.0'));
    }

    public function test_a_batch_opens_with_every_line_and_its_reason(): void
    {
        // Arrange
        $order = $this->delivered('100.00');
        $id = $this->settle([$this->row($order, '4144131'), $this->row('99999999')])->json('data.id');

        // Act
        $response = $this->withHeaders($this->headers)->getJson(self::STORE."/{$id}");

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.summary.settled_count', 1)
            ->assertJsonPath('data.summary.rejected_count', 1)
            ->assertJsonPath('data.items.0.warnings.0.code', 'code_mismatch')
            ->assertJsonPath('data.items.1.reason_code', 'order_not_found')
            ->assertJsonPath('data.items.1.raw_receiver', '99999999');
    }

    public function test_an_unknown_batch_is_not_found(): void
    {
        // Act
        $response = $this->withHeaders($this->headers)->getJson(self::STORE.'/99999');

        // Assert
        $response->assertNotFound();
    }
}
