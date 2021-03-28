import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/family.dart';
import 'package:churchdata/models/list.dart';
import 'package:churchdata/models/person.dart';
import 'package:churchdata/models/street.dart';
import 'package:churchdata/views/mini_lists/users_list.dart';
import 'package:churchdata/models/data_dialog.dart';
import 'package:churchdata/views/search_query.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart' hide User;
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as messaging_types;
import 'package:firebase_messaging/firebase_messaging.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart' hide User;
import 'package:firebase_storage/firebase_storage.dart' hide ListOptions;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Person;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:timeago/timeago.dart';

import '../models/list_options.dart';
import '../models/notification.dart' as no;
import '../models/order_options.dart';
import '../models/theme_notifier.dart';
import '../models/user.dart';
import '../models/super_classes.dart';
import '../main.dart';
import 'globals.dart';

void areaTap(Area area, BuildContext context) {
  Navigator.of(context).pushNamed('AreaInfo', arguments: area);
}

void showConfessionNotification() async {
  await Firebase.initializeApp();
  if (auth.FirebaseAuth.instance.currentUser == null) return;
  await User.instance.initialized;
  var user = User.instance;
  var source = GetOptions(
      source:
          (await Connectivity().checkConnectivity()) == ConnectivityResult.none
              ? Source.cache
              : Source.serverAndCache);
  QuerySnapshot docs;
  if (user.superAccess) {
    docs = (await FirebaseFirestore.instance
        .collection('Persons')
        .where('LastConfession', isLessThan: Timestamp.now())
        .limit(20)
        .get(source));
  } else {
    docs = (await FirebaseFirestore.instance
        .collection('Persons')
        .where('AreaId',
            whereIn: (await FirebaseFirestore.instance
                    .collection('Areas')
                    .where('Allowed',
                        arrayContains:
                            auth.FirebaseAuth.instance.currentUser.uid)
                    .get(source))
                .docs
                .map((e) => e.reference)
                .toList())
        .where('LastConfession', isLessThan: Timestamp.now())
        .limit(20)
        .get(source));
  }
  if (docs.docs.isNotEmpty)
    await FlutterLocalNotificationsPlugin().show(
        0,
        'انذار الاعتراف',
        docs.docs.map((e) => e.data()['Name']).join(', '),
        NotificationDetails(
          android: AndroidNotificationDetails(
              'Confessions', 'إشعارات الاعتراف', 'إشعارات الاعتراف',
              icon: 'warning',
              autoCancel: false,
              visibility: NotificationVisibility.secret,
              showWhen: false),
        ),
        payload: 'Confessions');
}

void showTanawolNotification() async {
  await Firebase.initializeApp();
  if (auth.FirebaseAuth.instance.currentUser == null) return;
  await User.instance.initialized;
  var user = User.instance;
  var source = GetOptions(
      source:
          (await Connectivity().checkConnectivity()) == ConnectivityResult.none
              ? Source.cache
              : Source.serverAndCache);
  QuerySnapshot docs;
  if (user.superAccess) {
    docs = (await FirebaseFirestore.instance
        .collection('Persons')
        .where('LastTanawol', isLessThan: Timestamp.now())
        .limit(20)
        .get(source));
  } else {
    docs = (await FirebaseFirestore.instance
        .collection('Persons')
        .where('AreaId',
            whereIn: (await FirebaseFirestore.instance
                    .collection('Areas')
                    .where('Allowed',
                        arrayContains:
                            auth.FirebaseAuth.instance.currentUser.uid)
                    .get(source))
                .docs
                .map((e) => e.reference)
                .toList())
        .where('LastTanawol', isLessThan: Timestamp.now())
        .limit(20)
        .get(source));
  }
  if (docs.docs.isNotEmpty)
    await FlutterLocalNotificationsPlugin().show(
        1,
        'انذار التناول',
        docs.docs.map((e) => e.data()['Name']).join(', '),
        NotificationDetails(
          android: AndroidNotificationDetails(
              'Tanawol', 'إشعارات التناول', 'إشعارات التناول',
              icon: 'warning',
              autoCancel: false,
              visibility: NotificationVisibility.secret,
              showWhen: false),
        ),
        payload: 'Tanawol');
}

