import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/core/utils/app_icons.dart';

/// The icons follow the device: Material on Android, Cupertino on iOS.
///
/// Arrange - Act - Assert throughout.
void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('an Android device is given the Material set', () {
    // Arrange
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    // Act
    final home = AppIcons.home;

    // Assert
    expect(AppIcons.isCupertino, isFalse);
    expect(home, Icons.home_rounded);
  });

  test('an iPhone is given the Cupertino set', () {
    // Arrange
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    // Act
    final home = AppIcons.home;

    // Assert
    expect(AppIcons.isCupertino, isTrue);
    expect(home, CupertinoIcons.house_fill);
  });

  test('macOS counts as Cupertino, and every other platform as Material', () {
    // Arrange
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    // Act
    final onMac = AppIcons.isCupertino;
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final onLinux = AppIcons.isCupertino;

    // Assert
    expect(onMac, isTrue);
    expect(onLinux, isFalse);
  });

  test('every name resolves on both platforms', () {
    // Arrange — read through one accessor each, so a name that resolves on Android but throws
    // on iOS (or vice versa) fails here rather than on somebody's phone.
    IconData readAll() => [
      AppIcons.home,
      AppIcons.customers,
      AppIcons.warehouse,
      AppIcons.products,
      AppIcons.menu,
      AppIcons.back,
      AppIcons.forward,
      AppIcons.addCustomer,
      AppIcons.copy,
      AppIcons.refresh,
      AppIcons.logout,
      AppIcons.orders,
      AppIcons.today,
      AppIcons.month,
      AppIcons.city,
      AppIcons.officePickup,
      AppIcons.employees,
      AppIcons.addEmployee,
      AppIcons.roles,
      AppIcons.adminRole,
      AppIcons.mapPin,
      AppIcons.person,
      AppIcons.phone,
      AppIcons.email,
      AppIcons.password,
      AppIcons.passwordVisible,
      AppIcons.passwordHidden,
      AppIcons.search,
      AppIcons.error,
      AppIcons.designs,
      AppIcons.document,
      AppIcons.photos,
      AppIcons.camera,
      AppIcons.pdf,
      AppIcons.openExternal,
      AppIcons.statusChange,
      AppIcons.empty,
    ].last;

    // Act
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final android = readAll();
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final ios = readAll();

    // Assert — the two sets are genuinely different, not one family answering both.
    expect(android, isNot(ios));
  });
}
