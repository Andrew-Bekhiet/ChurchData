import 'package:churchdata/models/loading_widget.dart';
import 'package:churchdata/models/models.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:churchdata/views/auth_screen.dart';
import 'package:churchdata/views/edit_page/update_user_data_error_p.dart';
import 'package:churchdata/views/login.dart';
import 'package:churchdata/views/updates.dart';
import 'package:churchdata/views/user_registeration.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../fakes/fakes.mocks.dart';
import '../globals.dart';
import '../main.dart';

Future<void> main() async {
  await initTests();

  group('Widgets structrures', () {
    group('LoadingWidget', () {
      testWidgets('Normal', (tester) async {
        await tester.pumpWidget(wrapWithMaterialApp(const Loading()));
        await tester.pump();

        expect(find.byType(Image), findsOneWidget);
        expect(find.text('جار التحميل...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
            find.text('اصدار: ' + (await PackageInfo.fromPlatform()).version),
            findsNothing);
      });

      testWidgets('With version', (tester) async {
        await tester.pumpWidget(wrapWithMaterialApp(const Loading(
          showVersionInfo: true,
        )));
        await tester.pump();

        expect(find.byType(Image), findsOneWidget);
        expect(find.text('جار التحميل...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
            find.text('اصدار: ' + (await PackageInfo.fromPlatform()).version),
            findsOneWidget);
      });

      group('Errors', () {
        tearDown(() {
          when(remoteConfig.getString('LoadApp')).thenReturn('true');
          when(remoteConfig.getString('LatestVersion')).thenReturn('8.0.0');
        });

        testWidgets('Other errors', (tester) async {
          await tester.pumpWidget(wrapWithMaterialApp(const Loading(
            error: true,
            message: '{Error message}',
          )));
          await tester.pump();

          expect(find.byType(Image), findsOneWidget);

          expect(find.text('جار التحميل...'), findsNothing);
          expect(find.byType(CircularProgressIndicator), findsNothing);

          expect(find.text('لا يمكن تحميل البرنامج في الوقت الحالي'),
              findsOneWidget);

          expect(find.text('اضغط لمزيد من المعلومات'), findsOneWidget);
          expect(find.byKey(const Key('ClickForMore')), findsOneWidget);

          expect(
              find.text('اصدار: ' + (await PackageInfo.fromPlatform()).version),
              findsOneWidget);

          await tester.tap(find.byKey(const Key('ClickForMore')));
          await tester.pumpAndSettle();

          expect(find.text('{Error message}'), findsOneWidget);
        });
        testWidgets('Update User Data Error', (tester) async {
          await tester.pumpWidget(
            wrapWithMaterialApp(
              const Loading(
                error: true,
                message: 'Exception: Error Update User Data',
              ),
              routes: {
                'UpdateUserDataError': (context) => UpdateUserDataErrorPage(
                      person: Person(
                        ref: null,
                        areaId: null,
                        streetId: null,
                        familyId: null,
                      ),
                    ),
              },
            ),
          );
          await tester.pump();

          expect(find.byType(Image), findsOneWidget);

          expect(find.text('جار التحميل...'), findsNothing);
          expect(find.byType(CircularProgressIndicator), findsNothing);

          expect(find.text('لا يمكن تحميل البرنامج في الوقت الحالي'),
              findsOneWidget);

          expect(find.text('اضغط لمزيد من المعلومات'), findsOneWidget);
          expect(find.byKey(const Key('ClickForMore')), findsOneWidget);

          expect(
              find.text('اصدار: ' + (await PackageInfo.fromPlatform()).version),
              findsOneWidget);

          await tester.tap(find.byKey(const Key('ClickForMore')));
          await tester.pumpAndSettle();

          expect(find.text('تحديث بيانات التناول والاعتراف'), findsOneWidget);

          await tester.tap(find.text('تحديث بيانات التناول والاعتراف'));
          await tester.pumpAndSettle();

          expect(find.byType(UpdateUserDataErrorPage), findsOneWidget);
        });
        testWidgets('Cannot Load App Error', (tester) async {
          when(remoteConfig.getString('LoadApp')).thenReturn('false');
          when(remoteConfig.getString('LatestVersion')).thenReturn('9.0.0');

          await tester.pumpWidget(
            wrapWithMaterialApp(
              const Loading(
                error: true,
                message: 'Exception: يجب التحديث لأخر إصدار لتشغيل البرنامج',
              ),
              routes: {
                'UpdateUserDataError': (context) => UpdateUserDataErrorPage(
                      person: Person(
                        ref: null,
                        areaId: null,
                        streetId: null,
                        familyId: null,
                      ),
                    ),
              },
            ),
          );
          await tester.pump();

          expect(find.byType(Image), findsOneWidget);

          expect(find.text('جار التحميل...'), findsNothing);
          expect(find.byType(CircularProgressIndicator), findsNothing);

          expect(find.text('لا يمكن تحميل البرنامج في الوقت الحالي'),
              findsOneWidget);

          expect(find.text('اضغط لمزيد من المعلومات'), findsOneWidget);
          expect(find.byKey(const Key('ClickForMore')), findsOneWidget);

          expect(
              find.text('اصدار: ' + (await PackageInfo.fromPlatform()).version),
              findsOneWidget);

          await tester.tap(find.byKey(const Key('ClickForMore')));
          await tester.pumpAndSettle();

          expect(find.text('تحديث'), findsOneWidget);
        });
      });
    });

    testWidgets(
      'Login Screen',
      (tester) async {
        await tester.pumpWidget(wrapWithMaterialApp(const LoginScreen()));

        expect(find.text('بيانات الكنيسة'), findsOneWidget);
        expect(find.textContaining('تسجيل الدخول'), findsWidgets);
        expect(find.text('Google'), findsOneWidget);
      },
    );

    testWidgets(
      'UpdateUserDataErrorPage',
      (tester) async {
        final DateTime lastConfession =
            DateTime.now().subtract(const Duration(days: 2 * 30));
        final DateTime lastTanawol =
            DateTime.now().subtract(const Duration(days: (2 * 30) + 1));

        await tester.pumpWidget(
          wrapWithMaterialApp(
            UpdateUserDataErrorPage(
              person: Person(
                lastConfession: Timestamp.fromDate(lastConfession),
                lastTanawol: Timestamp.fromDate(lastTanawol),
                ref: null,
                areaId: null,
                streetId: null,
                familyId: null,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.save), findsOneWidget);

        Finder lastTanawolMatcher =
            find.text(DateFormat('yyyy/M/d').format(lastTanawol));
        Finder lastConfessionMatcher =
            find.text(DateFormat('yyyy/M/d').format(lastConfession));

        expect(lastConfessionMatcher, findsOneWidget);
        expect(lastTanawolMatcher, findsOneWidget);

        expect(
            find.descendant(
              of: find.ancestor(
                of: lastConfessionMatcher,
                matching: find.byType(Container),
              ),
              matching: find.byIcon(Icons.close),
            ),
            findsOneWidget);
        expect(
            find.descendant(
              of: find.ancestor(
                of: lastTanawolMatcher,
                matching: find.byType(Container),
              ),
              matching: find.byIcon(Icons.close),
            ),
            findsOneWidget);

        await tester.tap(lastConfessionMatcher);
        await tester.pumpAndSettle();

        expect(find.byType(DatePickerDialog), findsOneWidget);

        if (lastConfession.day != 27)
          await tester.tap(find.text('٢٧'));
        else
          await tester.tap(find.text('٢٨'));

        await tester.tap(find.text('حسنًا'));
        await tester.pumpAndSettle();

        lastConfessionMatcher = find.text(DateFormat('yyyy/M/d').format(
            DateTime(lastConfession.year, lastConfession.month,
                lastConfession.day != 27 ? 27 : 28)));

        expect(lastConfessionMatcher, findsOneWidget);

        await tester.tap(lastTanawolMatcher);
        await tester.pumpAndSettle();

        expect(find.byType(DatePickerDialog), findsOneWidget);

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

        expect(lastTanawolMatcher, findsNWidgets(2));
      },
    );

    group(
      'UserRegisteration',
      () {
        setUp(() async {
          if (User.instance.uid != null) await User.instance.signOut();
          await firebaseAuth.signInWithCustomToken('token');
          await User.instance.initialized;
        });

        tearDown(() async {
          userClaims['approved'] = true;
          await User.instance.signOut();
        });

        testWidgets('When user is not approved', (tester) async {
          userClaims['approved'] = false;

          await tester.runAsync(User.instance.forceRefresh);

          await tester
              .pumpWidget(wrapWithMaterialApp(const UserRegisteration()));

          expect(find.text('في انتظار الموافقة'), findsOneWidget);
          expect(find.widgetWithIcon(IconButton, Icons.logout), findsOneWidget);
          expect(find.text('لينك الدعوة'), findsOneWidget);
          expect(find.text('تفعيل الحساب باللينك'), findsOneWidget);
        });

        testWidgets(
          'When user is approved',
          (tester) async {
            userClaims['approved'] = true;
            await tester.runAsync(User.instance.forceRefresh);

            await tester
                .pumpWidget(wrapWithMaterialApp(const UserRegisteration()));

            await tester.scrollUntilVisible(
              find.text('تسجيل حساب جديد'),
              70,
              scrollable: listViewMatcher,
            );
            expect(find.text('تسجيل حساب جديد'), findsOneWidget);

            await tester.scrollUntilVisible(
              find.text('اسم المستخدم'),
              70,
              scrollable: listViewMatcher,
            );
            expect(find.text('اسم المستخدم'), findsOneWidget);

            await tester.scrollUntilVisible(
              find.text('كلمة السر'),
              70,
              scrollable: listViewMatcher,
            );
            expect(find.text('كلمة السر'), findsOneWidget);

            await tester.scrollUntilVisible(
              find.text('تأكيد كلمة السر'),
              70,
              scrollable: listViewMatcher,
            );
            expect(find.text('تأكيد كلمة السر'), findsOneWidget);

            await tester.scrollUntilVisible(
              find.text('انشاء حساب جديد'),
              70,
              scrollable: listViewMatcher,
            );
            expect(find.text('انشاء حساب جديد'), findsOneWidget);
          },
        );
      },
    );

    group(
      'AuthScreen',
      () {
        tearDown(() {
          when(localAuthentication.canCheckBiometrics)
              .thenAnswer((_) async => true);
        });
        testWidgets('With Biometrics', (tester) async {
          tester.binding.window.physicalSizeTestValue =
              const Size(1080 * 3, 2400 * 3);

          await tester.pumpWidget(
            wrapWithMaterialApp(
              const AuthScreen(),
            ),
          );
          await tester.pump();

          expect(find.byType(BackButton), findsNothing);
          expect(find.text('برجاء التحقق للمتابعة'), findsOneWidget);

          await tester.scrollUntilVisible(
            find.byType(Image),
            70,
            scrollable: listViewMatcher,
          );

          expect(find.byType(Image), findsOneWidget);

          await tester.scrollUntilVisible(
            find.text('كلمة السر'),
            70,
            scrollable: listViewMatcher,
          );

          expect(find.text('كلمة السر'), findsOneWidget);

          await tester.scrollUntilVisible(
            find.text('تسجيل الدخول'),
            70,
            scrollable: listViewMatcher,
          );

          expect(find.text('تسجيل الدخول'), findsOneWidget);

          await tester.scrollUntilVisible(
            find.text('إعادة المحاولة عن طريق بصمة الاصبع/الوجه'),
            70,
            scrollable: listViewMatcher,
          );

          expect(find.text('إعادة المحاولة عن طريق بصمة الاصبع/الوجه'),
              findsOneWidget);
        });
        testWidgets('Without Biometrics', (tester) async {
          tester.binding.window.physicalSizeTestValue =
              const Size(1080 * 3, 2400 * 3);

          when(localAuthentication.canCheckBiometrics)
              .thenAnswer((_) async => false);

          await tester.pumpWidget(
            wrapWithMaterialApp(
              const AuthScreen(),
            ),
          );
          await tester.pump();

          expect(find.byType(BackButton), findsNothing);
          expect(find.text('برجاء التحقق للمتابعة'), findsOneWidget);

          await tester.scrollUntilVisible(
            find.byType(Image),
            70,
            scrollable: listViewMatcher,
          );

          expect(find.byType(Image), findsOneWidget);

          await tester.scrollUntilVisible(
            find.text('كلمة السر'),
            70,
            scrollable: listViewMatcher,
          );

          expect(find.text('كلمة السر'), findsOneWidget);

          await tester.scrollUntilVisible(
            find.text('تسجيل الدخول'),
            70,
            scrollable: listViewMatcher,
          );

          expect(find.text('تسجيل الدخول'), findsOneWidget);

          expect(find.text('إعادة المحاولة عن طريق بصمة الاصبع/الوجه'),
              findsNothing);
        });
      },
    );

    group('Updates page', () {
      late String downloadLink;

      setUp(() {
        downloadLink = remoteConfig
            .getString('DownloadLink')
            .replaceFirst('https://', 'https:');
        when(remoteConfig.getString('LatestVersion')).thenReturn('8.5.0');
        when(UrlLauncherPlatform.instance.canLaunch(downloadLink))
            .thenAnswer((_) async => true);
        when((UrlLauncherPlatform.instance as MockUrlLauncherPlatform).launch(
          downloadLink,
          enableDomStorage: anyNamed('enableDomStorage'),
          enableJavaScript: anyNamed('enableJavaScript'),
          headers: anyNamed('headers'),
          universalLinksOnly: anyNamed('universalLinksOnly'),
          useSafariVC: anyNamed('useSafariVC'),
          useWebView: anyNamed('useWebView'),
          webOnlyWindowName: anyNamed('webOnlyWindowName'),
        )).thenAnswer((_) async => true);
      });

      tearDown(() {
        when(remoteConfig.getString('LatestVersion')).thenReturn('8.0.0');
        reset(UrlLauncherPlatform.instance);
      });

      testWidgets(
        'Widget structure',
        (tester) async {
          await tester.pumpWidget(wrapWithMaterialApp(const Update()));
          await tester.pumpAndSettle();

          expect(find.text('الإصدار الحالي:'), findsOneWidget);
          expect(find.text('أخر إصدار:'), findsOneWidget);

          expect(
            find.descendant(
              of: find.ancestor(
                of: find.text('الإصدار الحالي:'),
                matching: find.byType(ListTile),
              ),
              matching: find.text('8.0.0'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.ancestor(
                of: find.text('أخر إصدار:'),
                matching: find.byType(ListTile),
              ),
              matching: find.text('8.5.0'),
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'Update Dialog',
        (tester) async {
          await tester.pumpWidget(wrapWithMaterialApp(const Update()));
          await tester.pumpAndSettle();

          expect(find.text('هل تريد التحديث إلى إصدار 8.5.0؟'), findsOneWidget);
          expect(find.text('نعم'), findsOneWidget);

          await tester.tap(find.text('نعم'));

          verify(
              (UrlLauncherPlatform.instance as MockUrlLauncherPlatform).launch(
            downloadLink,
            enableDomStorage: anyNamed('enableDomStorage'),
            enableJavaScript: anyNamed('enableJavaScript'),
            headers: anyNamed('headers'),
            universalLinksOnly: anyNamed('universalLinksOnly'),
            useSafariVC: anyNamed('useSafariVC'),
            useWebView: anyNamed('useWebView'),
            webOnlyWindowName: anyNamed('webOnlyWindowName'),
          ));
        },
      );
    });
  });
}
