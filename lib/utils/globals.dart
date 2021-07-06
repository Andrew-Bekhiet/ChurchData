import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const List<Color> colors = [
  Colors.white,
  Colors.grey,
  Colors.black,
  Colors.transparent,
  Colors.brown,
  Colors.red,
  Colors.deepOrange,
  Colors.orange,
  Colors.amber,
  Colors.yellow,
  Colors.lime,
  Colors.lightGreen,
  Colors.green,
  Colors.blue,
  Colors.cyan,
  Colors.lightBlue,
  Colors.teal,
  Colors.indigo,
  Colors.deepPurple,
  Colors.purple,
  Colors.pink,
];

const List<Color> accents = <Color>[
  Colors.redAccent,
  Colors.pinkAccent,
  Colors.purpleAccent,
  Colors.deepPurpleAccent,
  Colors.indigoAccent,
  Colors.blueAccent,
  Colors.lightBlueAccent,
  Colors.cyanAccent,
  Colors.tealAccent,
  Colors.greenAccent,
  Colors.lightGreenAccent,
  Colors.limeAccent,
  Colors.yellowAccent,
  Colors.amberAccent,
  Colors.orangeAccent,
  Colors.deepOrangeAccent,
  Colors.brown,
  Colors.blueGrey,
  Colors.black
];

final AndroidParameters androidParameters = AndroidParameters(
  packageName: 'com.AndroidQuartz.churchdata',
  minimumVersion: 4,
  fallbackUrl:
      Uri.parse('https://github.com/Andrew-Bekhiet/ChurchData/releases/latest'),
);

GetOptions dataSource = GetOptions(source: Source.serverAndCache);

final DynamicLinkParametersOptions dynamicLinkParametersOptions =
    DynamicLinkParametersOptions(
        shortDynamicLinkPathLength: ShortDynamicLinkPathLength.unguessable);

const FlutterSecureStorage flutterSecureStorage = FlutterSecureStorage();

final IosParameters iosParameters =
    IosParameters(bundleId: 'com.AndroidQuartz.churchdata');

final GlobalKey<ScaffoldState> mainScfld = GlobalKey<ScaffoldState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessenger =
    GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();

List<Color> primaries = <Color>[
  Colors.red,
  Colors.pink,
  Colors.purple,
  Colors.deepPurple,
  Colors.indigo,
  Colors.blue,
  Colors.lightBlue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.lightGreen,
  Colors.lime,
  Colors.yellow,
  Colors.amber,
  Colors.orange,
  Colors.deepOrange,
  Colors.deepOrangeAccent,
  Colors.blueAccent,
  Colors.grey.shade700
];

const String uriPrefix = 'https://churchdata.page.link';

bool configureMessaging = true;
enum PhoneCallAction { AddToContacts, Call, Message, Whatsapp }

const MaterialColor white = MaterialColor(0xFFD8D8D8, <int, Color>{
  50: Color(0xFFFAFAFA),
  100: Color(0xFFF3F3F3),
  200: Color(0xFFECECEC),
  300: Color(0xFFE4E4E4),
  400: Color(0xFFDEDEDE),
  500: Color(0xFFD8D8D8),
  600: Color(0xFFD4D4D4),
  700: Color(0xFFCECECE),
  800: Color(0xFFC8C8C8),
  900: Color(0xFFBFBFBF),
});

const MaterialColor whiteAccent = MaterialColor(0xFFFFFFFF, <int, Color>{
  100: Color(0xFFFFFFFF),
  200: Color(0xFFFFFFFF),
  400: Color(0xFFFFFFFF),
  700: Color(0xFFFFFFFF),
});

const MaterialColor black = MaterialColor(0xFF000000, <int, Color>{
  50: Color(0xFFE0E0E0),
  100: Color(0xFFB3B3B3),
  200: Color(0xFF808080),
  300: Color(0xFF4D4D4D),
  400: Color(0xFF262626),
  500: Color(0xFF000000),
  600: Color(0xFF000000),
  700: Color(0xFF000000),
  800: Color(0xFF000000),
  900: Color(0xFF000000),
});

const MaterialColor blackAccent = MaterialColor(0xFF8C8C8C, <int, Color>{
  100: Color(0xFFA6A6A6),
  200: Color(0xFF8C8C8C),
  400: Color(0xFF737373),
  700: Color(0xFF666666),
});
