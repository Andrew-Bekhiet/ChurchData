import 'dart:async';

import 'package:churchdata/EncryptionKeys.dart';
import 'package:churchdata/main.dart';
import 'package:churchdata/models/models.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:churchdata/views/auth_screen.dart';
import 'package:churchdata/views/login.dart';
import 'package:churchdata/views/user_registeration.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mockito/mockito.dart';

import '../fakes/fakes.dart';
import '../globals.dart';
import '../main.dart';
import '../main.mocks.dart';

Future<void> main() async {
  await initTests();

  group('Initialization tests', () {
    group('Login', () {
      setUp(User.instance.signOut);

      testWidgets(
        'Displays Login screen when not logged in',
        (tester) async {
          await tester.pumpWidget(const App());

          await tester.pumpAndSettle();

          expect(find.byType(LoginScreen), findsOneWidget);
        },
      );

      testWidgets(
        'Login logic',
        (tester) async {
          await tester.pumpWidget(const App());
          await tester.pumpAndSettle();

          await tester.tap(find.text('Google'));
          await tester.pumpAndSettle();

          expect(firebaseAuth.currentUser?.uid, '8t7we9rhuiU%762');
        },
      );
      tearDown(User.instance.signOut);
    });

    group(
      'User registeration',
      () {
        setUp(() async {
          userClaims['approved'] = false;
          userClaims['password'] = null;

          if (User.instance.uid != null) await User.instance.signOut();
          await firebaseAuth.signInWithCustomToken('token');
          await User.instance.initialized;
          await User.instance.forceRefresh();
        });
        tearDown(() async {
          userClaims['approved'] = true;
          userClaims['password'] = 'password';
          await User.instance.signOut();
          reset(firebaseFunctions);
        });

        testWidgets(
          'Shows UserRegisteration widget',
          (tester) async {
            await tester.pumpWidget(const App());
            await tester.pumpAndSettle();

            expect(find.byType(UserRegisteration), findsOneWidget);
          },
          timeout: const Timeout(Duration(seconds: 5)),
        );

        testWidgets('Using invitation link', (tester) async {
          final MockHttpsCallable mockHttpsCallable = MockHttpsCallable();

          when(firebaseFunctions.httpsCallable('registerWithLink'))
              .thenReturn(mockHttpsCallable);

          when(mockHttpsCallable.call(argThat(predicate((p) {
            if (p == null) return false;
            final Map<String, dynamic> m = p as Map<String, dynamic>;
            return m['link'] == 'https://churchdata.page.link/fakeInvitation';
          }))))
              .thenAnswer((_) async => FakeHttpsCallableResult<String>('dumb'));

          await tester.pumpWidget(const App());
          await tester.pumpAndSettle();

          await tester.tap(find.text('تفعيل الحساب باللينك'));
          await tester.pump();

          expect(find.text('برجاء ادخال لينك الدخول لتفعيل حسابك'),
              findsOneWidget);

          await tester.enterText(
              find.widgetWithText(TextFormField, 'لينك الدعوة'),
              'https://churchdata.page.link/fakeInvitation');
          await tester.pump();

          await tester.tap(find.text('تفعيل الحساب باللينك'));
          await tester.pump();

          verify(mockHttpsCallable.call(argThat(predicate((p) {
            if (p == null) return false;
            final Map<String, dynamic> m = p as Map<String, dynamic>;
            return m['link'] == 'https://churchdata.page.link/fakeInvitation';
          }))));
        });

        testWidgets(
          'Submitting account name and password',
          (tester) async {
            final MockHttpsCallable mockHttpsCallable = MockHttpsCallable();

            when(mockHttpsCallable.call(argThat(predicate((p) {
              if (p == null) return false;
              final Map<String, dynamic> m = p as Map<String, dynamic>;
              return m['name'] == 'name' &&
                  m['password'] == Encryption.encryptPassword('Strong*P@ss9') &&
                  m['fcmToken'] == '{FCMToken}';
            })))).thenAnswer(
                (_) async => FakeHttpsCallableResult<String>('dumb'));

            when(firebaseFunctions.httpsCallable('registerAccount'))
                .thenReturn(mockHttpsCallable);

            await firestore.doc('Persons/user').set(
              {
                'LastTanawol': Timestamp.now(),
                'LastConfession': Timestamp.now(),
              },
            );

            userClaims['approved'] = true;
            await tester.runAsync(User.instance.forceRefresh);

            await tester.pumpWidget(const App());
            await tester.pumpAndSettle();

            expect(find.byType(UserRegisteration), findsOneWidget);

            await tester.scrollUntilVisible(
              find.byKey(const Key('UsernameField')),
              70,
              scrollable: listViewMatcher,
            );

            await tester.enterText(
              find.byKey(const Key('UsernameField')),
              'name',
            );

            await tester.scrollUntilVisible(
              find.byKey(const Key('Password')),
              70,
              scrollable: listViewMatcher,
            );

            await tester.enterText(
                find.byKey(const Key('Password')), 'Strong*P@ss9');

            await tester.scrollUntilVisible(
              find.byKey(const Key('PasswordConfirmation')),
              70,
              scrollable: listViewMatcher,
            );

            await tester.enterText(
                find.byKey(const Key('PasswordConfirmation')), 'Strong*P@ss9');
            await tester.pump();

            await tester.scrollUntilVisible(
              find.byKey(const Key('SubmitButton')),
              70,
              scrollable: listViewMatcher,
            );

            await tester.tap(find.byKey(const Key('SubmitButton')));

            await tester.pump();

            verify(mockHttpsCallable.call(argThat(predicate((p) {
              if (p == null) return false;
              final Map<String, dynamic> m = p as Map<String, dynamic>;
              return m['name'] == 'name' &&
                  m['password'] == Encryption.encryptPassword('Strong*P@ss9') &&
                  m['fcmToken'] == '{FCMToken}';
            }))));
          },
          timeout: const Timeout(Duration(seconds: 5)),
        );
      },
    );

    group('Entering with AuthScreen', () {
      Completer<bool> _authCompleter = Completer();
      setUp(() {
        when(localAuthentication.canCheckBiometrics)
            .thenAnswer((_) async => true);
        when(localAuthentication.authenticate(
          localizedReason: 'برجاء التحقق للمتابعة',
          options: const AuthenticationOptions(
            biometricOnly: true,
            useErrorDialogs: false,
          ),
        )).thenAnswer((_) => _authCompleter.future);
      });

      tearDown(() async {
        if (!_authCompleter.isCompleted) _authCompleter.complete(false);
        _authCompleter = Completer();
      });
      group('With password', () {
        const _passwordText = '1%Pass word*)';

        setUp(() async {
          userClaims['password'] = Encryption.encryptPassword(_passwordText);

          if (User.instance.uid != null) await User.instance.signOut();
          await firebaseAuth.signInWithCustomToken('token');
          await User.instance.initialized;
        });
        tearDown(() async {
          await User.instance.signOut();
          userClaims['password'] = 'password';
        });

        testWidgets('Entering password', (tester) async {
          tester.binding.window.physicalSizeTestValue =
              const Size(1080 * 3, 2400 * 3);

          await tester.pumpWidget(
            wrapWithMaterialApp(
              const AuthScreen(
                nextRoute: 'Success',
              ),
              routes: {
                'Success': (_) => const Scaffold(body: Text('Test succeeded'))
              },
            ),
          );
          await tester.pump();

          _authCompleter.complete(false);

          await tester.enterText(
            find.byKey(const Key('Password')),
            _passwordText,
          );

          await tester.tap(find.byKey(const Key('Submit')));

          await tester.pump();
          await tester.pump();

          expect(find.text('Test succeeded'), findsOneWidget);
        });
        group('Errors', () {
          testWidgets('Empty Password', (tester) async {
            tester.binding.window.physicalSizeTestValue =
                const Size(1080 * 3, 2400 * 3);

            await tester.pumpWidget(
              wrapWithMaterialApp(
                const AuthScreen(),
              ),
            );
            await tester.pump();

            await tester.enterText(
              find.byKey(const Key('Password')),
              '',
            );
            await tester.tap(find.byKey(const Key('Submit')));
            await tester.pump();

            expect(find.text('كلمة سر فارغة!'), findsOneWidget);
          });
          testWidgets('Wrong Password', (tester) async {
            tester.binding.window.physicalSizeTestValue =
                const Size(1080 * 3, 2400 * 3);

            await tester.pumpWidget(
              wrapWithMaterialApp(
                const AuthScreen(),
              ),
            );
            await tester.pump();

            await tester.enterText(
              find.byKey(const Key('Password')),
              'Wrong',
            );
            await tester.tap(find.text('تسجيل الدخول'));
            await tester.pump();

            expect(find.text('كلمة سر خاطئة!'), findsOneWidget);
          });
        });
      });

      testWidgets('With Biometrics', (tester) async {
        tester.binding.window.physicalSizeTestValue =
            const Size(1080 * 3, 2400 * 3);

        await tester.pumpWidget(
          wrapWithMaterialApp(
            const AuthScreen(
              nextRoute: 'Success',
            ),
            routes: {
              'Success': (_) => const Scaffold(body: Text('Test succeeded'))
            },
          ),
        );
        await tester.pump();

        _authCompleter.complete(false);
        _authCompleter = Completer();

        await tester.tap(find.byKey(const Key('Biometrics')));

        _authCompleter.complete(true);

        await tester.pumpAndSettle();

        expect(find.text('Test succeeded'), findsOneWidget);
      });
    });

    group('Updating lastConfession and lastTanawol', () {
      final DateTime lastConfession =
          DateTime.now().subtract(const Duration(days: 2 * 30));
      final DateTime lastTanawol =
          DateTime.now().subtract(const Duration(days: (2 * 30) + 1));

      setUp(() async {
        if (User.instance.uid != null) await User.instance.signOut();
        await firebaseAuth.signInWithCustomToken('token');
        await User.instance.initialized;

        await firestore.doc('Persons/user').set(
          {
            'LastTanawol': lastTanawol,
            'LastConfession': lastConfession,
          },
        );
      });

      tearDown(() async {
        await User.instance.signOut();
        await firestore.doc('Persons/user').delete();
      });

      testWidgets(
        'Displays UpdateUserDataError when needed',
        (tester) async {
          await tester.pumpWidget(const App());
          await tester.pumpAndSettle();

          expect(find.text('تحديث بيانات التناول والاعتراف'), findsOneWidget);
        },
      );

      testWidgets(
        'UpdateUserDataErrorPage saves data correctly',
        (tester) async {
          await tester.pumpWidget(const App());
          await tester.pumpAndSettle();

          await tester.tap(find.text('تحديث بيانات التناول والاعتراف'));

          await tester.pumpAndSettle();

          Finder lastTanawolMatcher =
              find.text(DateFormat('yyyy/M/d').format(lastTanawol));
          Finder lastConfessionMatcher =
              find.text(DateFormat('yyyy/M/d').format(lastConfession));

          await tester.tap(lastConfessionMatcher);
          await tester.pumpAndSettle();

          if (lastConfession.day != 27)
            await tester.tap(find.text('٢٧'));
          else
            await tester.tap(find.text('٢٨'));

          await tester.tap(find.text('حسنًا'));
          await tester.pumpAndSettle();

          lastConfessionMatcher = find.text(DateFormat('yyyy/M/d').format(
              DateTime(lastConfession.year, lastConfession.month,
                  lastConfession.day != 27 ? 27 : 28)));

          await tester.tap(lastTanawolMatcher);
          await tester.pumpAndSettle();

          if (lastTanawol.day != 27)
            await tester.tap(find.text('٢٧'));
          else
            await tester.tap(find.text('٢٨'));

          await tester.tap(find.text('حسنًا'));
          await tester.pumpAndSettle();

          lastTanawolMatcher = find.text(DateFormat('yyyy/M/d').format(DateTime(
              lastTanawol.year,
              lastTanawol.month,
              lastTanawol.day != 27 ? 27 : 28)));

          await tester.tap(find.byIcon(Icons.save));

          expect(
            (await firestore.doc('Persons/user').get())
                .data()?['LastTanawol']
                ?.millisecondsSinceEpoch,
            DateTime(lastTanawol.year, lastTanawol.month,
                    lastTanawol.day != 27 ? 27 : 28)
                .millisecondsSinceEpoch,
          );
          expect(
            (await firestore.doc('Persons/user').get())
                .data()?['LastConfession']
                ?.millisecondsSinceEpoch,
            DateTime(lastConfession.year, lastConfession.month,
                    lastConfession.day != 27 ? 27 : 28)
                .millisecondsSinceEpoch,
          );
        },
      );
    });

    testWidgets(
      'Blocks running when LoadApp is false',
      (tester) async {
        when(remoteConfig.getString('LoadApp')).thenReturn('false');
        when(remoteConfig.getString('LatestVersion')).thenReturn('9.0.0');

        addTearDown(() {
          when(remoteConfig.getString('LoadApp')).thenReturn('true');
          when(remoteConfig.getString('LatestVersion')).thenReturn('8.0.0');
        });

        await tester.pumpWidget(const App());

        await tester.pumpAndSettle();

        expect(find.text('تحديث'), findsOneWidget);
      },
    );
  });
}
