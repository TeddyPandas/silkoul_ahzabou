import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silkoul_ahzabou/widgets/finish_task_dialog.dart';

void main() {
  testWidgets('FinishTaskDialog calculates returned to pool correctly',
      (WidgetTester tester) async {
    // Scenario:
    // Subscribed Quantity: 100
    // Already Completed: 0
    // User enters: 50
    // Expect: Returned to pool = 50

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FinishTaskDialog(
            taskName: 'Test Task',
            subscribedQuantity: 100,
            currentCompletedQuantity: 0,
          ),
        ),
      ),
    );

    // Verify initial state
    expect(find.text('Terminer la tâche'), findsOneWidget);
    expect(find.text('100'), findsAtLeastNWidgets(1)); // Initial value in text field

    // Find TextField and enter 50
    final textField = find.byType(TextFormField);
    await tester.enterText(textField, '50');
    await tester.pumpAndSettle();

    // Verify "Returned to pool" message
    // Logic: 100 subscribed - 0 previous - 50 current = 50 returned
    expect(find.text('50 unité(s) seront retournées au pool global'), findsOneWidget);

    // Tap confirm
    final confirmButton = find.text('Confirmer');
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    // Note: We can't easily check the Navigator.pop result here without a wrapper,
    // but the presence of the correct message confirms the internal logic calculation.
  });

  testWidgets('FinishTaskDialog handles full completion correctly',
      (WidgetTester tester) async {
    // Scenario:
    // Subscribed Quantity: 100
    // User enters: 100
    // Expect: Nothing returned to pool

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FinishTaskDialog(
            taskName: 'Test Task',
            subscribedQuantity: 100,
            currentCompletedQuantity: 0,
          ),
        ),
      ),
    );

    // Find TextField and enter 100
    final textField = find.byType(TextFormField);
    await tester.enterText(textField, '100');
    await tester.pumpAndSettle();

    // Verify success message
    expect(find.text('Tâche complète ! Rien ne sera retourné.'), findsOneWidget);
  });

   testWidgets('FinishTaskDialog handles complicated history correctly',
      (WidgetTester tester) async {
    // Scenario:
    // Subscribed: 100
    // Previously Completed: 20
    // Remaining Pledge: 80
    // User enters: 30
    // Expect: Returned = 100 - (20 + 30) = 50

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FinishTaskDialog(
            taskName: 'Test Task',
            subscribedQuantity: 100,
            currentCompletedQuantity: 20,
          ),
        ),
      ),
    );

    // Verify "New Pledge" info
    // Should show 80 (100 - 20)
    // Note: It appears in the Info Row AND the Text Field initially
    expect(find.text('80'), findsAtLeastNWidgets(1)); 

    // Find TextField and enter 30
    final textField = find.byType(TextFormField);
    await tester.enterText(textField, '30');
    await tester.pumpAndSettle();

    // Verify "Returned to pool" message
    // 100 - (20 + 30) = 50
    expect(find.text('50 unité(s) seront retournées au pool global'), findsOneWidget);
  });
}