void showBirthDayNotification() async {
  await Firebase.initializeApp();
  if (auth.FirebaseAuth.instance.currentUser == null) return;
  await User.instance.initialized;
  var user = User.instance;
  var source = GetOptions(
      source:
          (await Connectivity().checkConnectivity()) == ConnectivityResult.none
              ? Source.cache
              : Source.serverAndCache);
  QuerySnapshot docs;
  if (user.superAccess) {
    docs = (await FirebaseFirestore.instance
        .collection('Persons')
        .where(
          'BirthDay',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            DateTime(1970, DateTime.now().month, DateTime.now().day),
          ),
        )
        .where(
          'BirthDay',
          isLessThan: Timestamp.fromDate(
            DateTime(1970, DateTime.now().month, DateTime.now().day + 1),
          ),
        )
        .limit(20)
        .get(source));
  } else {
    docs = (await FirebaseFirestore.instance
        .collection('Persons')
        .where('AreaId',
            whereIn: (await FirebaseFirestore.instance
                    .collection('Areas')
                    .where('Allowed',
                        arrayContains:
                            auth.FirebaseAuth.instance.currentUser.uid)
                    .get(source))
                .docs
                .map((e) => e.reference)
                .toList())
        .where(
          'BirthDay',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            DateTime(1970, DateTime.now().month, DateTime.now().day),
          ),
        )
        .where(
          'BirthDay',
          isLessThan: Timestamp.fromDate(
            DateTime(1970, DateTime.now().month, DateTime.now().day + 1),
          ),
        )
        .limit(20)
        .get(source));
  }
  if (docs.docs.isNotEmpty)
    await FlutterLocalNotificationsPlugin().show(
        2,
        'أعياد الميلاد',
        docs.docs.map((e) => e.data()['Name']).join(', '),
        NotificationDetails(
          android: AndroidNotificationDetails(
              'Birthday', 'إشعارات أعياد الميلاد', 'إشعارات أعياد الميلاد',
              icon: 'birthday',
              autoCancel: false,
              visibility: NotificationVisibility.secret,
              showWhen: false),
        ),
        payload: 'Birthday');
}

Future onNotificationClicked(String payload) {
  if (WidgetsBinding.instance.renderViewElement != null) {
    processClickedNotification(mainScfld.currentContext, payload);
  }
  return null;
}

void changeTheme(
    {int primary,
    int accent,
    Brightness brightness,
    @required BuildContext context}) {
  primary = primary ?? Hive.box('Settings').get('PrimaryColorIndex');
  bool darkTheme = Hive.box('Settings').get('DarkTheme');
  brightness = brightness ??
      (darkTheme != null
          ? (darkTheme ? Brightness.dark : Brightness.light)
          : MediaQuery.of(context).platformBrightness);
  context.read<ThemeNotifier>().setTheme(
        ThemeData(
          floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: primaries[primary ?? 7]),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          outlinedButtonTheme: OutlinedButtonThemeData(
              style:
                  OutlinedButton.styleFrom(primary: primaries[primary ?? 7])),
          textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(primary: primaries[primary ?? 7])),
          elevatedButtonTheme: ElevatedButtonThemeData(
              style:
                  ElevatedButton.styleFrom(primary: primaries[primary ?? 7])),
          brightness: darkTheme != null
              ? (darkTheme ? Brightness.dark : Brightness.light)
              : WidgetsBinding.instance.window.platformBrightness,
          accentColor: accents[accent ?? 7],
          primaryColor: primaries[primary ?? 7],
        ),
      );
}

void dataObjectTap(DataObject obj, BuildContext context) {
  if (obj is Area)
    areaTap(obj, context);
  else if (obj is Street)
    streetTap(obj, context);
  else if (obj is Family)
    familyTap(obj, context);
  else if (obj is Person)
    personTap(obj, context);
  else if (obj is User)
    userTap(obj, context);
  else
    throw UnimplementedError();
}

void familyTap(Family family, BuildContext context) {
  Navigator.of(context).pushNamed('FamilyInfo', arguments: family);
}

LatLng fromGeoPoint(GeoPoint point) {
  return LatLng(point.latitude, point.longitude);
}

GeoPoint fromLatLng(LatLng point) {
  return GeoPoint(point.latitude, point.longitude);
}

Future<dynamic> getLinkObject(Uri deepLink) async {
  try {
    if (deepLink.pathSegments[0] == 'viewImage') {
      return MessageIcon(deepLink.queryParameters['url']);
    } else if (deepLink.pathSegments[0] == 'viewArea') {
      return await Area.fromId(deepLink.queryParameters['AreaId']);
    } else if (deepLink.pathSegments[0] == 'viewStreet') {
      return await Street.fromId(deepLink.queryParameters['StreetId']);
    } else if (deepLink.pathSegments[0] == 'viewFamily') {
      return await Family.fromId(deepLink.queryParameters['FamilyId']);
    } else if (deepLink.pathSegments[0] == 'viewPerson') {
      return await Person.fromId(deepLink.queryParameters['PersonId']);
    } else if (deepLink.pathSegments[0] == 'viewUser') {
      return await User.fromID(deepLink.queryParameters['UID']);
    } else if (deepLink.pathSegments[0] == 'viewQuery') {
      return QueryIcon();
    }
  } catch (err, stkTrace) {
    await FirebaseCrashlytics.instance
        .setCustomKey('LastErrorIn', 'Helpers.getLinkObject');
    await FirebaseCrashlytics.instance.recordError(err, stkTrace);
  }
  return null;
}

