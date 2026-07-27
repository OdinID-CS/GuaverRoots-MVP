import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guaverroots/main.dart';

void main() {
  testWidgets('Home screen appears after splash delay', (WidgetTester tester) async {
    await tester.pumpWidget(const GuaverRootsApp(cameras: []));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Scan Crop'), findsOneWidget);
    expect(find.text('Area Scan'), findsOneWidget);
    expect(find.text('Farm History'), findsOneWidget);
  });

  testWidgets('History screen opens from home', (WidgetTester tester) async {
    await tester.pumpWidget(const GuaverRootsApp(cameras: []));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Farm History'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Farm History'), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);
  });

  testWidgets('Area scan screen opens from home', (WidgetTester tester) async {
    await tester.pumpWidget(const GuaverRootsApp(cameras: []));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Area Scan'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Area Scan'), findsOneWidget);
  });

  testWidgets('Scan screen opens from home', (WidgetTester tester) async {
    await tester.pumpWidget(const GuaverRootsApp(cameras: []));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Scan Crop'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Scan Crop'), findsOneWidget);
  });
}
