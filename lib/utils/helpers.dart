import 'dart:async';
import 'dart:io' if (dart.library.html) 'dart:html';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/data_dialog.dart';
import 'package:churchdata/models/data_object_widget.dart';
import 'package:churchdata/models/family.dart';
import 'package:churchdata/models/list.dart';
import 'package:churchdata/models/person.dart';
import 'package:churchdata/models/search_filters.dart';
import 'package:churchdata/models/street.dart';
import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:churchdata/views/mini_lists/users_list.dart';
import 'package:churchdata/views/search_query.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_storage/firebase_storage.dart' hide ListOptions;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:timeago/timeago.dart';

import '../main.dart';
import '../models/list_controllers.dart';
import '../models/super_classes.dart';
import '../models/user.dart';
import 'globals.dart';

void areaTap(Area area) {
  navigator.currentState!.pushNamed('AreaInfo', arguments: area);
}

void dataObjectTap(DataObject obj) {
  if (obj is Area)
    areaTap(obj);
  else if (obj is Street)
    streetTap(obj);
  else if (obj is Family)
    familyTap(obj);
  else if (obj is Person)
    personTap(obj);
  else if (obj is User)
    userTap(obj);
  else
    throw UnimplementedError();
}

void familyTap(Family family) {
  navigator.currentState!.pushNamed('FamilyInfo', arguments: family);
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
      return MessageIcon(deepLink.queryParameters['url']!);
    } else if (deepLink.pathSegments[0] == 'viewArea') {
      return await Area.fromId(deepLink.queryParameters['AreaId']!);
    } else if (deepLink.pathSegments[0] == 'viewStreet') {
      return await Street.fromId(deepLink.queryParameters['StreetId']!);
    } else if (deepLink.pathSegments[0] == 'viewFamily') {
      return await Family.fromId(deepLink.queryParameters['FamilyId']!);
    } else if (deepLink.pathSegments[0] == 'viewPerson') {
      return await Person.fromId(deepLink.queryParameters['PersonId']!);
    } else if (deepLink.pathSegments[0] == 'viewUser') {
      return await User.fromID(deepLink.queryParameters['UID']!);
    } else if (deepLink.pathSegments[0] == 'viewQuery') {
      return const QueryIcon();
    }
  } catch (err, stkTrace) {
    await FirebaseCrashlytics.instance
        .setCustomKey('LastErrorIn', 'Helpers.getLinkObject');
    await FirebaseCrashlytics.instance.recordError(err, stkTrace);
  }
  return null;
}

