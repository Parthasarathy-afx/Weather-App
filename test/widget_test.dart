import 'package:flutter_test/flutter_test.dart';

import 'package:varshaura/main.dart';



void main() {
  testWidgets(
    'VarshAura app loads successfully',
    (WidgetTester tester) async {
      // 🚀 LOAD APP
      await tester.pumpWidget(
        const VarshAura(),
      );

      // ✅ CHECK APP NAME
      expect(
        find.text('VarshAura'),
        findsOneWidget,
      );
    },
  );
}
