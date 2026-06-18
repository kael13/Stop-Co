import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App loads placeholder test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Text('Stop-Co')),
    );
    expect(find.text('Stop-Co'), findsOneWidget);
  });
}