List<RadioListTile> getOrderingOptions(
  BehaviorSubject<OrderOptions> orderOptions,
  int? index,
) {
  final Json source = index == 0
      ? Area.getStaticHumanReadableMap()
      : index == 1
          ? Street.getHumanReadableMap2()
          : index == 2
              ? Family.getHumanReadableMap2()
              : Person.getHumanReadableMap2();

  return source.entries
      .map(
        (e) => RadioListTile<String>(
          value: e.key,
          groupValue: orderOptions.value.orderBy,
          title: Text(e.value),
          onChanged: (value) {
            orderOptions.add(
              OrderOptions(orderBy: value!, asc: orderOptions.value.asc),
            );
            navigator.currentState!.pop();
          },
        ),
      )
      .toList()
    ..addAll(
      [
        RadioListTile(
          value: 'true',
          groupValue: orderOptions.value.asc.toString(),
          title: const Text('تصاعدي'),
          onChanged: (value) {
            orderOptions.add(
              OrderOptions(
                orderBy: orderOptions.value.orderBy,
                asc: value == 'true',
              ),
            );
            navigator.currentState!.pop();
          },
        ),
        RadioListTile(
          value: 'false',
          groupValue: orderOptions.value.asc.toString(),
          title: const Text('تنازلي'),
          onChanged: (value) {
            orderOptions.add(
              OrderOptions(
                orderBy: orderOptions.value.orderBy,
                asc: value == 'true',
              ),
            );
            navigator.currentState!.pop();
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

DateTime getRiseDay([int? year]) {
  year ??= DateTime.now().year;
  final int a = year % 4;
  final int b = year % 7;
  final int c = year % 19;
  final int d = (19 * c + 15) % 30;
  final int e = (2 * a + 4 * b - d + 34) % 7;

  return DateTime(year, (d + e + 114) ~/ 31, ((d + e + 114) % 31) + 14);
}

Future<void> import(BuildContext context) async {
  try {
    final picked = await FilePicker.platform.pickFiles(
      allowedExtensions: ['xlsx'],
      withData: true,
      type: FileType.custom,
    );
    if (picked == null) return;
    final fileData = picked.files[0].bytes;
    final decoder = SpreadsheetDecoder.decodeBytes(fileData!);
    if (decoder.tables.containsKey('Areas') &&
        decoder.tables.containsKey('Streets') &&
        decoder.tables.containsKey('Families') &&
        decoder.tables.containsKey('Persons')) {
      scaffoldMessenger.currentState!.showSnackBar(
        const SnackBar(
          content: Text('جار رفع الملف...'),
          duration: Duration(minutes: 9),
        ),
      );
      final filename = DateTime.now().toIso8601String();
      await firebaseStorage.ref('Imports/' + filename + '.xlsx').putData(
            fileData,
            SettableMetadata(customMetadata: {'createdBy': User.instance.uid!}),
          );
      scaffoldMessenger.currentState!.hideCurrentSnackBar();
      scaffoldMessenger.currentState!.showSnackBar(
        const SnackBar(
          content: Text('جار استيراد الملف...'),
          duration: Duration(minutes: 9),
        ),
      );
      await firebaseFunctions
          .httpsCallable('importFromExcel')
          .call({'fileId': filename + '.xlsx'});
      scaffoldMessenger.currentState!.hideCurrentSnackBar();
      scaffoldMessenger.currentState!.showSnackBar(
        const SnackBar(
          content: Text('تم الاستيراد بنجاح'),
        ),
      );
    } else {
      scaffoldMessenger.currentState!.hideCurrentSnackBar();
      await showErrorDialog(context, 'ملف غير صالح');
    }
  } catch (e) {
    scaffoldMessenger.currentState!.hideCurrentSnackBar();
    await showErrorDialog(context, e.toString());
  }
}

Future importArea(
  SpreadsheetDecoder decoder,
  Area area,
  BuildContext context,
) async {
  try {
    WriteBatch batchUpdate = firestore.batch();
    int batchCount = 1;
    List<String>? keys;
    final String uid = User.instance.uid!;

    scaffoldMessenger.currentState!.hideCurrentSnackBar();
    scaffoldMessenger.currentState!.showSnackBar(
      const SnackBar(
        content: Text('جار رفع البيانات ...'),
        duration: Duration(minutes: 5),
      ),
    );

    batchUpdate.set(
      area.ref,
      area.getMap(),
    );

    for (final List<dynamic> row in decoder.tables['Areas']!.rows) {
      if (keys == null) {
        keys = List<String>.from(
          row..removeAt(0),
        );
        continue;
      }

      if (batchCount % 500 == 0 && batchCount != 0) {
        await batchUpdate.commit().catchError((onError) {
          scaffoldMessenger.currentState!.hideCurrentSnackBar();
          scaffoldMessenger.currentState!.showSnackBar(
            SnackBar(
              content: Text(
                onError.toString(),
              ),
              duration: const Duration(seconds: 10),
            ),
          );
        });
        batchUpdate = firestore.batch();
      }
      batchUpdate.set(
        firestore.collection('Streets').doc(row[0]),
        Map.fromIterables(
          keys,
          List<String?>.from(
            row..removeAt(0),
          ),
        ).map((key, value) {
          if (value == null) return MapEntry(key, null);
          if (key == 'Name')
            return MapEntry(
              key,
              value,
            );
          if (key == 'AreaId') return MapEntry(key, area.ref);
          if (key == 'Location')
            return MapEntry(
              key,
              value.split(','),
            );
          if (key == 'LocationConfirmed') return MapEntry(key, value == 'true');
          if (key == 'Color') return MapEntry(key, int.parse(value));
          if (key == 'LastEdit') return MapEntry(key, uid);
          return MapEntry(
            key,
            Timestamp.fromMillisecondsSinceEpoch(
              int.parse(
                value,
              ),
            ),
          );
        }),
      );
      batchCount++;
    }

    keys = null;
    for (final List<dynamic> row in decoder.tables['Families']!.rows) {
      if (keys == null) {
        keys = List<String>.from(
          row..removeAt(0),
        );
        continue;
      }

      if (batchCount % 500 == 0 && batchCount != 0) {
        await batchUpdate.commit().catchError((onError) {
          scaffoldMessenger.currentState!.hideCurrentSnackBar();
          scaffoldMessenger.currentState!.showSnackBar(
            SnackBar(
              content: Text(
                onError.toString(),
              ),
              duration: const Duration(seconds: 10),
            ),
          );
        });
        batchUpdate = firestore.batch();
      }
      batchUpdate.set(
        firestore.collection('Families').doc(row[0]),
        Map.fromIterables(
          keys,
          List<String?>.from(
            row..removeAt(0),
          ),
        ).map((key, value) {
          if (value == null) return MapEntry(key, null);
          if (key == 'AreaId') return MapEntry(key, area.ref);
          if (key == 'StreetId')
            return MapEntry(
              key,
              firestore.doc('Streets/$value'),
            );
          if (key == 'LastVisit' || key == 'FatherLastVisit')
            return MapEntry(
              key,
              Timestamp.fromMillisecondsSinceEpoch(
                int.parse(
                  value,
                ),
              ),
            );
          if (key == 'Location')
            return MapEntry(
              key,
              GeoPoint(
                double.parse(value.split(',')[0]),
                double.parse(value.split(',')[1]),
              ),
            );
          if (key == 'LocationConfirmed') return MapEntry(key, value == 'true');
          if (key == 'Color') return MapEntry(key, int.parse(value));
          if (key == 'LastEdit') return MapEntry(key, uid);
          return MapEntry(key, value);
        }),
      );
      batchCount++;
    }

    keys = null;
    bool end = false;
    for (final List<dynamic> row in decoder.tables['Contacts']!.rows) {
      if (keys == null) {
        keys = List<String>.from(
          row..removeAt(0),
        );
        continue;
      }
      if (batchCount % 500 == 0 && batchCount != 0) {
        await batchUpdate.commit().catchError((onError) {
          scaffoldMessenger.currentState!.hideCurrentSnackBar();
          scaffoldMessenger.currentState!.showSnackBar(
            SnackBar(
              content: Text(
                onError.toString(),
              ),
              duration: const Duration(seconds: 10),
            ),
          );
        }).then((k) {
          if (decoder.tables.values.elementAt(2).rows.indexOf(row) ==
              decoder.tables.values.elementAt(2).rows.length - 1) {
            end = true;
            scaffoldMessenger.currentState!.hideCurrentSnackBar();
            scaffoldMessenger.currentState!.showSnackBar(
              SnackBar(
                content: Text(
                    'تم استيراد بيانات 1 منطقة و ${decoder.tables['Areas']!.rows.length - 1}'
                    ' شارع و ${decoder.tables['Families']!.rows.length - 1}'
                    ' عائلة و ${decoder.tables['Contacts']!.rows.length - 1} شخص بنجاح'),
              ),
            );
          }
        });
        batchUpdate = firestore.batch();
      }
      batchUpdate.set(
        firestore.collection('Persons').doc(row[0]),
        Map.fromIterables(
          keys,
          List<String?>.from(
            row..removeAt(0),
          ),
        ).map((key, value) {
          if (value == null) return MapEntry(key, null);
          if (key == 'FamilyId') {
            return MapEntry(
              key,
              firestore.doc('Families/$value'),
            );
          } else if (key == 'StreetId') {
            return MapEntry(
              key,
              firestore.doc('Streets/$value'),
            );
          } else if (key == 'AreaId' || key == 'ServingAreaId') {
            if (key == 'AreaId') return MapEntry(key, area.ref);
            return MapEntry(
              key,
              firestore.doc('Areas/$value'),
            );
          } else if (key.contains('BirthDa') || key.startsWith('Last')) {
            return MapEntry(
              key,
              Timestamp.fromMillisecondsSinceEpoch(
                int.parse(
                  value,
                ),
              ),
            );
          } else if (key.startsWith('Is') || key == 'HasPhoto') {
            return MapEntry(key, value == 'true');
          } else if (key == 'StudyYear' || key == 'Job' || key == 'State') {
            return MapEntry(
              key,
              firestore.doc('${key}s/$value'),
            );
          } else if (key == 'Church') {
            return MapEntry(
              key,
              firestore.doc('${key}es/$value'),
            );
          } else if (key == 'CFather') {
            return MapEntry(
              key,
              firestore.doc('Fathers/$value'),
            );
          } else if (key == 'ServantUserId') {
            return MapEntry(
              key,
              firestore.doc('Users/$value'),
            );
          }
          if (key == 'Color') return MapEntry(key, int.parse(value));
          if (key == 'LastEdit') return MapEntry(key, uid);
          return MapEntry(key, value);
        }),
      );
      batchCount++;
    }

    if (!end) {
      await batchUpdate.commit().catchError((onError) {
        scaffoldMessenger.currentState!.hideCurrentSnackBar();
        scaffoldMessenger.currentState!.showSnackBar(
          SnackBar(
            content: Text(
              onError.toString(),
            ),
            duration: const Duration(seconds: 10),
          ),
        );
      }).then((k) {
        scaffoldMessenger.currentState!.hideCurrentSnackBar();
        scaffoldMessenger.currentState!.showSnackBar(
          SnackBar(
            content: Text(
                'تم استيراد بيانات 1 منطقة و ${decoder.tables['Areas']!.rows.length - 1}'
                ' شارع و ${decoder.tables['Families']!.rows.length - 1}'
                ' عائلة و ${decoder.tables['Contacts']!.rows.length - 1} شخص بنجاح'),
          ),
        );
      });
    }
  } on Exception catch (err, stkTrace) {
    await FirebaseCrashlytics.instance
        .setCustomKey('LastErrorIn', 'Helpers.importArea');
    await FirebaseCrashlytics.instance.recordError(err, stkTrace);
    scaffoldMessenger.currentState!.hideCurrentSnackBar();
    scaffoldMessenger.currentState!.showSnackBar(
      SnackBar(
        content: Text(
          err.toString(),
        ),
        duration: const Duration(seconds: 10),
      ),
    );
  }
}

void personTap(Person person) {
  navigator.currentState!.pushNamed('PersonInfo', arguments: person);
}

Future processLink(Uri deepLink) async {
  try {
    if (deepLink.pathSegments[0] == 'viewArea') {
      areaTap(
        Area.fromDoc(
          await firestore
              .doc('Areas/${deepLink.queryParameters['AreaId']}')
              .get(),
        )!,
      );
    } else if (deepLink.pathSegments[0] == 'viewStreet') {
      streetTap(
        Street.fromDoc(
          await firestore
              .doc('Streets/${deepLink.queryParameters['StreetId']}')
              .get(),
        )!,
      );
    } else if (deepLink.pathSegments[0] == 'viewFamily') {
      familyTap(
        Family.fromDoc(
          await firestore
              .doc('Families/${deepLink.queryParameters['FamilyId']}')
              .get(),
        )!,
      );
    } else if (deepLink.pathSegments[0] == 'viewPerson') {
      personTap(
        Person.fromDoc(
          await firestore
              .doc('Persons/${deepLink.queryParameters['PersonId']}')
              .get(),
        )!,
      );
    } else if (deepLink.pathSegments[0] == 'viewQuery') {
      await navigator.currentState!.push(
        MaterialPageRoute(
          builder: (c) => SearchQuery(
            query: deepLink.queryParameters,
          ),
        ),
      );
    } else if (deepLink.pathSegments[0] == 'viewUser') {
      if (User.instance.manageUsers) {
        unawaited(userTap(await User.fromID(deepLink.queryParameters['UID']!)));
      } else {
        await showErrorDialog(
          navigator.currentContext!,
          'ليس لديك الصلاحية لرؤية محتويات الرابط!',
        );
      }
    } else {
      await showErrorDialog(navigator.currentContext!, 'رابط غير صالح!');
    }
  } catch (err, stcTrace) {
    if (err.toString().contains('PERMISSION_DENIED')) {
      await showErrorDialog(
        navigator.currentContext!,
        'ليس لديك الصلاحية لرؤية محتويات الرابط!',
      );
    } else {
      await showErrorDialog(
        navigator.currentContext!,
        'حدث خطأ! أثناء قراءة محتويات الرابط',
      );
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'Helpers.processLink');
      await FirebaseCrashlytics.instance.recordError(err, stcTrace);
    }
  }
}

Future<void> recoverDoc(BuildContext context, String path) async {
  bool nested = false;
  bool keepBackup = true;
  if (await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          actions: [
            TextButton(
              onPressed: () => navigator.currentState!.pop(true),
              child: const Text('استرجاع'),
            ),
          ],
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: nested,
                        onChanged: (v) => setState(() => nested = v!),
                      ),
                      const Text(
                        'استرجع ايضا العناصر بداخل هذا العنصر',
                        textScaler: TextScaler.linear(0.9),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: keepBackup,
                        onChanged: (v) => setState(() => keepBackup = v!),
                      ),
                      const Text('ابقاء البيانات المحذوفة'),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ) ==
      true) {
    try {
      await firebaseFunctions.httpsCallable('recoverDoc').call({
        'deletedPath': path,
        'keepBackup': keepBackup,
        'nested': nested,
      });
      scaffoldMessenger.currentState!
          .showSnackBar(const SnackBar(content: Text('تم الاسترجاع بنجاح')));
    } catch (err, stcTrace) {
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'helpers.recoverDoc');
      await FirebaseCrashlytics.instance.recordError(err, stcTrace);
    }
  }
}

Future<List<Area>?> selectAreas(BuildContext context, List<Area> areas) async {
  final _options = DataObjectListController<Area>(
    itemsStream:
        Area.getAllForUser().map((s) => s.docs.map(Area.fromQueryDoc).toList()),
    selectionMode: true,
    onLongPress: (_) {},
    selected: {for (final a in areas) a.id: a},
    searchQuery: Stream.value(''),
  );
  if (await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('اختر المناطق'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.done),
                  onPressed: () => navigator.currentState!.pop(true),
                  tooltip: 'تم',
                ),
              ],
            ),
            body: DataObjectList<Area>(
              options: _options,
              autoDisposeController: true,
            ),
          ),
        ),
      ) ==
      true) {
    return _options.selected.value.values.toList();
  }
  return null;
}

