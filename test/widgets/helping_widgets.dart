import 'package:churchdata/views/form_widgets/password_field.dart';
import 'package:churchdata/views/form_widgets/tapable_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../globals.dart';
import '../main.dart';

Future<void> main() async {
  await initTests();

  group('Helping widgets', () {
    group('Tapable Form Field', () {
      testWidgets('Label', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Scaffold(
              body: TapableFormField<String>(
                initialValue: 'initialValue',
                labelText: 'some label',
                onTap: (state) {},
                builder: (context, state) {
                  return null;
                },
              ),
            ),
          ),
        );

        expect(find.text('some label'), findsOneWidget);
      });

      testWidgets('Decoration', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Scaffold(
              body: TapableFormField<String>(
                initialValue: 'initialValue',
                decoration: (context, state) =>
                    const InputDecoration(labelText: 'Some label'),
                onTap: (state) {},
                builder: (context, state) {
                  return null;
                },
              ),
            ),
          ),
        );

        expect(find.text('Some label'), findsOneWidget);
      });

      testWidgets('Initial value', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Scaffold(
              body: TapableFormField<String>(
                initialValue: 'Initial Value',
                decoration: (context, state) =>
                    const InputDecoration(labelText: 'Some label'),
                onTap: (state) {},
                builder: (context, state) => Text(state.value!),
              ),
            ),
          ),
        );

        expect(find.text('Initial Value'), findsOneWidget);
      });

      testWidgets('Tapping', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Scaffold(
              body: TapableFormField<String>(
                initialValue: 'Initial Value',
                decoration: (context, state) =>
                    const InputDecoration(labelText: 'Some label'),
                onTap: (state) {
                  showDialog(
                    context: state.context,
                    builder: (context) => const AlertDialog(
                      content: Text('Test succeeded'),
                    ),
                  );
                },
                builder: (context, state) => Text(state.value!),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Initial Value'));
        await tester.pump();

        expect(find.text('Test succeeded'), findsOneWidget);
      });

      testWidgets('Can change state', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Scaffold(
              body: TapableFormField<String>(
                initialValue: 'Initial Value',
                decoration: (context, state) =>
                    const InputDecoration(labelText: 'Some label'),
                onTap: (state) {
                  state.didChange('Changed!');
                },
                builder: (context, state) => Text(state.value!),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Initial Value'));
        await tester.pump();

        expect(find.text('Changed!'), findsOneWidget);
        expect(find.text('Initial Value'), findsNothing);
      });
    });

    group('Password Form Field', () {
      testWidgets('Label', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const Scaffold(
              body: PasswordFormField(
                labelText: 'Password',
              ),
            ),
          ),
        );

        expect(find.text('Password'), findsOneWidget);
      });

      testWidgets('Text obscuring', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const Scaffold(
              body: PasswordFormField(
                key: Key('PasswordField'),
                initialValue: 'initialValue',
                labelText: 'Password',
              ),
            ),
          ),
        );

        expect(
          tester
              .widget<TextField>(
                find.descendant(
                  of: find.byKey(const Key('PasswordField')),
                  matching: find.byType(TextField),
                ),
              )
              .obscureText,
          true,
        );

        expect(find.byIcon(Icons.visibility_off), findsNothing);
        expect(find.byIcon(Icons.visibility), findsOneWidget);

        await tester.tap(find.byIcon(Icons.visibility));
        await tester.pump();

        expect(
          tester
              .widget<TextField>(
                find.descendant(
                  of: find.byKey(const Key('PasswordField')),
                  matching: find.byType(TextField),
                ),
              )
              .obscureText,
          false,
        );

        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
        expect(find.byIcon(Icons.visibility), findsNothing);

        await tester.tap(find.byIcon(Icons.visibility_off));
        await tester.pump();

        expect(
          tester
              .widget<TextField>(
                find.descendant(
                  of: find.byKey(const Key('PasswordField')),
                  matching: find.byType(TextField),
                ),
              )
              .obscureText,
          true,
        );
        expect(find.byIcon(Icons.visibility_off), findsNothing);
        expect(find.byIcon(Icons.visibility), findsOneWidget);
      });
    });
  });
}