List<RadioListTile> getOrderingOptions(BuildContext context,
    BehaviorSubject<OrderOptions> orderOptions, int index) {
  Map source = index == 0
      ? Area.getStaticHumanReadableMap()
      : index == 1
          ? Street.getHumanReadableMap2()
          : index == 2
              ? Family.getHumanReadableMap2()
              : Person.getHumanReadableMap2();

  return source.entries
      .map(
        (e) => RadioListTile(
          value: e.key,
          groupValue: orderOptions.value.orderBy,
          title: Text(e.value),
          onChanged: (value) {
            orderOptions
                .add(OrderOptions(orderBy: value, asc: orderOptions.value.asc));
            Navigator.pop(context);
          },
        ),
      )
      .toList()
        ..addAll(
          [
            RadioListTile(
              value: 'true',
              groupValue: orderOptions.value.asc.toString(),
              title: Text('تصاعدي'),
              onChanged: (value) {
                orderOptions.add(OrderOptions(
                    orderBy: orderOptions.value.orderBy, asc: value == 'true'));
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              value: 'false',
              groupValue: orderOptions.value.asc.toString(),
              title: Text('تنازلي'),
              onChanged: (value) {
                orderOptions.add(OrderOptions(
                    orderBy: orderOptions.value.orderBy, asc: value == 'true'));
                Navigator.pop(context);
              },
            ),
          ],
        );
}

String getPhone(String phone, [bool whatsapp = true]) {
  if (phone.startsWith('+')) return phone.replaceFirst('+', '').trim();
  if (phone.startsWith('2')) return phone.trim();
  if (phone.startsWith('0') && whatsapp) return '2' + phone.trim();
  if (phone.startsWith('1') && whatsapp) return '21' + phone.trim();
  return phone.trim();
}

void import(BuildContext context) async {
  try {
    final picked = await FilePicker.platform.pickFiles(
        allowedExtensions: ['xlsx'], withData: true, type: FileType.custom);
    if (picked == null) return;
    final fileData = picked.files[0].bytes;
    final decoder = SpreadsheetDecoder.decodeBytes(fileData);
    if (decoder.tables.containsKey('Areas') &&
        decoder.tables.containsKey('Streets') &&
        decoder.tables.containsKey('Families') &&
        decoder.tables.containsKey('Persons')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('جار رفع الملف...'),
          duration: Duration(minutes: 9),
        ),
      );
      final filename = DateTime.now().toIso8601String();
      await FirebaseStorage.instance
          .ref('Imports/' + filename + '.xlsx')
          .putData(
              fileData,
              SettableMetadata(
                  customMetadata: {'createdBy': User.instance.uid}));
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('جار استيراد الملف...'),
          duration: Duration(minutes: 9),
        ),
      );
      await FirebaseFunctions.instance
          .httpsCallable('importFromExcel')
          .call({'fileId': filename + '.xlsx'});
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم الاستيراد بنجاح'),
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await showErrorDialog(context, 'ملف غير صالح');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await showErrorDialog(context, e.toString());
  }
}