Future<void> sendNotification(BuildContext context, dynamic attachement) async {
  final List<User>? users = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) {
        return MultiProvider(
          providers: [
            Provider<DataObjectListController<User>>(
              create: (_) => DataObjectListController<User>(
                itemBuilder: (
                  current, [
                  void Function(User)? onLongPress,
                  void Function(User)? onTap,
                  trailing,
                  subtitle,
                ]) =>
                    DataObjectWidget(
                  current,
                  onTap: () => onTap!(current),
                  trailing: trailing,
                  showSubtitle: false,
                ),
                selectionMode: true,
                itemsStream: firestore.collection('Users').snapshots().map(
                      (s) => s.docs
                          .map((e) => User.fromQueryDoc(e)..uid = e.id)
                          .toList(),
                    ),
              ),
              dispose: (context, c) => c.dispose(),
            ),
          ],
          builder: (context, child) => Scaffold(
            appBar: AppBar(
              title: const Text('اختيار مستخدمين'),
              actions: [
                IconButton(
                  onPressed: () {
                    navigator.currentState!.pop(
                      context
                          .read<DataObjectListController<User>>()
                          .selectedLatest
                          ?.values
                          .toList(),
                    );
                  },
                  icon: const Icon(Icons.done),
                  tooltip: 'تم',
                ),
              ],
            ),
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SearchField(
                  showSuffix: false,
                  searchStream: context
                      .read<DataObjectListController<User>>()
                      .searchQuery,
                  textStyle: Theme.of(context).textTheme.bodyMedium,
                ),
                const Expanded(
                  child: UsersList(
                    autoDisposeController: false,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  final title = TextEditingController();
  final content = TextEditingController();
  if (users != null &&
      await showDialog(
            context: context,
            builder: (context) {
              return DataDialog(
                actions: <Widget>[
                  TextButton.icon(
                    icon: const Icon(Icons.send),
                    onPressed: () => navigator.currentState!.pop(true),
                    label: const Text('ارسال'),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.cancel),
                    onPressed: () => navigator.currentState!.pop(false),
                    label: const Text('الغاء الأمر'),
                  ),
                ],
                title: const Text('انشاء رسالة'),
                content: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'عنوان الرسالة',
                        ),
                        controller: title,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'هذا الحقل مطلوب';
                          }
                          return null;
                        },
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'محتوى الرسالة',
                          ),
                          textInputAction: TextInputAction.newline,
                          maxLines: null,
                          controller: content,
                          expands: true,
                        ),
                      ),
                    ),
                    Text('سيتم ارفاق ${attachement.name} مع الرسالة'),
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
    await firebaseFunctions.httpsCallable('sendMessageToUsers').call({
      'users': users.map((e) => e.uid).toList(),
      'title': title.text,
      'body': 'أرسل إليك ${User.instance.name} رسالة',
      'content': content.text,
      'attachement': 'https://churchdata.page.link/view$link',
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

Future<String> shareArea(Area area) async => shareAreaRaw(area.id);

Future<String> shareAreaRaw(String id) async {
  return (await FirebaseDynamicLinks.instance.buildShortLink(
    DynamicLinkParameters(
      uriPrefix: uriPrefix,
      link: Uri.parse('https://churchdata.com/viewArea?AreaId=$id'),
      androidParameters: androidParameters,
      iosParameters: iosParameters,
    ),
    shortLinkType: ShortDynamicLinkType.unguessable,
  ))
      .shortUrl
      .toString();
}

Future<String> shareDataObject(DataObject obj) async {
  if (obj is Area) return shareArea(obj);
  if (obj is Street) return shareStreet(obj);
  if (obj is Family) return shareFamily(obj);
  if (obj is Person) return sharePerson(obj);
  throw UnimplementedError();
}

Future<String> shareFamily(Family family) async => shareFamilyRaw(family.id);

Future<String> shareFamilyRaw(String id) async {
  return (await FirebaseDynamicLinks.instance.buildShortLink(
    DynamicLinkParameters(
      uriPrefix: uriPrefix,
      link: Uri.parse('https://churchdata.com/viewFamily?FamilyId=$id'),
      androidParameters: androidParameters,
      iosParameters: iosParameters,
    ),
    shortLinkType: ShortDynamicLinkType.unguessable,
  ))
      .shortUrl
      .toString();
}

Future<String> sharePerson(Person person) async {
  return sharePersonRaw(person.id);
}

Future<String> sharePersonRaw(String id) async {
  return (await FirebaseDynamicLinks.instance.buildShortLink(
    DynamicLinkParameters(
      uriPrefix: uriPrefix,
      link: Uri.parse('https://churchdata.com/viewPerson?PersonId=$id'),
      androidParameters: androidParameters,
      iosParameters: iosParameters,
    ),
    shortLinkType: ShortDynamicLinkType.unguessable,
  ))
      .shortUrl
      .toString();
}

Future<String> shareQuery(Map<String, String> query) async {
  return (await FirebaseDynamicLinks.instance.buildShortLink(
    DynamicLinkParameters(
      uriPrefix: uriPrefix,
      link: Uri.https('churchdata.com', 'viewQuery', query),
      androidParameters: androidParameters,
      iosParameters: iosParameters,
    ),
    shortLinkType: ShortDynamicLinkType.unguessable,
  ))
      .shortUrl
      .toString();
}

Future<String> shareStreet(Street street) async => shareStreetRaw(street.id);

Future<String> shareStreetRaw(String id) async {
  return (await FirebaseDynamicLinks.instance.buildShortLink(
    DynamicLinkParameters(
      uriPrefix: uriPrefix,
      link: Uri.parse('https://churchdata.com/viewStreet?StreetId=$id'),
      androidParameters: androidParameters,
      iosParameters: iosParameters,
    ),
    shortLinkType: ShortDynamicLinkType.unguessable,
  ))
      .shortUrl
      .toString();
}

Future<String> shareUser(User user) async => shareUserRaw(user.uid!);

Future<String> shareUserRaw(String uid) async {
  return (await FirebaseDynamicLinks.instance.buildShortLink(
    DynamicLinkParameters(
      uriPrefix: uriPrefix,
      link: Uri.parse('https://churchdata.com/viewUser?UID=$uid'),
      androidParameters: androidParameters,
      iosParameters: iosParameters,
    ),
    shortLinkType: ShortDynamicLinkType.unguessable,
  ))
      .shortUrl
      .toString();
}

Future showErrorDialog(
  BuildContext context,
  String? message, {
  String? title,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (context) => AlertDialog(
      title: title != null ? Text(title) : null,
      content: Text(message ?? ''),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            navigator.currentState!.pop();
          },
          child: const Text('حسنًا'),
        ),
      ],
    ),
  );
}

