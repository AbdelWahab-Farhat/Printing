<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// The customer app's privacy policy: the URL the App Store and Google Play listings point at.
// Section 9 is reachable as /privacy#delete-account, for Play's account-deletion field.
Route::view('/privacy', 'privacy')->name('privacy');