Future importArea(
    SpreadsheetDecoder decoder, Area area, BuildContext context) async {
  try {
    WriteBatch batchUpdate = FirebaseFirestore.instance.batch();
    int batchCount = 1;
    List<String> keys;
    String uid = auth.FirebaseAuth.instance.currentUser.uid;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جار رفع البيانات ...'),
        duration: Duration(minutes: 5),
      ),
    );

    batchUpdate.set(
      area.ref,
      area.getMap(),
    );

    for (List<dynamic> row in decoder.tables['Areas'].rows) {
      if (keys == null) {
        keys = List<String>.from(
          row..removeAt(0),
        );
        continue;
      }

      if (batchCount % 500 == 0 && batchCount != 0) {
        await batchUpdate.commit().catchError((onError) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                onError.toString(),
              ),
              duration: Duration(seconds: 10),
            ),
          );
        });
        batchUpdate = FirebaseFirestore.instance.batch();
      }
      batchUpdate.set(
        FirebaseFirestore.instance.collection('Streets').doc(row[0]),
        Map.fromIterables(
            keys,
            List<String>.from(
              row..removeAt(0),
            )).map((key, value) {
          if (value == null) return MapEntry(key, null);
          if (key == 'Name')
            return MapEntry(
              key,
              value.toString(),
            );
          if (key == 'AreaId') return MapEntry(key, area.ref);
          if (key == 'Location')
            return MapEntry(
              key,
              value?.split(','),
            );
          if (key == 'LocationConfirmed') return MapEntry(key, value == 'true');
          if (key == 'Color')
            return MapEntry(key, value != null ? int.parse(value) : null);
          if (key == 'LastEdit') return MapEntry(key, uid);
          return MapEntry(
            key,
            Timestamp.fromMillisecondsSinceEpoch(int.parse(
              value.toString(),
            )),
          );
        }),
      );
      batchCount++;
    }

    keys = null;
    for (List<dynamic> row in decoder.tables['Families'].rows) {
      if (keys == null) {
        keys = List<String>.from(
          row..removeAt(0),
        );
        continue;
      }

      if (batchCount % 500 == 0 && batchCount != 0) {
        await batchUpdate.commit().catchError((onError) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                onError.toString(),
              ),
              duration: Duration(seconds: 10),
            ),
          );
        });
        batchUpdate = FirebaseFirestore.instance.batch();
      }
      batchUpdate.set(
        FirebaseFirestore.instance.collection('Families').doc(row[0]),
        Map.fromIterables(
            keys,
            List<String>.from(
              row..removeAt(0),
            )).map((key, value) {
          if (value == null) return MapEntry(key, null);
          if (key == 'AreaId') return MapEntry(key, area.ref);
          if (key == 'StreetId')
            return MapEntry(
              key,
              FirebaseFirestore.instance.doc('Streets/${value.toString()}'),
            );
          if (key == 'LastVisit' || key == 'FatherLastVisit')
            return MapEntry(
              key,
              Timestamp.fromMillisecondsSinceEpoch(int.parse(
                value.toString(),
              )),
            );
          if (key == 'Location')
            return MapEntry(
                key,
                value != null
                    ? GeoPoint(
                        double.parse(value.split(',')[0]),
                        double.parse(value.split(',')[1]),
                      )
                    : null);
          if (key == 'LocationConfirmed') return MapEntry(key, value == 'true');
          if (key == 'Color')
            return MapEntry(key, value != null ? int.parse(value) : null);
          if (key == 'LastEdit') return MapEntry(key, uid);
          return MapEntry(key, value);
        }),
      );
      batchCount++;
    }

    keys = null;
    bool end = false;
    for (List<dynamic> row in decoder.tables['Contacts'].rows) {
      if (keys == null) {
        keys = List<String>.from(
          row..removeAt(0),
        );
        continue;
      }
      if (batchCount % 500 == 0 && batchCount != 0) {
        await batchUpdate.commit().catchError((onError) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                onError.toString(),
              ),
              duration: Duration(seconds: 10),
            ),
          );
        }).then((k) {
          if (decoder.tables.values.elementAt(2).rows.indexOf(row) ==
              decoder.tables.values.elementAt(2).rows.length - 1) {
            end = true;
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'تم استيراد بيانات 1 منطقة و ${decoder.tables['Areas'].rows.length - 1}'
                    ' شارع و ${decoder.tables['Families'].rows.length - 1}'
                    ' عائلة و ${decoder.tables['Contacts'].rows.length - 1} شخص بنجاح'),
                duration: Duration(seconds: 4),
              ),
            );
          }
        });
        batchUpdate = FirebaseFirestore.instance.batch();
      }
      batchUpdate.set(
        FirebaseFirestore.instance.collection('Persons').doc(row[0]),
        Map.fromIterables(
            keys,
            List<String>.from(
              row..removeAt(0),
            )).map((key, value) {
          if (value == null) return MapEntry(key, null);
          if (key == 'FamilyId') {
            return MapEntry(
              key,
              FirebaseFirestore.instance.doc('Families/$value'),
            );
          } else if (key == 'StreetId') {
            return MapEntry(
              key,
              FirebaseFirestore.instance.doc('Streets/$value'),
            );
          } else if (key == 'AreaId' || key == 'ServingAreaId') {
            if (key == 'AreaId') return MapEntry(key, area.ref);
            return MapEntry(
              key,
              FirebaseFirestore.instance.doc('Areas/$value'),
            );
          } else if (key.contains('BirthDa') || key.startsWith('Last')) {
            return MapEntry(
                key,
                value != null
                    ? Timestamp.fromMillisecondsSinceEpoch(int.parse(
                        value.toString(),
                      ))
                    : null);
          } else if (key.startsWith('Is') || key == 'HasPhoto') {
            return MapEntry(key, value == 'true');
          } else if (key == 'StudyYear' || key == 'Job' || key == 'State') {
            return MapEntry(
              key,
              FirebaseFirestore.instance.doc('${key}s/$value'),
            );
          } else if (key == 'Church') {
            return MapEntry(
              key,
              FirebaseFirestore.instance.doc('${key}es/$value'),
            );
          } else if (key == 'CFather') {
            return MapEntry(
              key,
              FirebaseFirestore.instance.doc('Fathers/$value'),
            );
          } else if (key == 'ServantUserId') {
            return MapEntry(
              key,
              FirebaseFirestore.instance.doc('Users/$value'),
            );
          }
          if (key == 'Color')
            return MapEntry(key, value != null ? int.parse(value) : null);
          if (key == 'LastEdit') return MapEntry(key, uid);
          return MapEntry(key, value);
        }),
      );
      batchCount++;
    }

    if (!end) {
      await batchUpdate.commit().catchError((onError) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              onError.toString(),
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }).then((k) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'تم استيراد بيانات 1 منطقة و ${decoder.tables['Areas'].rows.length - 1}'
                ' شارع و ${decoder.tables['Families'].rows.length - 1}'
                ' عائلة و ${decoder.tables['Contacts'].rows.length - 1} شخص بنجاح'),
            duration: Duration(seconds: 4),
          ),
        );
      });
    }
  } on Exception catch (err, stkTrace) {
    await FirebaseCrashlytics.instance
        .setCustomKey('LastErrorIn', 'Helpers.importArea');
    await FirebaseCrashlytics.instance.recordError(err, stkTrace);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          err.toString(),
        ),
        duration: Duration(seconds: 10),
      ),
    );
  }
}

