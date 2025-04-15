import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sencare_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SenCare App End-to-End Tests', () {
    testWidgets('Login and navigate to patient list screen',
        (WidgetTester tester) async {
      // Initialize the app
      app.main();
      await tester.pumpAndSettle();

      // Verify login screen is displayed
      expect(find.text('SenCare'), findsOneWidget);
      expect(find.byType(TextFormField),
          findsNWidgets(2)); // Username and password fields

      // Enter login credentials
      await tester.enterText(find.byType(TextFormField).first, 'test');
      await tester.enterText(find.byType(TextFormField).last, 'test');

      // Tap login button - using a more flexible finder
      await tester.tap(find.text('Login'));

      // Wait for the login processing animation
      await tester.pump(Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Verify we navigated to patient list screen
      expect(find.text('Patient List'), findsOneWidget);
      expect(find.text('Add Patient'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Search field
    });

    testWidgets('Navigate to add patient screen and back',
        (WidgetTester tester) async {
      // Initialize the app
      app.main();
      await tester.pumpAndSettle();

      // Login with test credentials
      await tester.enterText(find.byType(TextFormField).first, 'test');
      await tester.enterText(find.byType(TextFormField).last, 'test');
      await tester.tap(find.text('Login'));
      await tester.pump(Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Verify we're on patient list screen
      expect(find.text('Patient List'), findsOneWidget);

      // Optional debugging - uncomment if needed to see all available text widgets
      // tester.allWidgets.forEach((widget) {
      //   if (widget is Text) {
      //     print('Found Text widget: "${widget.data}"');
      //   }
      // });

      // Tap on Add Patient button - using a more flexible finder
      await tester.tap(find.text('Add Patient'));
      await tester.pumpAndSettle();

      // Verify we're on the Add Patient screen
      // Check for name field which should be in the form
      expect(find.byType(TextFormField), findsAtLeastNWidgets(1));

      // Check if we can find the condition dropdown
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

      // Navigate back without adding a patient
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Verify we're back on the patient list screen
      expect(find.text('Patient List'), findsOneWidget);
    });
  });
}
