// Basic smoke test for the FoodSaver app.
//
// This replaces the default Flutter counter-app template test, which
// referenced a `MyApp` widget that doesn't exist in this project (the
// real root widget is `FoodSaverApp`) and would fail to compile.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodsaver/main.dart';

void main() {
  testWidgets('App boots and shows the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FoodSaverApp());

    // The splash screen should render immediately on launch.
    expect(find.text('FoodSaver'), findsOneWidget);
    expect(find.byIcon(Icons.eco), findsOneWidget);
  });
}
