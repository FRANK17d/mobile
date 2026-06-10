import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toke_plus/app/app.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TokeApp()));

    // Verify the app renders without crashing
    expect(find.byType(MaterialApp), findsOneWidget);

    // Let splash startup async work finish so no timer is left pending.
    await tester.pump(const Duration(seconds: 3));
  });
}