Future<void> showPendingMessage([BuildContext context]) async {
  context ??= mainScfld.currentContext;
  var pendingMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (pendingMessage != null) {
    // ignore: unawaited_futures
    Navigator.of(context).pushNamed('Notifications');
    if (pendingMessage.data['type'] == 'Message')
      await showMessage(
        context,
        no.Notification.fromMessage(pendingMessage.data),
      );
    else
      await processLink(Uri.parse(pendingMessage.data['attachement']), context);
  }
}

void onForegroundMessage(messaging_types.RemoteMessage message,
    [BuildContext context]) async {
  context ??= mainScfld.currentContext;
  bool opened = Hive.isBoxOpen('Notifications');
  if (!opened) await Hive.openBox<Map>('Notifications');
  await storeNotification(message);
  if (!opened) await Hive.box<Map>('Notifications').close();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message.notification.body),
      action: SnackBarAction(
        label: 'فتح الاشعارات',
        onPressed: () => Navigator.of(context).pushNamed('Notifications'),
      ),
    ),
  );
}

Future<int> storeNotification(messaging_types.RemoteMessage message) async {
  return await Hive.box<Map<dynamic, dynamic>>('Notifications')
      .add(message.data);
}

Future<void> onBackgroundMessage(messaging_types.RemoteMessage message) async {
  await Hive.initFlutter();
  await Hive.openBox<Map>('Notifications');
  await storeNotification(message);
  await Hive.close();
}

void personTap(Person person, BuildContext context) {
  Navigator.of(context).pushNamed('PersonInfo', arguments: person);
}

Future processClickedNotification(BuildContext context,
    [String payload]) async {
  var notificationDetails =
      await FlutterLocalNotificationsPlugin().getNotificationAppLaunchDetails();

  if (notificationDetails.didNotificationLaunchApp) {
    if ((notificationDetails.payload ?? payload) == 'Birthday') {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                var now = DateTime.now().millisecondsSinceEpoch;
                return SearchQuery(query: {
                  'parentIndex': '3',
                  'childIndex': '2',
                  'operatorIndex': '0',
                  'queryText': '',
                  'queryValue': 'T' +
                      (now - (now % Duration.millisecondsPerDay)).toString(),
                  'birthDate': 'false',
                  'descending': 'false',
                  'orderBy': 'BirthDay'
                });
              },
            ),
          );
        },
      );
    } else if ((notificationDetails.payload ?? payload) == 'Confessions') {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                var now = DateTime.now().millisecondsSinceEpoch;
                return SearchQuery(query: {
                  'parentIndex': '3',
                  'childIndex': '15',
                  'operatorIndex': '3',
                  'queryText': '',
                  'queryValue': 'T' +
                      ((now - (now % Duration.millisecondsPerDay)) -
                              (Duration.millisecondsPerDay * 7))
                          .toString(),
                  'birthDate': 'false',
                  'descending': 'false',
                  'orderBy': 'LastConfession'
                });
              },
            ),
          );
        },
      );
    } else if ((notificationDetails.payload ?? payload) == 'Tanawol') {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                var now = DateTime.now().millisecondsSinceEpoch;
                return SearchQuery(query: {
                  'parentIndex': '3',
                  'childIndex': '14',
                  'operatorIndex': '3',
                  'queryText': '',
                  'queryValue': 'T' +
                      ((now - (now % Duration.millisecondsPerDay)) -
                              (Duration.millisecondsPerDay * 7))
                          .toString(),
                  'birthDate': 'false',
                  'descending': 'false',
                  'orderBy': 'LastTanawol'
                });
              },
            ),
          );
        },
      );
    }
  } else
    return;
}

Future processLink(Uri deepLink, BuildContext context) async {
  try {
    if (deepLink.pathSegments[0] == 'viewArea') {
      areaTap(
          Area.fromDoc(
            await FirebaseFirestore.instance
                .doc('Areas/${deepLink.queryParameters['AreaId']}')
                .get(),
          ),
          context);
    } else if (deepLink.pathSegments[0] == 'viewStreet') {
      streetTap(
          Street.fromDoc(
            await FirebaseFirestore.instance
                .doc('Streets/${deepLink.queryParameters['StreetId']}')
                .get(),
          ),
          context);
    } else if (deepLink.pathSegments[0] == 'viewFamily') {
      familyTap(
          Family.fromDoc(
            await FirebaseFirestore.instance
                .doc('Families/${deepLink.queryParameters['FamilyId']}')
                .get(),
          ),
          context);
    } else if (deepLink.pathSegments[0] == 'viewPerson') {
      personTap(
          Person.fromDoc(
            await FirebaseFirestore.instance
                .doc('Persons/${deepLink.queryParameters['PersonId']}')
                .get(),
          ),
          context);
    } else if (deepLink.pathSegments[0] == 'viewQuery') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (c) => SearchQuery(
            query: deepLink.queryParameters,
          ),
        ),
      );
    } else if (deepLink.pathSegments[0] == 'viewUser') {
      if (User.instance.manageUsers) {
        userTap(await User.fromID(deepLink.queryParameters['UID']), context);
      } else {
        await showErrorDialog(
            context, 'ليس لديك الصلاحية لرؤية محتويات الرابط!');
      }
    } else {
      await showErrorDialog(context, 'رابط غير صالح!');
    }
  } catch (err, stcTrace) {
    if (err.toString().contains('PERMISSION_DENIED')) {
      await showErrorDialog(context, 'ليس لديك الصلاحية لرؤية محتويات الرابط!');
    } else {
      await showErrorDialog(context, 'حدث خطأ! أثناء قراءة محتويات الرابط');
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'Helpers.processLink');
      await FirebaseCrashlytics.instance.recordError(err, stcTrace);
    }
  }
}