Future showErrorUpdateDataDialog({
  required BuildContext context,
  bool pushApp = true,
}) async {
  if (pushApp ||
      Hive.box('Settings').get('DialogLastShown') !=
          tranucateToDay().millisecondsSinceEpoch) {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(
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
              await navigator.currentState!
                  .pushNamed('UpdateUserDataError', arguments: userPerson);
              userPerson = await User.getCurrentPerson();
              if (userPerson != null &&
                  userPerson.lastTanawol != null &&
                  userPerson.lastConfession != null &&
                  ((userPerson.lastTanawol!.millisecondsSinceEpoch +
                              2592000000) >
                          DateTime.now().millisecondsSinceEpoch &&
                      (userPerson.lastConfession!.millisecondsSinceEpoch +
                              5184000000) >
                          DateTime.now().millisecondsSinceEpoch)) {
                navigator.currentState!.pop();
                if (pushApp)
                  // ignore: unawaited_futures
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const App(),
                    ),
                  );
              }
            },
            icon: const Icon(Icons.update),
            label: const Text('تحديث بيانات التناول والاعتراف'),
          ),
          TextButton.icon(
            onPressed: () => navigator.currentState!.pop(),
            icon: const Icon(Icons.close),
            label: const Text('تم'),
          ),
        ],
      ),
    );
    await Hive.box('Settings')
        .put('DialogLastShown', tranucateToDay().millisecondsSinceEpoch);
  }
}

