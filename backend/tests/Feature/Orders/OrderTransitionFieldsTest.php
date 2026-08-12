<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Customer\Models\Customer;
use App\Domain\Customer\Models\CustomerDesign;
use App\Domain\Delivery\Models\ShippingCompany;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\DTOs\TransitionField;
use App\Domain\Order\Enums\DesignSource;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderDesign;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Support\TransitionFields;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * What each move *asks for*, and what happens when it is given.
 *
 * **The app draws the form from `available_transitions[].fields`.** So a move that needs
 * artwork says so in the same payload that offers it, and adding a field to a move later is a
 * change here rather than an app release. This test is the contract: it pins what is described,
 * that the description and the validation cannot disagree, and that the whole move — the
 * artwork and the status — lands in one transaction or not at all.
 *
 * Arrange - Act - Assert throughout.
 */
class OrderTransitionFieldsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    /**
     * @return array<string, string>
     */
    private function foreman(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo([
            PermissionName::ViewOrders->value,
            PermissionName::ManageOrders->value,
            PermissionName::ManageOrderDesigns->value,
            PermissionName::MoveOrderToDesigning->value,
            PermissionName::MoveOrderToPrinting->value,
            PermissionName::MoveOrderToReady->value,
            PermissionName::MoveOrderToShortage->value,
            PermissionName::CancelOrders->value,
        ]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * Somebody who agrees the money, and nothing else.
     *
     * @return array<string, string>
     */
    private function accountant(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo([
            PermissionName::ViewOrders->value,
            PermissionName::SettleOrders->value,
        ]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * Somebody who sends parcels out.
     *
     * @return array<string, string>
     */
    private function dispatcher(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo([
            PermissionName::ViewOrders->value,
            PermissionName::DispatchOrders->value,
        ]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function show(array $headers, Order $order): TestResponse
    {
        return $this->withHeaders($headers)->getJson("/api/v1/orders/{$order->id}");
    }

    private function move(array $headers, Order $order, OrderStatus $to, array $payload = []): TestResponse
    {
        return $this->withHeaders($headers)->postJson(
            "/api/v1/orders/{$order->id}/status",
            ['status' => $to->value] + $payload,
        );
    }

    /**
     * @return array{0: Order, 1: Customer}
     */
    private function orderNeedingArtwork(): array
    {
        $customer = Customer::factory()->create();
        $order = Order::factory()->forCustomer($customer)->create([
            'design_source' => DesignSource::Customer,
        ]);

        return [$order, $customer];
    }

    /** The one transition out of the list, whatever position the map put it in. */
    private function transition(TestResponse $response, OrderStatus $target): ?array
    {
        $transitions = $response->json('data.available_transitions');

        foreach ($transitions as $transition) {
            if ($transition['status'] === $target->value) {
                return $transition;
            }
        }

        return null;
    }

    // ───────────────────────────── what a move describes ─────────────────────────────

    public function test_moving_to_designing_offers_artwork_without_demanding_it(): void
    {
        // Arrange
        [$order] = $this->orderNeedingArtwork();
        $headers = $this->foreman();

        // Act
        $designing = $this->transition($this->show($headers, $order), OrderStatus::Designing);

        // Assert — the app renders this and nothing it wrote itself. The note is last and comes
        // with every move; the artwork is offered here because this is the move it usually
        // arrives with, and left optional because the queue exists for the orders it has not been
        // drawn for yet.
        $this->assertSame([
            [
                'key' => 'design_ids',
                'type' => 'customer_designs',
                'label' => 'التصاميم',
                'required' => false,
                'multiple' => true,
                'multiline' => false,
                'hint' => 'تُرفع إلى مكتبة العميل ثم تُربط بالطلبية',
                'min' => null,
                'max' => null,
            ],
            [
                'key' => 'reason',
                'type' => 'text',
                'label' => 'ملاحظة',
                'required' => false,
                'multiple' => false,
                'multiline' => true,
                'hint' => 'تُسجَّل في سجل الطلبية',
                'min' => null,
                'max' => null,
            ],
        ], $designing['fields']);
    }

    public function test_even_a_reprint_is_offered_artwork_on_the_way_into_design(): void
    {
        // Arrange — `design_source = none` says whose work the artwork was, which is a question
        // about money. Whether there is a file to look at is a different question.
        $order = Order::factory()->create(['design_source' => DesignSource::None]);
        $headers = $this->foreman();

        // Act
        $designing = $this->transition($this->show($headers, $order), OrderStatus::Designing);

        // Assert — a reprint may never enter design at all; if it does, the field is there for
        // whatever the customer sent, on the same terms as every other order.
        $this->assertSame('design_ids', $designing['fields'][0]['key']);
        $this->assertFalse($designing['fields'][0]['required']);
    }

    public function test_a_new_order_starts_work_or_says_it_cannot_and_is_never_cancelled(): void
    {
        // Arrange
        $order = Order::factory()->create();
        $headers = $this->foreman();

        // Act
        $offered = array_column(
            $this->show($headers, $order)->json('data.available_transitions'),
            'status',
        );

        // Assert — the two ways of starting the job, and «نواقص» for the case where it cannot be
        // started at all. Cancelling is not among them: a job nobody has begun is two taps from
        // being begun, and an ending competed with the moves that matter.
        $this->assertSame(
            [
                OrderStatus::Designing->value,
                OrderStatus::Printing->value,
                OrderStatus::Shortage->value,
            ],
            $offered,
        );
    }

    public function test_an_order_that_already_carries_artwork_is_not_asked_again(): void
    {
        // Arrange
        [$order, $customer] = $this->orderNeedingArtwork();
        $design = CustomerDesign::factory()->for($customer)->create();
        OrderDesign::factory()->for($order)->create(['customer_design_id' => $design->id]);
        $headers = $this->foreman();

        // Act — the correction path: printing back to designing, where versions already exist.
        $designing = $this->transition($this->show($headers, $order), OrderStatus::Designing);

        // Assert — still offered, because another version is normal; no longer demanded.
        $this->assertFalse($designing['fields'][0]['required']);
    }

    public function test_cancelling_asks_for_its_reason_as_a_field(): void
    {
        // Arrange — from printing, because «جديدة» has no cancellation to offer.
        $order = Order::factory()->status(OrderStatus::Printing)->create();
        $headers = $this->foreman();

        // Act
        $cancelled = $this->transition($this->show($headers, $order), OrderStatus::Cancelled);

        // Assert — one way to render every input, instead of a special case written in Dart.
        $this->assertTrue($cancelled['requires_reason']);
        $this->assertSame('reason', $cancelled['fields'][0]['key']);
        $this->assertSame('text', $cancelled['fields'][0]['type']);
        $this->assertTrue($cancelled['fields'][0]['required']);
    }

    public function test_printing_straight_from_new_still_carries_the_artwork(): void
    {
        // Arrange — still «جديدة»: the order never entered the design conversation, and does not
        // need to. The customer brought the file with them.
        [$order] = $this->orderNeedingArtwork();
        $headers = $this->foreman();

        // Act
        $printing = $this->transition($this->show($headers, $order), OrderStatus::Printing);

        // Assert — «جديدة» accepts a version, so the move that leaves it may carry one. This is
        // the whole short path: an agreed file goes on the order and the press starts, without
        // a detour through a status naming work nobody did.
        $this->assertSame(['design_ids', 'reason'], array_column($printing['fields'], 'key'));
        $this->assertFalse($printing['fields'][0]['required']);
    }

    public function test_leaving_design_for_the_press_offers_the_artwork_one_last_time(): void
    {
        // Arrange — the order has been waiting in the designer's queue.
        [$order] = $this->orderNeedingArtwork();
        $order->forceFill(['status' => OrderStatus::Designing])->save();
        $headers = $this->foreman();

        // Act
        $printing = $this->transition($this->show($headers, $order), OrderStatus::Printing);

        // Assert — this is the move the finished artwork arrives with: «قيد التصميم» is the one
        // status that accepts a version, and this is the last moment the order stands in it.
        $this->assertSame(['design_ids', 'reason'], array_column($printing['fields'], 'key'));
        $this->assertFalse($printing['fields'][0]['required']);
    }

    // ──────────────────────── what «جاري التوصيل» asks for ────────────────────────

    public function test_sending_a_parcel_out_names_the_carrier(): void
    {
        // Arrange
        $order = Order::factory()->status(OrderStatus::Ready)->create();
        $headers = $this->dispatcher();

        // Act
        $out = $this->transition($this->show($headers, $order), OrderStatus::OutForDelivery);
        $fields = collect($out['fields']);

        // Assert — the company is compulsory and the driver is not: the company is answerable
        // for the parcel, while the man carrying it is merely useful to be able to ring, and
        // often nobody has his number at the moment it leaves.
        $carrier = $fields->firstWhere('key', 'shipping_company_id');
        $this->assertNotNull($carrier);
        $this->assertSame('shipping_company', $carrier['type']);
        $this->assertTrue($carrier['required']);

        $courier = $fields->firstWhere('key', 'courier_phone');
        $this->assertNotNull($courier);
        $this->assertSame('هاتف المندوب', $courier['label']);
        $this->assertFalse($courier['required']);
    }

    public function test_an_order_the_customer_is_collecting_is_asked_for_no_carrier(): void
    {
        // Arrange — a branch order. The clerk still presses one dispatch button.
        $order = Order::factory()->officePickup()->status(OrderStatus::Ready)->create();
        $headers = $this->dispatcher();

        // Act
        $dispatch = $this->transition($this->show($headers, $order), OrderStatus::OfficePickup);

        // Assert — nobody carries a parcel the customer is coming to fetch. The description
        // resolves the dispatch pair exactly as the move does, so what is asked for and what
        // is accepted cannot disagree.
        $this->assertSame(['reason'], array_column($dispatch['fields'], 'key'));
    }

    public function test_a_parcel_cannot_leave_with_nobody_named(): void
    {
        // Arrange
        $order = Order::factory()->status(OrderStatus::Ready)->create();
        $headers = $this->dispatcher();

        // Act
        $response = $this->move($headers, $order, OrderStatus::OutForDelivery);

        // Assert — a parcel on the road with no carrier recorded is a parcel nobody can chase,
        // and the return chain has nothing to be answered from.
        $response->assertStatus(422)->assertJsonValidationErrors('fields.shipping_company_id');
        $this->assertSame(OrderStatus::Ready, $order->fresh()->status);
    }

    public function test_the_carrier_is_written_down_by_name_as_well_as_by_key(): void
    {
        // Arrange
        $company = ShippingCompany::factory()->create(['name' => 'درب']);
        $order = Order::factory()->status(OrderStatus::Ready)->create();
        $headers = $this->dispatcher();

        // Act
        $response = $this->move($headers, $order, OrderStatus::OutForDelivery, [
            'fields' => ['shipping_company_id' => $company->id, 'courier_phone' => '0913334444'],
        ]);

        // Assert — the key for filtering and for opening the record, the name for what the
        // order said on the day. Renaming the company later must not rewrite this order.
        $response->assertOk();

        $dispatched = $order->fresh();
        $this->assertSame($company->id, $dispatched->shipping_company_id);
        $this->assertSame('درب', $dispatched->shipping_company);
        $this->assertSame('0913334444', $dispatched->courier_phone);

        $company->update(['name' => 'درب للشحن السريع']);
        $this->assertSame('درب', $order->fresh()->shipping_company);
    }

    public function test_a_carrier_removed_from_the_list_cannot_be_chosen(): void
    {
        // Arrange
        $company = ShippingCompany::factory()->create();
        $company->delete();
        $order = Order::factory()->status(OrderStatus::Ready)->create();
        $headers = $this->dispatcher();

        // Act
        $response = $this->move($headers, $order, OrderStatus::OutForDelivery, [
            'fields' => ['shipping_company_id' => $company->id],
        ]);

        // Assert — the rule agrees with the picker: what is not offered is not accepted.
        $response->assertStatus(422)->assertJsonValidationErrors('fields.shipping_company_id');
    }

    // ──────────────────────── what «تم التسوية» asks for ────────────────────────

    public function test_settling_asks_for_the_money_only_if_it_came_back_different(): void
    {
        // Arrange
        $order = Order::factory()->status(OrderStatus::Delivered)->create(['grand_total' => '250.00']);
        $headers = $this->accountant();

        // Act
        $settling = $this->transition($this->show($headers, $order), OrderStatus::Settled);
        $money = collect($settling['fields'])->firstWhere('key', 'collected_amount');

        // Assert — optional, and the invoice total is on screen beside it so the person agreeing
        // the money is not asked to remember what it should have been.
        $this->assertNotNull($money);
        $this->assertFalse($money['required']);
        $this->assertSame('المبلغ المستلم', $money['label']);
        $this->assertStringContainsString('250.00', $money['hint']);
    }

    public function test_a_settlement_that_matches_the_invoice_records_no_amount(): void
    {
        // Arrange
        $order = Order::factory()->status(OrderStatus::Delivered)->create(['grand_total' => '250.00']);
        $headers = $this->accountant();

        // Act — the ordinary case: the money came back and it was the right money.
        $response = $this->move($headers, $order, OrderStatus::Settled);

        // Assert — the column stays null on purpose, so a number in it always means the two
        // disagreed. Filling it with the total would make agreement and discrepancy look alike.
        $response->assertOk()->assertJsonPath('data.status', 'settled');

        $settled = $order->fresh();
        $this->assertNull($settled->collected_amount);
        $this->assertNotNull($settled->settled_at);
    }

    public function test_a_short_settlement_is_written_down_as_what_actually_arrived(): void
    {
        // Arrange
        $order = Order::factory()->status(OrderStatus::Delivered)->create(['grand_total' => '250.00']);
        $headers = $this->accountant();

        // Act
        $response = $this->move($headers, $order, OrderStatus::Settled, [
            'fields' => ['collected_amount' => '230.50', 'reason' => 'المندوب خصم أجرة التوصيل'],
        ]);

        // Assert — the number and the sentence explaining it, kept together.
        $response->assertOk();
        $this->assertSame('230.50', $order->fresh()->collected_amount);
        $this->assertDatabaseHas('order_status_transitions', [
            'order_id' => $order->id,
            'to_status' => OrderStatus::Settled->value,
            'reason' => 'المندوب خصم أجرة التوصيل',
        ]);
    }

    public function test_settling_is_its_own_grant(): void
    {
        // Arrange — a foreman runs the shop floor and touches no money.
        $order = Order::factory()->status(OrderStatus::Delivered)->create();

        // Act
        $response = $this->move($this->foreman(), $order, OrderStatus::Settled);

        // Assert
        $response->assertStatus(403);
        $this->assertSame(OrderStatus::Delivered, $order->fresh()->status);
    }

    // ─────────────────────── the note that travels with every move ───────────────────────

    public function test_every_move_can_carry_a_note(): void
    {
        // Arrange — one order sitting where several different moves are offered at once.
        $order = Order::factory()->status(OrderStatus::Printing)->create();
        OrderItem::factory()->for($order)->create();
        $headers = $this->foreman();

        // Act
        $transitions = $this->show($headers, $order)->json('data.available_transitions');

        // Assert — no move is without one. Staff explain what they did in the moment they do it,
        // and a note nobody could leave is a note that ends up in a phone call instead.
        $this->assertNotEmpty($transitions);

        foreach ($transitions as $transition) {
            $note = collect($transition['fields'])->firstWhere('key', 'reason');

            $this->assertNotNull($note, "«{$transition['label']}» carries no note field");
            $this->assertTrue($note['multiline'], 'a note is a sentence, not a word');
        }
    }

    public function test_no_move_anywhere_in_the_machine_is_without_its_note(): void
    {
        // Arrange — the whole machine, not one order in one status: every status the business
        // has, and every move it is allowed to make from there. A line apiece, because two of
        // those moves ask their questions per line.
        $checked = 0;

        // Act & Assert — walked pair by pair, because the rule is about the pair. The backward
        // moves are the point of doing it this way: «قيد الطباعة» back to «قيد التصميم» is
        // exactly the move somebody needs to explain, and a rule pinned only on the way forward
        // would have let that one through.
        foreach (OrderStatus::cases() as $from) {
            $order = Order::factory()->status($from)->create();
            OrderItem::factory()->for($order)->create();

            foreach ($from->allowedNext() as $target) {
                $note = collect(TransitionFields::for($order->fresh(), $target))
                    ->first(fn (TransitionField $field) => $field->key === 'reason');

                $move = "{$from->label()} ← {$target->label()}";

                $this->assertNotNull($note, "«{$move}» carries no note field");
                $this->assertTrue($note->multiline, "«{$move}»: a note is a sentence, not a word");

                // Optional everywhere, and demanded in exactly one place. Writing an order off
                // is the only move that owes an explanation; asking for one each time would
                // fill the timeline with «تمام».
                $this->assertSame(
                    $target === OrderStatus::Cancelled,
                    $note->required,
                    "«{$move}» asks for the note on the wrong terms",
                );

                $checked++;
            }
        }

        // The walk itself has to have happened — a machine that offered nothing would have
        // passed every assertion above without making one.
        $this->assertGreaterThan(20, $checked);
    }

    public function test_only_writing_an_order_off_turns_that_note_into_an_explanation(): void
    {
        // Arrange
        $order = Order::factory()->status(OrderStatus::Printing)->create();
        $headers = $this->foreman();

        // Act
        $shown = $this->show($headers, $order);
        $cancelling = $this->transition($shown, OrderStatus::Cancelled);
        $designing = $this->transition($shown, OrderStatus::Designing);

        $cancelNote = collect($cancelling['fields'])->firstWhere('key', 'reason');
        $designNote = collect($designing['fields'])->firstWhere('key', 'reason');

        // Assert — the same field, renamed and made compulsory exactly where an explanation is
        // owed. One input in the app, one column in the timeline.
        $this->assertSame('السبب', $cancelNote['label']);
        $this->assertTrue($cancelNote['required']);

        $this->assertSame('ملاحظة', $designNote['label']);
        $this->assertFalse($designNote['required']);
    }

    public function test_a_note_left_with_an_ordinary_move_is_kept_on_the_timeline(): void
    {
        // Arrange
        $order = Order::factory()->status(OrderStatus::Printing)->create();
        $headers = $this->foreman();

        // Act
        $response = $this->move($headers, $order, OrderStatus::Ready, [
            'fields' => ['reason' => 'الكمية طلعت زيادة ٢٠ كيس'],
        ]);

        // Assert — it lands in the same column a cancellation's reason does, so the order's
        // history has one place to read from rather than two.
        $response->assertOk();
        $this->assertDatabaseHas('order_status_transitions', [
            'order_id' => $order->id,
            'to_status' => OrderStatus::Ready->value,
            'reason' => 'الكمية طلعت زيادة ٢٠ كيس',
        ]);

        // And it stays a note about the move, not a reason the order was written off.
        $this->assertNull($order->fresh()->cancellation_reason);
    }

    // ───────────────────────────── what a move accepts ─────────────────────────────

    public function test_an_order_waits_in_design_before_there_is_anything_to_look_at(): void
    {
        // Arrange — the ordinary case: the customer wants something drawn, and nobody has drawn
        // it yet. There is nothing to attach.
        [$order] = $this->orderNeedingArtwork();
        $headers = $this->foreman();

        // Act
        $response = $this->move($headers, $order, OrderStatus::Designing);

        // Assert — this is what «قيد التصميم» is *for*: the order sits in the designer's queue
        // until the work exists. Demanding the file on the way in would have made the status
        // unreachable exactly when it is needed.
        $response->assertOk()->assertJsonPath('data.status', 'designing');
        $this->assertSame(0, $order->designs()->count());
    }

    public function test_the_artwork_and_the_move_arrive_together(): void
    {
        // Arrange
        [$order, $customer] = $this->orderNeedingArtwork();
        $designs = CustomerDesign::factory()->count(2)->for($customer)->create();
        $headers = $this->foreman();

        // Act
        $response = $this->move($headers, $order, OrderStatus::Designing, [
            'fields' => ['design_ids' => $designs->pluck('id')->all()],
        ]);

        // Assert — one request: the versions are numbered and the order has moved.
        $response->assertOk()->assertJsonPath('data.status', 'designing');
        $this->assertSame([1, 2], $order->designs()->pluck('version')->sort()->values()->all());
    }

    public function test_artwork_belonging_to_somebody_else_moves_nothing(): void
    {
        // Arrange
        [$order] = $this->orderNeedingArtwork();
        $stranger = CustomerDesign::factory()->create();
        $headers = $this->foreman();

        // Act
        $response = $this->move($headers, $order, OrderStatus::Designing, [
            'fields' => ['design_ids' => [$stranger->id]],
        ]);

        // Assert — the whole move rolls back: no half-designed order, no orphan version.
        $response->assertStatus(422);
        $this->assertSame(OrderStatus::New, $order->fresh()->status);
        $this->assertSame(0, $order->designs()->count());
    }

    public function test_a_field_the_move_never_offered_is_refused(): void
    {
        // Arrange
        $order = Order::factory()->create();
        $headers = $this->foreman();

        // Act
        $response = $this->move($headers, $order, OrderStatus::Printing, [
            'fields' => ['courier_name' => 'أحمد'],
        ]);

        // Assert — silently dropping it would teach a client that it worked.
        $response->assertStatus(422)->assertJsonValidationErrors('fields');
    }

    public function test_the_reason_may_arrive_inside_the_fields(): void
    {
        // Arrange
        $order = Order::factory()->status(OrderStatus::Printing)->create();
        $headers = $this->foreman();

        // Act — the app sends every input the same way, including this one.
        $response = $this->move($headers, $order, OrderStatus::Cancelled, [
            'fields' => ['reason' => 'العميل غيّر رأيه'],
        ]);

        // Assert
        $response->assertOk()->assertJsonPath('data.status', 'cancelled');
        $this->assertSame('العميل غيّر رأيه', $order->fresh()->cancellation_reason);
    }

    // ───────────────────────── what «قيد الطباعة» may and may not do ─────────────────────────

    public function test_the_artwork_is_settled_once_printing_starts(): void
    {
        // Arrange
        [$order, $customer] = $this->orderNeedingArtwork();
        $design = CustomerDesign::factory()->for($customer)->create();
        $order->forceFill(['status' => OrderStatus::Printing])->save();
        $headers = $this->foreman();

        // Act — adding a version straight onto an order that is being printed.
        $response = $this->withHeaders($headers)->postJson(
            "/api/v1/orders/{$order->id}/designs",
            ['customer_design_id' => $design->id],
        );

        // Assert — the press is running against the approved file. Changing the artwork means
        // sending the order back to «قيد التصميم», which is a move somebody makes on purpose.
        $response->assertStatus(422);
        $this->assertSame(0, $order->designs()->count());
    }

    public function test_sending_a_printing_order_back_to_design_still_carries_artwork(): void
    {
        // Arrange — the correction path, and the one case where a version arrives *while* the
        // order is still in a status that forbids adding one.
        [$order, $customer] = $this->orderNeedingArtwork();
        $design = CustomerDesign::factory()->for($customer)->create();
        $order->forceFill(['status' => OrderStatus::Printing])->save();
        $headers = $this->foreman();

        // Act
        $response = $this->move($headers, $order, OrderStatus::Designing, [
            'fields' => ['design_ids' => [$design->id]],
        ]);

        // Assert — the move and the version land together: the order is in design by the time
        // the artwork is attached, which is what makes the attachment legal.
        $response->assertOk()->assertJsonPath('data.status', 'designing');
        $this->assertSame(1, $order->designs()->count());
    }

    public function test_the_artwork_is_attached_while_the_order_is_still_in_design(): void
    {
        // Arrange — the whole point of the waiting: the designer finished, and sends the order
        // to the press with the file in the same hand.
        [$order, $customer] = $this->orderNeedingArtwork();
        $design = CustomerDesign::factory()->for($customer)->create();
        $order->forceFill(['status' => OrderStatus::Designing])->save();
        $headers = $this->foreman();

        // Act
        $response = $this->move($headers, $order, OrderStatus::Printing, [
            'fields' => ['design_ids' => [$design->id]],
        ]);

        // Assert — the mirror image of the correction path: there the status is written first
        // because the *new* status is the one that accepts artwork, here it is written last for
        // the same reason about the old one. Either way the version lands.
        $response->assertOk()->assertJsonPath('data.status', 'printing');
        $this->assertSame(1, $order->designs()->count());
    }

    public function test_the_order_says_which_of_the_two_may_still_be_changed(): void
    {
        // Arrange
        [$order] = $this->orderNeedingArtwork();
        $order->forceFill(['status' => OrderStatus::Printing])->save();
        $headers = $this->foreman();

        // Act
        $response = $this->show($headers, $order);

        // Assert — the app draws each section from these rather than keeping its own copy of
        // where the two lines fall, which are deliberately different lines.
        $response->assertJsonPath('data.items_are_editable', true)
            ->assertJsonPath('data.designs_are_editable', false);
    }

    // ─────────────────────────── the weight «جاهزة» asks for ───────────────────────────

    /** An order priced the way most are: by the piece. */
    private function orderBeingPrinted(PricingUnit $unit = PricingUnit::Piece): Order
    {
        $order = Order::factory()->status(OrderStatus::Printing)->create();
        OrderItem::factory()->for($order)->create(['pricing_unit' => $unit]);

        return $order;
    }

    public function test_finishing_a_run_asks_for_its_weight(): void
    {
        // Arrange
        $order = $this->orderBeingPrinted();
        $headers = $this->foreman();

        // Act
        $ready = $this->transition($this->show($headers, $order), OrderStatus::Ready);

        // Assert — a number, and the app draws a numeric field for it because the description
        // says `number` and not because anybody wrote «الوزن» into a screen.
        $this->assertSame('weight_kg', $ready['fields'][0]['key']);
        $this->assertSame('number', $ready['fields'][0]['type']);
    }

    public function test_bags_sold_by_the_piece_may_be_weighed_or_not(): void
    {
        // Arrange
        $order = $this->orderBeingPrinted();
        $headers = $this->foreman();

        // Act
        $ready = $this->transition($this->show($headers, $order), OrderStatus::Ready);

        // Assert — the weight is for the courier, and a run can be shelved before anybody has
        // put it on the scale.
        $this->assertFalse($ready['fields'][0]['required']);
    }

    public function test_bags_sold_by_the_kilo_cannot_be_shelved_unweighed(): void
    {
        // Arrange
        $order = $this->orderBeingPrinted(PricingUnit::Kilogram);
        $headers = $this->foreman();

        // Act
        $ready = $this->transition($this->show($headers, $order), OrderStatus::Ready);

        // Assert — the scale is the invoice for these: without a weight there is no answer to
        // what was sold.
        $this->assertTrue($ready['fields'][0]['required']);
    }

    public function test_a_kilo_order_is_refused_without_a_weight(): void
    {
        // Arrange
        $order = $this->orderBeingPrinted(PricingUnit::Kilogram);
        $headers = $this->foreman();

        // Act
        $response = $this->move($headers, $order, OrderStatus::Ready);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('fields.weight_kg');
        $this->assertSame(OrderStatus::Printing, $order->fresh()->status);
    }

    public function test_the_weight_lands_on_the_order_with_the_move(): void
    {
        // Arrange
        $order = $this->orderBeingPrinted(PricingUnit::Kilogram);
        $headers = $this->foreman();

        // Act
        $response = $this->move($headers, $order, OrderStatus::Ready, [
            'fields' => ['weight_kg' => 12.5],
        ]);

        // Assert — one request, and the number is on the order rather than in a note somebody
        // has to read.
        $response->assertOk()->assertJsonPath('data.status', 'ready');
        $this->assertSame('12.500', $order->fresh()->weight_kg);
    }

    public function test_a_weight_that_is_not_a_number_is_refused(): void
    {
        // Arrange
        $order = $this->orderBeingPrinted();
        $headers = $this->foreman();

        // Act
        $response = $this->move($headers, $order, OrderStatus::Ready, [
            'fields' => ['weight_kg' => 'ثقيلة'],
        ]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('fields.weight_kg');
    }

    // ────────────────────── what «نواقص» asks for, line by line ──────────────────────

    public function test_a_shortage_is_asked_for_line_by_line(): void
    {
        // Arrange — two sizes on one order, priced differently. «نواقص» is offered off «جديدة»,
        // which is the only status it is reachable from.
        $order = Order::factory()->create();
        $pieces = OrderItem::factory()->for($order)->create([
            'variant_label' => '30*30',
            'pricing_unit' => PricingUnit::Piece,
            'quantity' => '100',
        ]);
        $kilos = OrderItem::factory()->for($order)->create([
            'variant_label' => 'سادة',
            'pricing_unit' => PricingUnit::Kilogram,
            'quantity' => '50',
        ]);
        $headers = $this->foreman();

        // Act
        $shortage = $this->transition($this->show($headers, $order), OrderStatus::Shortage);
        $keys = array_column($shortage['fields'], 'key');

        // Assert — «كم ناقص» is meaningless for an order; it is a question about a size. Each
        // line asks in its own unit, and the app draws them without knowing what a line is.
        $this->assertSame(["shortage_{$pieces->id}", "shortage_{$kilos->id}", 'reason'], $keys);
        $this->assertStringContainsString('30*30', $shortage['fields'][0]['label']);
        $this->assertStringContainsString('قطعة', $shortage['fields'][0]['label']);
        $this->assertStringContainsString('كيلوغرام', $shortage['fields'][1]['label']);
    }

    public function test_a_line_cannot_be_shorter_than_it_was_ordered(): void
    {
        // Arrange
        $order = Order::factory()->create();
        $item = OrderItem::factory()->for($order)->create(['quantity' => '100']);
        $headers = $this->foreman();

        // Act
        $response = $this->move($headers, $order, OrderStatus::Shortage, [
            'fields' => ["shortage_{$item->id}" => 150],
        ]);

        // Assert — «ناقص ١٥٠ من ١٠٠» is not a shortage, it is a typo.
        $response->assertStatus(422)->assertJsonValidationErrors("fields.shortage_{$item->id}");
    }

    public function test_a_shortage_with_nothing_missing_is_refused(): void
    {
        // Arrange
        $order = Order::factory()->create();
        OrderItem::factory()->for($order)->create(['quantity' => '100']);
        $headers = $this->foreman();

        // Act — the status chosen, and every line left alone.
        $response = $this->move($headers, $order, OrderStatus::Shortage);

        // Assert — a «نواقص» that does not say what is missing is a status nobody can act on.
        $response->assertStatus(422);
        $this->assertSame(OrderStatus::New, $order->fresh()->status);
    }

    public function test_what_is_missing_is_recorded_against_the_size_it_is_missing_from(): void
    {
        // Arrange
        $order = Order::factory()->create();
        $short = OrderItem::factory()->for($order)->create([
            'variant_label' => '30*30',
            'quantity' => '100',
        ]);
        $whole = OrderItem::factory()->for($order)->create([
            'variant_label' => '45*50',
            'quantity' => '80',
        ]);
        $headers = $this->foreman();

        // Act
        $response = $this->move($headers, $order, OrderStatus::Shortage, [
            'fields' => ["shortage_{$short->id}" => 40],
        ]);

        // Assert — the number sits on the line it belongs to, so «ما الناقص ومن أي مقاس» is
        // answered by the order itself rather than by reading a sentence somebody typed.
        $response->assertOk()->assertJsonPath('data.status', 'shortage');
        $this->assertSame('40.000', $short->fresh()->shortage_quantity);
        $this->assertNull($whole->fresh()->shortage_quantity);
    }
}