void sendNotification(BuildContext context, dynamic attachement) async {
  BehaviorSubject<String> search = BehaviorSubject<String>.seeded('');
  List<User> users = await showDialog(
    context: context,
    builder: (context) {
      return MultiProvider(
        providers: [
          Provider(
              create: (_) => DataObjectListOptions<User>(
                  selectionMode: true,
                  searchQuery: search,
                  itemsStream: Stream.fromFuture(User.getAllUsersLive())
                      .map((s) => s.docs.map(User.fromDoc).toList()))),
        ],
        builder: (context, child) => AlertDialog(
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                    context,
                    context
                        .read<DataObjectListOptions<User>>()
                        .selectedLatest
                        .values
                        .toList());
              },
              child: Text('تم'),
            )
          ],
          content: Container(
            width: 280,
            child: UsersList(),
          ),
        ),
      );
    },
  );
  var title = TextEditingController();
  var content = TextEditingController();
  if (users != null &&
      await showDialog(
            context: context,
            builder: (context) {
              return DataDialog(
                actions: <Widget>[
                  TextButton.icon(
                    icon: Icon(Icons.send),
                    onPressed: () => Navigator.of(context).pop(true),
                    label: Text('ارسال'),
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.cancel),
                    onPressed: () => Navigator.of(context).pop(false),
                    label: Text('الغاء الأمر'),
                  ),
                ],
                title: Text('انشاء رسالة'),
                content: Column(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'عنوان الرسالة',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor),
                          ),
                        ),
                        controller: title,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'هذا الحقل مطلوب';
                          }
                          return null;
                        },
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'محتوى الرسالة',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor),
                            ),
                          ),
                          textInputAction: TextInputAction.newline,
                          maxLines: null,
                          controller: content,
                          expands: true,
                        ),
                      ),
                    ),
                    Text('سيتم ارفاق ${attachement.name} مع الرسالة')
                  ],
                ),
              );
            },
          ) ==
          true) {
    String link = '';
    if (attachement is Area) {
      link = 'Area?AreaId=${attachement.id}';
    } else if (attachement is Street) {
      link = 'Street?StreetId=${attachement.id}';
    } else if (attachement is Family) {
      link = 'Family?FamilyId=${attachement.id}';
    } else if (attachement is Person) {
      link = 'Person?PersonId=${attachement.id}';
    }
    await FirebaseFunctions.instance.httpsCallable('sendMessageToUsers').call({
      'users': users.map((e) => e.uid).toList(),
      'title': title.text,
      'body': 'أرسل إليك ${User.instance.name} رسالة',
      'content': content.text,
      'attachement': 'https://churchdata.page.link/view$link'
    });
    // else
    // await functions().httpsCallable('sendMessageToUsers').call({
    //   'users': users.map((e) => e.uid).toList(),
    //   'title': title.text,
    //   'body': 'أرسل إليك ${(await User.getCurrentUser()).name} رسالة',
    //   'content': content.text,
    //   'attachement': 'https://churchdata.page.link/view$link'
    // });
  }
}

Future<String> shareArea(Area area) async => await shareAreaRaw(area.id);

Future<String> shareAreaRaw(String id) async {
  return (await DynamicLinkParameters(
    uriPrefix: uriPrefix,
    link: Uri.parse('https://churchdata.com/viewArea?AreaId=$id'),
    androidParameters: androidParameters,
    dynamicLinkParametersOptions: dynamicLinkParametersOptions,
    iosParameters: iosParameters,
  ).buildShortLink())
      .shortUrl
      .toString();
}

Future<String> shareDataObject(DataObject obj) async {
  if (obj is Area) return await shareArea(obj);
  if (obj is Street) return await shareStreet(obj);
  if (obj is Family) return await shareFamily(obj);
  if (obj is Person) return await sharePerson(obj);
  throw UnimplementedError();
}

Future<String> shareFamily(Family family) async =>
    await shareFamilyRaw(family.id);

Future<String> shareFamilyRaw(String id) async {
  return (await DynamicLinkParameters(
    uriPrefix: uriPrefix,
    link: Uri.parse('https://churchdata.com/viewFamily?FamilyId=$id'),
    androidParameters: androidParameters,
    dynamicLinkParametersOptions: dynamicLinkParametersOptions,
    iosParameters: iosParameters,
  ).buildShortLink())
      .shortUrl
      .toString();
}

Future<String> sharePerson(Person person) async {
  return await sharePersonRaw(person.id);
}

Future<String> sharePersonRaw(String id) async {
  return (await DynamicLinkParameters(
    uriPrefix: uriPrefix,
    link: Uri.parse('https://churchdata.com/viewPerson?PersonId=$id'),
    androidParameters: androidParameters,
    dynamicLinkParametersOptions: dynamicLinkParametersOptions,
    iosParameters: iosParameters,
  ).buildShortLink())
      .shortUrl
      .toString();
}