Future<void> showLoadingDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
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

void streetTap(Street street) {
  navigator.currentState!.pushNamed('StreetInfo', arguments: street);
}

Future<void> takeScreenshot(GlobalKey key) async {
  final RenderRepaintBoundary? boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary?;
  WidgetsBinding.instance.addPostFrameCallback(
    (_) async {
      final ui.Image image = await boundary!.toImage(pixelRatio: 2);
      final ByteData byteData =
          (await image.toByteData(format: ui.ImageByteFormat.png))!;
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final file = await (await File(
        (await getApplicationDocumentsDirectory()).path +
            DateTime.now().millisecondsSinceEpoch.toString() +
            '.png',
      ).create())
          .writeAsBytes(pngBytes.toList());

      await Share.shareXFiles(
        [
          XFile(file.path),
        ],
      );
    },
  );
}

String toDurationString(Timestamp? date, {appendSince = true}) {
  if (date == null) return '';
  if (appendSince) return format(date.toDate(), locale: 'ar');
  return format(date.toDate(), locale: 'ar').replaceAll('منذ ', '');
}

Timestamp tranucateToDay({DateTime? time}) {
  time = time ?? DateTime.now();
  return Timestamp.fromMillisecondsSinceEpoch(
    time.millisecondsSinceEpoch -
        time.millisecondsSinceEpoch.remainder(Duration.millisecondsPerDay),
  );
}

