<?php

return [

    /*
    |---------------------------------------------------------------------------
    | Design fee filled from the designer's pay
    |---------------------------------------------------------------------------
    |
    | When a design ticket on an order is approved and nobody set the order's design fee, the fee
    | becomes what the designers of its approved tickets are paid (ORDER-DESIGN-FEE.md, decision 5).
    | Off leaves the fee alone: it stays whatever a person set, zero when nobody did, and nobody is
    | told to price it. The designer is paid either way.
    |
    | `false`, `0`, `off` and `no` all turn it off. Unset means on.
    */
    'design_fee' => [
        'fill_from_designer_pay' => filter_var(
            env('ORDERS_FILL_DESIGN_FEE_FROM_PAY', true),
            FILTER_VALIDATE_BOOLEAN,
        ),
    ],

];