Future<String> shareQuery(Map<String, String> query) async {
  return (await DynamicLinkParameters(
    uriPrefix: uriPrefix,
    link: Uri.https('churchdata.com', 'viewQuery', query),
    androidParameters: androidParameters,
    dynamicLinkParametersOptions: dynamicLinkParametersOptions,
    iosParameters: iosParameters,
  ).buildShortLink())
      .shortUrl
      .toString();
}

Future<String> shareStreet(Street street) async =>
    await shareStreetRaw(street.id);

Future<String> shareStreetRaw(String id) async {
  return (await DynamicLinkParameters(
    uriPrefix: uriPrefix,
    link: Uri.parse('https://churchdata.com/viewStreet?StreetId=$id'),
    androidParameters: androidParameters,
    dynamicLinkParametersOptions: dynamicLinkParametersOptions,
    iosParameters: iosParameters,
  ).buildShortLink())
      .shortUrl
      .toString();
}

Future<String> shareUser(User user) async => await shareUserRaw(user.uid);

Future<String> shareUserRaw(String uid) async {
  return (await DynamicLinkParameters(
    uriPrefix: uriPrefix,
    link: Uri.parse('https://churchdata.com/viewUser?UID=$uid'),
    androidParameters: androidParameters,
    dynamicLinkParametersOptions: dynamicLinkParametersOptions,
    iosParameters: iosParameters,
  ).buildShortLink())
      .shortUrl
      .toString();
}

Future showErrorDialog(BuildContext context, String message,
    {String title}) async {
  return await showDialog(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) => AlertDialog(
      title: title != null ? Text(title) : null,
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('حسنًا'),
        ),
      ],
    ),
  );
}

Future showErrorUpdateDataDialog(
    {BuildContext context, bool pushApp = true}) async {
  if (pushApp ||
      Hive.box('Settings').get('DialogLastShown') !=
          tranucateToDay().millisecondsSinceEpoch) {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
            'العجيب أننا اليوم نقضى كل وقتنا فى الخدمة . أما هؤلاء القديسون'
            ' فكانوا يعيشون أغلب حياتهم فى التوبة والاتحاد بالله ثم ينزلون'
            ' فى خدمة هجومية صاروخية'
            ' إلى معاقل الشر وبعد الانتهاء منها يرجعون فوراً إلى عزلتهم ،'
            ' وأحياناً تكون معهم فريستهم وصيدهم\n'
            'أبونا بيشوي كامل\n'
            'يرجي مراجعة حياتك الروحية والاهتمام بها'),
        actions: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              shape: StadiumBorder(
                side: BorderSide(color: primaries[13]),
              ),
            ),
            onPressed: () async {
              var userPerson = await User.getCurrentPerson();
              await Navigator.of(context)
                  .pushNamed('UpdateUserDataError', arguments: userPerson);
              userPerson = await User.getCurrentPerson();
              if (userPerson != null &&
                  ((userPerson.lastTanawol.millisecondsSinceEpoch +
                              2592000000) >
                          DateTime.now().millisecondsSinceEpoch &&
                      (userPerson.lastConfession.millisecondsSinceEpoch +
                              5184000000) >
                          DateTime.now().millisecondsSinceEpoch)) {
                Navigator.pop(context);
                if (pushApp)
                  // ignore: unawaited_futures
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => App(),
                      ));
              }
            },
            icon: Icon(Icons.update),
            label: Text('تحديث بيانات التناول والاعتراف'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close),
            label: Text('تم'),
          ),
        ],
      ),
    );
    await Hive.box('Settings')
        .put('DialogLastShown', tranucateToDay().millisecondsSinceEpoch);
  }
}

void showLoadingDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('جار التحميل...'),
          CircularProgressIndicator(),
        ],
      ),
    ),
  );
}

Future<void> showMessage(
    BuildContext context, no.Notification notification) async {
  var attachement = await getLinkObject(
    Uri.parse(notification.attachement),
  );
  String scndLine = await attachement.getSecondLine() ?? '';
  var user = notification.from != ''
      ? await FirebaseFirestore.instance
          .doc('Users/${notification.from}')
          .get(dataSource)
      : null;
  await showDialog(
    context: context,
    builder: (context) => DataDialog(
      title: Text(notification.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            notification.content,
            style: TextStyle(fontSize: 18),
          ),
          if (user != null)
            Card(
              color: attachement.color != Colors.transparent
                  ? attachement.color
                  : null,
              child: ListTile(
                title: Text(attachement.name),
                subtitle: Text(
                  scndLine,
                ),
                leading: attachement is User
                    ? attachement.getPhoto()
                    : attachement.photo,
                onTap: () {
                  if (attachement is Area) {
                    areaTap(attachement, context);
                  } else if (attachement is Street) {
                    streetTap(attachement, context);
                  } else if (attachement is Family) {
                    familyTap(attachement, context);
                  } else if (attachement is Person) {
                    personTap(attachement, context);
                  } else if (attachement is User) {
                    userTap(attachement, context);
                  }
                },
              ),
            )
          else
            CachedNetworkImage(imageUrl: attachement.url),
          Text('من: ' +
              (user != null
                  ? User.fromDoc(
                      user,
                    ).name
                  : 'مسؤلو البرنامج')),
          Text(
            DateFormat('yyyy/M/d h:m a', 'ar-EG').format(
              DateTime.fromMillisecondsSinceEpoch(notification.time),
            ),
          ),
        ],
      ),
    ),
  );
}

