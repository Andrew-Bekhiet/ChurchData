import 'package:churchdata/utils/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Finder get listViewMatcher => find.descendant(
      of: find.byKey(const Key('ListView')),
      matching: find.byType(Scrollable).first,
    );

final Map<String, dynamic> userClaims = {
  'password': 'password',
  'manageUsers': false,
  'superAccess': false,
  'manageDeleted': false,
  'write': true,
  'exportAreas': false,
  'birthdayNotify': false,
  'confessionsNotify': false,
  'tanawolNotify': false,
  'approveLocations': false,
  'approved': true,
  'personRef': 'Persons/user'
};

Widget wrapWithMaterialApp(Widget widget,
    {Map<String, Widget Function(BuildContext)>? routes}) {
  return MaterialApp(
    navigatorKey: navigator,
    scaffoldMessengerKey: scaffoldMessenger,
    debugShowCheckedModeBanner: false,
    title: 'بيانات الكنيسة',
    routes: {
      '/': (_) => widget,
      ...routes ?? {},
    },
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('ar', 'EG'),
    ],
    locale: const Locale('ar', 'EG'),
  );
}
