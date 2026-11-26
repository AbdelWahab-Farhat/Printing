<?php

return [

    /*
    |---------------------------------------------------------------------------
    | Automatic ticket when an order enters «قيد التصميم»
    |---------------------------------------------------------------------------
    |
    | When on, an order moved into «قيد التصميم» with no open design ticket gets one by itself
    | (`OpenAutomaticDesignTicket`). Built 2026-11-18, switched off by the owner on 2026-11-26:
    | the ticket it opened carried no real brief, so tickets are opened by a person again. Kept
    | behind this switch so it can come back without new code.
    |
    | Off or on, tickets the system already opened are still closed when the order moves on or
    | is cancelled (`CancelAutomaticDesignTickets`).
    */
    'auto_open_on_designing' => (bool) env('DESIGN_TICKETS_AUTO_OPEN_ON_DESIGNING', false),

];