void streetTap(Street street, BuildContext context) {
  Navigator.of(context).pushNamed('StreetInfo', arguments: street);
}

String toDurationString(Timestamp date, {appendSince = true}) {
  if (date == null) return '';
  if (appendSince) return format(date.toDate(), locale: 'ar');
  return format(date.toDate(), locale: 'ar').replaceAll('منذ ', '');
}

Timestamp tranucateToDay({DateTime time}) {
  time = time ?? DateTime.now();
  return Timestamp.fromMillisecondsSinceEpoch(
    time.millisecondsSinceEpoch -
        time.millisecondsSinceEpoch.remainder(Duration.millisecondsPerDay),
  );
}

void userTap(User user, BuildContext context) async {
  if (user.approved) {
    await Navigator.of(context).pushNamed('UserInfo', arguments: user);
  } else {
    dynamic rslt = await showDialog(
        context: context,
        builder: (context) => DataDialog(
              actions: <Widget>[
                if (user.personRef != null)
                  TextButton.icon(
                    icon: Icon(Icons.info),
                    label: Text('اظهار استمارة البيانات'),
                    onPressed: () async => Navigator.of(context).pushNamed(
                      'PersonInfo',
                      arguments: await user.getPerson(),
                    ),
                  ),
                TextButton.icon(
                  icon: Icon(Icons.done),
                  label: Text('نعم'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                TextButton.icon(
                  icon: Icon(Icons.close),
                  label: Text('لا'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton.icon(
                  icon: Icon(Icons.close),
                  label: Text('حذف المستخدم'),
                  onPressed: () => Navigator.of(context).pop('delete'),
                ),
              ],
              title: Text('${user.name} غير مُنشط هل تريد تنشيطه؟'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  user.getPhoto(false),
                  Text(
                    'البريد الاكتروني: ' + (user.email ?? ''),
                  ),
                ],
              ),
            ));
    if (rslt == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: LinearProgressIndicator(),
          duration: Duration(seconds: 15),
        ),
      );
      try {
        await FirebaseFunctions.instance
            .httpsCallable('approveUser')
            .call({'affectedUser': user.uid});
        user.approved = true;
        // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
        user.notifyListeners();
        userTap(user, context);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم بنجاح'),
            duration: Duration(seconds: 15),
          ),
        );
      } catch (err, stkTrace) {
        await FirebaseCrashlytics.instance
            .setCustomKey('LastErrorIn', 'Data.userTap');
        await FirebaseCrashlytics.instance.recordError(err, stkTrace);
      }
    } else if (rslt == 'delete') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: LinearProgressIndicator(),
          duration: Duration(seconds: 15),
        ),
      );
      try {
        await FirebaseFunctions.instance
            .httpsCallable('deleteUser')
            .call({'affectedUser': user.uid});
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم بنجاح'),
            duration: Duration(seconds: 15),
          ),
        );
      } catch (err, stkTrace) {
        await FirebaseCrashlytics.instance
            .setCustomKey('LastErrorIn', 'Data.userTap');
        await FirebaseCrashlytics.instance.recordError(err, stkTrace);
      }
    }
  }
}

class QueryIcon extends StatelessWidget {
  Color get color => Colors.transparent;
  String get name => 'نتائج بحث';

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.search,
        size: MediaQuery.of(context).size.shortestSide / 7.2);
  }

  Widget getPhoto(BuildContext context) {
    return build(context);
  }

  Future<String> getSecondLine() async => '';
}

class MessageIcon extends StatelessWidget {
  final String url;
  MessageIcon(this.url, {Key key}) : super(key: key);

  Future<String> getSecondLine() async => '';
  Color get color => Colors.transparent;
  String get name => '';

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints.expand(width: 55.2, height: 55.2),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => showDialog(
            context: context,
            builder: (context) => Dialog(
              child: Hero(
                tag: url,
                child: CachedNetworkImage(
                  imageUrl: url,
                  imageBuilder: (context, imageProvider) => PhotoView(
                    imageProvider: imageProvider,
                    tightMode: true,
                    enableRotation: true,
                  ),
                  progressIndicatorBuilder: (context, url, progress) =>
                      CircularProgressIndicator(value: progress.progress),
                ),
              ),
            ),
          ),
          child: CachedNetworkImage(
            memCacheHeight: 221,
            imageUrl: url,
            progressIndicatorBuilder: (context, url, progress) =>
                CircularProgressIndicator(value: progress.progress),
          ),
        ),
      ),
    );
  }

  Widget getPhoto(BuildContext context) {
    return build(context);
  }
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}
