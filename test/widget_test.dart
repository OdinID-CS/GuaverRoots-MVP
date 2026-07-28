import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guaverroots/main.dart';

void main() {
  testWidgets('Home screen appears after splash delay', (WidgetTester tester) async {
    await tester.pumpWidget(const GuaverRootsApp(cameras: []));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('Scan Crop'), findsOneWidget);
    expect(find.text('Area Scan'), findsOneWidget);
    expect(find.text('Farm History'), findsOneWidget);
    expect(find.text('Farm Dashboard'), findsOneWidget);
  });

  testWidgets('History screen opens from home', (WidgetTester tester) async {
    await tester.pumpWidget(const GuaverRootsApp(cameras: []));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await tester.tap(find.text('Farm History'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Farm History'), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);
  });

  testWidgets('Area scan screen opens from home', (WidgetTester tester) async {
    await tester.pumpWidget(const GuaverRootsApp(cameras: []));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await tester.tap(find.text('Area Scan'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Area Scan'), findsOneWidget);
  });

  testWidgets('Dashboard screen opens from home', (WidgetTester tester) async {
    await tester.pumpWidget(const GuaverRootsApp(cameras: []));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await tester.tap(find.text('Farm Dashboard'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Farm Dashboard'), findsOneWidget);
  });
}