Future<void> userTap(User user) async {
  if (user.approved) {
    await navigator.currentState!.pushNamed('UserInfo', arguments: user);
  } else {
    final dynamic rslt = await showDialog(
      context: navigator.currentContext!,
      builder: (context) => DataDialog(
        actions: <Widget>[
          if (user.personRef != null)
            TextButton.icon(
              icon: const Icon(Icons.info),
              label: const Text('اظهار استمارة البيانات'),
              onPressed: () async => navigator.currentState!.pushNamed(
                'PersonInfo',
                arguments: await user.getPerson(),
              ),
            ),
          TextButton.icon(
            icon: const Icon(Icons.done),
            label: const Text('نعم'),
            onPressed: () => navigator.currentState!.pop(true),
          ),
          TextButton.icon(
            icon: const Icon(Icons.close),
            label: const Text('لا'),
            onPressed: () => navigator.currentState!.pop(false),
          ),
          TextButton.icon(
            icon: const Icon(Icons.close),
            label: const Text('حذف المستخدم'),
            onPressed: () => navigator.currentState!.pop('delete'),
          ),
        ],
        title: Text('${user.name} غير مُنشط هل تريد تنشيطه؟'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            user.getPhoto(false),
            Text(
              'البريد الاكتروني: ' + (user.email),
            ),
          ],
        ),
      ),
    );
    if (rslt == true) {
      scaffoldMessenger.currentState!.showSnackBar(
        const SnackBar(
          content: LinearProgressIndicator(),
          duration: Duration(seconds: 15),
        ),
      );
      try {
        await firebaseFunctions
            .httpsCallable('approveUser')
            .call({'affectedUser': user.uid});
        user
          ..approved = true
          // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
          ..notifyListeners();
        unawaited(userTap(user));
        scaffoldMessenger.currentState!.hideCurrentSnackBar();
        scaffoldMessenger.currentState!.showSnackBar(
          const SnackBar(
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
      scaffoldMessenger.currentState!.showSnackBar(
        const SnackBar(
          content: LinearProgressIndicator(),
          duration: Duration(seconds: 15),
        ),
      );
      try {
        await firebaseFunctions
            .httpsCallable('deleteUser')
            .call({'affectedUser': user.uid});
        scaffoldMessenger.currentState!.hideCurrentSnackBar();
        scaffoldMessenger.currentState!.showSnackBar(
          const SnackBar(
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

class MessageIcon extends StatelessWidget {
  final String url;
  const MessageIcon(this.url, {super.key});

  Color get color => Colors.transparent;
  String get name => '';
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints.expand(width: 55.2, height: 55.2),
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

  Future<String> getSecondLine() async => SynchronousFuture('');
}

class QueryIcon extends StatelessWidget {
  const QueryIcon({super.key});

  Color get color => Colors.transparent;
  String get name => 'نتائج بحث';

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.search,
      size: MediaQuery.of(context).size.shortestSide / 7.2,
    );
  }

  Widget getPhoto(BuildContext context) {
    return build(context);
  }

  Future<String> getSecondLine() async => SynchronousFuture('');
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

extension ConnectivityX on List<ConnectivityResult> {
  bool get isConnected => any(
        (c) =>
            c == ConnectivityResult.mobile ||
            c == ConnectivityResult.wifi ||
            c == ConnectivityResult.ethernet,
      );

  bool get isNotConnected => !isConnected;
}
