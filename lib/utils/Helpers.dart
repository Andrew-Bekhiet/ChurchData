import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:churchdata/views/MiniLists/UsersList.dart';
import 'package:churchdata/views/utils/DataDialog.dart';
import 'package:churchdata/views/utils/SearchFilters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity/connectivity.dart';
import 'package:device_info/device_info.dart';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.io) 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart' hide User;
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Person;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart' as open;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as sfxls;
import 'package:timeago/timeago.dart';
import 'package:tuple/tuple.dart';

import '../Models.dart';
import '../Models/ListOptions.dart';
import '../Models/MiniModels.dart';
import '../Models/Notification.dart' as no;
import '../Models/OrderOptions.dart';
import '../Models/SearchString.dart';
import '../Models/ThemeNotifier.dart';
import '../Models/User.dart';
import '../Models/super_classes.dart';
import '../main.dart';
import '../views/ui/Lists.dart';
import '../views/ui/SearchQuery.dart';
import 'globals.dart';

Future analysisExport(BuildContext context) async {
  var scaffold = ScaffoldMessenger.of(context);
  try {
    if ((await Permission.storage.request()).isGranted) {
      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'جار تجهيز البيانات',
              ),
              LinearProgressIndicator(),
            ],
          ),
          duration: Duration(seconds: 100),
        ),
      );

      var file = sfxls.Workbook();
      file.worksheets.addWithName('Streets');
      file.worksheets.addWithName('Families');
      file.worksheets.addWithName('Persons');

      var areasSheet = file.worksheets[0];
      var streetsSheet = file.worksheets[1];
      var familiesSheet = file.worksheets[2];
      var personsSheet = file.worksheets[3];

      areasSheet.name = 'Areas';

      areasSheet.getRangeByName('A1').setText('ID');
      areasSheet.getRangeByName('B1').setText('Name');
      areasSheet.getRangeByName('C1').setText('Address');
      areasSheet.getRangeByName('D1').setText('Last Visit');
      areasSheet.getRangeByName('E1').setText('Father Last Visit');
      areasSheet.getRangeByName('F1').setText('Location');
      areasSheet.getRangeByName('G1').setText('Last Edit');

      streetsSheet.getRangeByName('A1').setText('ID');
      streetsSheet.getRangeByName('B1').setText('Name');
      streetsSheet.getRangeByName('C1').setText('Location');
      streetsSheet.getRangeByName('D1').setText('Last Visit');
      streetsSheet.getRangeByName('E1').setText('Father Last Visit');
      streetsSheet.getRangeByName('F1').setText('Inside Area');
      streetsSheet.getRangeByName('G1').setText('Last Edit');

      familiesSheet.getRangeByName('A1').setText('ID');
      familiesSheet.getRangeByName('B1').setText('Name');
      familiesSheet.getRangeByName('C1').setText('Address');
      familiesSheet.getRangeByName('D1').setText('Last Visit');
      familiesSheet.getRangeByName('E1').setText('Father Last Visit');
      familiesSheet.getRangeByName('F1').setText('Location');
      familiesSheet.getRangeByName('G1').setText('Inside Area');
      familiesSheet.getRangeByName('H1').setText('Inside Street');
      familiesSheet.getRangeByName('I1').setText('Last Edit');

      personsSheet.getRangeByName('A1').setText('ID');
      personsSheet.getRangeByName('B1').setText('Name');
      personsSheet.getRangeByName('C1').setText('Birthdate');
      personsSheet.getRangeByName('D1').setText('Is Student');
      personsSheet.getRangeByName('E1').setText('Study Year');
      personsSheet.getRangeByName('F1').setText('College');
      personsSheet.getRangeByName('G1').setText('Job');
      personsSheet.getRangeByName('H1').setText('Job Description');
      personsSheet.getRangeByName('I1').setText('Qualification');
      personsSheet.getRangeByName('J1').setText('Person Type');
      personsSheet.getRangeByName('K1').setText('Church');
      personsSheet.getRangeByName('L1').setText('Confession Father');
      personsSheet.getRangeByName('M1').setText('Is Servant');
      personsSheet.getRangeByName('N1').setText('Serving Type');
      personsSheet.getRangeByName('O1').setText('State');
      personsSheet.getRangeByName('P1').setText('Last Tanawol');
      personsSheet.getRangeByName('Q1').setText('Last Confession');
      personsSheet.getRangeByName('R1').setText('Notes');
      personsSheet.getRangeByName('S1').setText('Last Edit');
      personsSheet.getRangeByName('T1').setText('Inside Area');
      personsSheet.getRangeByName('U1').setText('Inside Street');
      personsSheet.getRangeByName('V1').setText('Inside Family');

      Map<String, String> streetsByID = {
        for (var doc in await Street.getAllStreetsForUser()) doc.id: doc.name,
      };

      Map<String, String> familiesByID = {
        for (var doc in await Family.getAllFamiliesForUser()) doc.id: doc.name
      };

      Map<String, String> usersByID = {
        for (var sDoc in (await User.getAllUsersLive()).docs)
          sDoc.id: sDoc.data()['Name']
      };

      Map<String, String> studyYearByID = {
        for (var sDoc in (await StudyYear.getAllForUser()).docs)
          sDoc.id: sDoc.data()['Name']
      };

      Map<String, String> collegesByID = {
        for (var sDoc in (await College.getAllForUser()).docs)
          sDoc.id: sDoc.data()['Name']
      };

      Map<String, String> jobsByID = {
        for (var sDoc in (await Job.getAllForUser()).docs)
          sDoc.id: sDoc.data()['Name']
      };

      Map<String, String> typesByID = {
        for (var sDoc in (await PersonType.getAllForUser()).docs)
          sDoc.id: sDoc.data()['Name']
      };

      Map<String, String> churchByID = {
        for (var sDoc in (await Church.getAllForUser()).docs)
          sDoc.id: sDoc.data()['Name']
      };

      Map<String, String> fathersByID = {
        for (var sDoc in (await Father.getAllForUser()).docs)
          sDoc.id: sDoc.data()['Name']
      };

      Map<String, String> servingTypeByID = {
        for (var sDoc in (await ServingType.getAllForUser()).docs)
          sDoc.id: sDoc.data()['Name']
      };

      Map<String, PersonState> statesByID = {
        for (var sDoc in (await PersonState.getAllForUser()).docs)
          sDoc.id: PersonState.fromDocumentSnapshot(sDoc)
      };

      int areaIndex = 2;
      int streetIndex = 2;
      int familyIndex = 2;
      int personIndex = 2;

      var areas = await Area.getAllAreasForUser();
      for (Area area in areas) {
        scaffold.hideCurrentSnackBar();
        scaffold.showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'جار تصدير منطقة ' + area.name,
                ),
                LinearProgressIndicator(),
              ],
            ),
            duration: Duration(seconds: 100),
          ),
        );
        var areaStreets = await area.getChildren();
        var areaFamilies = await area.getFamilyMembersList();
        var areaPersons = await area.getPersonMembersList();

        var areaCellStyle = sfxls.CellStyle(file);
        areaCellStyle.backColor = area.color.toHex();

        areasSheet
            .getRangeByName('A' + (areas.indexOf(area) + areaIndex).toString())
            .cellStyle = areaCellStyle;

        areasSheet
            .getRangeByName('A' + (areas.indexOf(area) + areaIndex).toString())
            .setText(area.id);
        areasSheet
            .getRangeByName('B' + (areas.indexOf(area) + areaIndex).toString())
            .setText(area.name);
        areasSheet
            .getRangeByName('C' + (areas.indexOf(area) + areaIndex).toString())
            .setText(area.address);
        if (area.lastVisit != null)
          areasSheet
              .getRangeByName(
                  'D' + (areas.indexOf(area) + areaIndex).toString())
              .setDateTime(area.lastVisit.toDate());
        if (area.fatherLastVisit != null)
          areasSheet
              .getRangeByName(
                  'E' + (areas.indexOf(area) + areaIndex).toString())
              .setDateTime(area.fatherLastVisit.toDate());
        if (area.locationPoints != null)
          areasSheet
              .getRangeByName(
                  'F' + (areas.indexOf(area) + areaIndex).toString())
              .setText(area.locationPoints.join(', '));
        if (area.lastEdit != null)
          areasSheet
              .getRangeByName(
                  'G' + (areas.indexOf(area) + areaIndex).toString())
              .setText(usersByID[area.lastEdit] ?? '');

        for (Street street in areaStreets) {
          var cellStyle = sfxls.CellStyle(file);
          cellStyle.backColor = street.color.toHex();

          streetsSheet
              .getRangeByName(
                  'A' + (areaStreets.indexOf(street) + streetIndex).toString())
              .cellStyle = cellStyle;

          streetsSheet
              .getRangeByName(
                  'A' + (areaStreets.indexOf(street) + streetIndex).toString())
              .setText(street.id);
          streetsSheet
              .getRangeByName(
                  'B' + (areaStreets.indexOf(street) + streetIndex).toString())
              .setText(street.name);
          if (street.locationPoints != null)
            streetsSheet
                .getRangeByName('C' +
                    (areaStreets.indexOf(street) + streetIndex).toString())
                .setText(street.locationPoints.join(', '));
          if (street.lastVisit != null)
            streetsSheet
                .getRangeByName('D' +
                    (areaStreets.indexOf(street) + streetIndex).toString())
                .setDateTime(street.lastVisit.toDate());
          if (street.fatherLastVisit != null)
            streetsSheet
                .getRangeByName('E' +
                    (areaStreets.indexOf(street) + streetIndex).toString())
                .setDateTime(street.fatherLastVisit.toDate());
          streetsSheet
              .getRangeByName(
                  'F' + (areaStreets.indexOf(street) + streetIndex).toString())
              .setText(area.name);
          if (street.lastEdit != null)
            streetsSheet
                .getRangeByName('G' +
                    (areaStreets.indexOf(street) + streetIndex).toString())
                .setText(usersByID[street.lastEdit] ?? '');
        }

        for (Family family in areaFamilies) {
          var cellStyle = sfxls.CellStyle(file);
          cellStyle.backColor = family.color.toHex();

          familiesSheet
              .getRangeByName(
                  'A' + (areaFamilies.indexOf(family) + familyIndex).toString())
              .setText(family.id);
          familiesSheet
              .getRangeByName(
                  'A' + (areaFamilies.indexOf(family) + familyIndex).toString())
              .cellStyle = cellStyle;

          familiesSheet
              .getRangeByName(
                  'B' + (areaFamilies.indexOf(family) + familyIndex).toString())
              .setText(family.name);
          familiesSheet
              .getRangeByName(
                  'C' + (areaFamilies.indexOf(family) + familyIndex).toString())
              .setText(family.address);
          if (family.lastVisit != null)
            familiesSheet
                .getRangeByName('D' +
                    (areaFamilies.indexOf(family) + familyIndex).toString())
                .setDateTime(family.lastVisit.toDate());
          if (family.fatherLastVisit != null)
            familiesSheet
                .getRangeByName('E' +
                    (areaFamilies.indexOf(family) + familyIndex).toString())
                .setDateTime(family.fatherLastVisit.toDate());
          if (family.locationPoint != null)
            familiesSheet
                .getRangeByName('F' +
                    (areaFamilies.indexOf(family) + familyIndex).toString())
                .setText(family.locationPoint.toString());
          familiesSheet
              .getRangeByName(
                  'G' + (areaFamilies.indexOf(family) + familyIndex).toString())
              .setText(area.name);
          familiesSheet
              .getRangeByName(
                  'H' + (areaFamilies.indexOf(family) + familyIndex).toString())
              .setText(streetsByID[family.streetId.id] ?? '');
          if (family.lastEdit != null)
            familiesSheet
                .getRangeByName('I' +
                    (areaFamilies.indexOf(family) + familyIndex).toString())
                .setText(usersByID[family.lastEdit] ?? '');
        }

        for (Person person in areaPersons) {
          var cellStyle = sfxls.CellStyle(file);
          cellStyle.backColor = person.color.toHex();

          personsSheet
              .getRangeByName(
                  'A' + (areaPersons.indexOf(person) + personIndex).toString())
              .cellStyle = cellStyle;

          personsSheet
              .getRangeByName(
                  'A' + (areaPersons.indexOf(person) + personIndex).toString())
              .setText(person.id);
          personsSheet
              .getRangeByName(
                  'B' + (areaPersons.indexOf(person) + personIndex).toString())
              .setText(person.name);
          if (person.birthDate != null)
            personsSheet
                .getRangeByName('C' +
                    (areaPersons.indexOf(person) + personIndex).toString())
                .setDateTime(person.birthDate.toDate());
          personsSheet
              .getRangeByName(
                  'D' + (areaPersons.indexOf(person) + personIndex).toString())
              .setText(person.isStudent.toString());
          if (person.studyYear != null)
            personsSheet
                .getRangeByName('E' +
                    (areaPersons.indexOf(person) + personIndex).toString())
                .setText(studyYearByID[person.studyYear.id] ?? '');
          if (person.college != null)
            personsSheet
                .getRangeByName('F' +
                    (areaPersons.indexOf(person) + personIndex).toString())
                .setText(collegesByID[person.college.id] ?? '');
          if (person.job != null)
            personsSheet
                .getRangeByName('G' +
                    (areaPersons.indexOf(person) + personIndex).toString())
                .setText(jobsByID[person.job.id] ?? '');
          personsSheet
              .getRangeByName(
                  'H' + (areaPersons.indexOf(person) + personIndex).toString())
              .setText(person.jobDescription);
          personsSheet
              .getRangeByName(
                  'I' + (areaPersons.indexOf(person) + personIndex).toString())
              .setText(person.qualification);
          if (person.type != null)
            personsSheet
                .getRangeByName('J' +
                    (areaPersons.indexOf(person) + personIndex).toString())
                .setText(typesByID[person.type] ?? '');
          if (person.church != null)
            personsSheet
                .getRangeByName('K' +
                    (areaPersons.indexOf(person) + personIndex).toString())
                .setText(churchByID[person.church.id] ?? '');
          if (person.cFather != null)
            personsSheet
                .getRangeByName('L' +
                    (areaPersons.indexOf(person) + personIndex).toString())
                .setText(fathersByID[person.cFather.id] ?? '');
          personsSheet
              .getRangeByName(
                  'M' + (areaPersons.indexOf(person) + personIndex).toString())
              .setText(person.isServant.toString());
          if (person.servingType != null)
            personsSheet
                .getRangeByName('N' +
                    (areaPersons.indexOf(person) + personIndex).toString())
                .setText(servingTypeByID[person.servingType.id] ?? '');

          if (person.state != null) {
            personsSheet
                .getRangeByName('O' +
                    (areaPersons.indexOf(person) + personIndex).toString())
                .setText(statesByID[person.state.id].name);

            var stateCellStyle = sfxls.CellStyle(file);
            stateCellStyle.backColor =
                statesByID[person.state.id].color.toHex();

            personsSheet
                .getRangeByName('O' +
                    (areaPersons.indexOf(person) + personIndex).toString())
                .cellStyle = stateCellStyle;
          }

          if (person.lastTanawol != null)
            personsSheet
                .getRangeByName('P' +
                    (areaPersons.indexOf(person) + personIndex).toString())
                .setDateTime(person.lastTanawol.toDate());
          if (person.lastConfession != null)
            personsSheet
                .getRangeByName('Q' +
                    (areaPersons.indexOf(person) + personIndex).toString())
                .setDateTime(person.lastConfession.toDate());
          personsSheet
              .getRangeByName(
                  'R' + (areaPersons.indexOf(person) + personIndex).toString())
              .setText(person.notes);
          if (person.lastEdit != null)
            personsSheet
                .getRangeByName('S' +
                    (areaPersons.indexOf(person) + personIndex).toString())
                .setText(usersByID[person.lastEdit] ?? '');

          personsSheet
              .getRangeByName(
                  'T' + (areaPersons.indexOf(person) + personIndex).toString())
              .setText(area.name);

          personsSheet
              .getRangeByName(
                  'U' + (areaPersons.indexOf(person) + personIndex).toString())
              .setText(streetsByID[person.streetId.id] ?? '');

          personsSheet
              .getRangeByName(
                  'V' + (areaPersons.indexOf(person) + personIndex).toString())
              .setText(familiesByID[person.familyId.id] ?? '');
        }
        streetIndex += areaStreets.length;
        familyIndex += areaFamilies.length;
        personIndex += areaPersons.length;
        // areaIndex++; //We dont need this
      }
      String filePath = '/storage/emulated/0/ChurchData/Export-' +
          DateTime.now().toIso8601String().replaceAll(':', '_') +
          '.xlsx';
      if (Platform.isAndroid &&
          (await DeviceInfoPlugin().androidInfo).version.sdkInt <= 28) {
        await (await File(filePath).create(recursive: true))
            .writeAsBytes(file.saveAsStream());
        scaffold.hideCurrentSnackBar();
        scaffold.showSnackBar(
          SnackBar(
            content: Text(
              'تم التصدير بنجاح الى ' + filePath,
            ),
          ),
        );
      } else {
        filePath = (await getApplicationDocumentsDirectory()).path +
            '/ChurchData/Export-' +
            DateTime.now().toIso8601String().replaceAll(':', '_') +
            '.xlsx';
        await (await (File(filePath)).create(recursive: true))
            .writeAsBytes(file.saveAsStream());
        scaffold.hideCurrentSnackBar();
        scaffold.showSnackBar(
          SnackBar(
            content: Text(
              'تم التصدير بنجاح الى ' + filePath,
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
      await open.OpenFile.open(filePath);
    }
  } catch (err, stckTrace) {
    scaffold.hideCurrentSnackBar();
    scaffold.showSnackBar(
      SnackBar(
        content: Text(
          err.toString(),
        ),
      ),
    );
    await FirebaseCrashlytics.instance
        .setCustomKey('LastErrorIn', 'Helpers.analysisExport');
    await FirebaseCrashlytics.instance.recordError(err, stckTrace);
  }
}

void areaTap(Area area, BuildContext context) {
  if (export) {
    exportArea(area, context);
    return;
  }
  Navigator.of(context).pushNamed('AreaInfo', arguments: area);
}

void showConfessionNotification() async {
  await Firebase.initializeApp();
  var user = await User.getCurrentUser();
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
  var user = await User.getCurrentUser();
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
  var user = await User.getCurrentUser();
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
  else
    throw UnimplementedError();
}

Future exportArea(Area area, BuildContext context) async {
  try {
    if ((await Permission.storage.request()).isGranted) {
      var areaStreets = await area.getChildren();
      var areaFamilies = await area.getFamilyMembersList();
      var areaPersons = await area.getPersonMembersList();
      var file = excel.Excel.createExcel()
        ..appendRow(
          'Main',
          area.getExportMap().values.toList(),
        )
        ..appendRow(
          'Areas',
          Street.getEmptyExportMap().keys.toList(),
        )
        ..appendRow(
          'Families',
          Family.getEmptyExportMap().keys.toList(),
        )
        ..appendRow(
          'Contacts',
          Person.getEmptyExportMap().keys.toList(),
        );
      await file.setDefaultSheet('Areas');
      for (Street item in areaStreets) {
        file.appendRow(
          'Areas',
          item.getExportMap().values.toList(),
        );
      }

      for (Family item in areaFamilies) {
        file.appendRow(
          'Families',
          item.getExportMap().values.toList(),
        );
      }

      for (Person item in areaPersons) {
        file.appendRow(
          'Contacts',
          item.getExportMap().values.toList(),
        );
      }
      String filePath = '/storage/emulated/0/ChurchData/${area.name}.xlsx';
      if (Platform.isAndroid &&
          (await DeviceInfoPlugin().androidInfo).version.sdkInt <= 28) {
        await (await (File(filePath)).create(recursive: true)).writeAsBytes(
          await file.encode(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم التصدير بنجاح الى ' + filePath,
            ),
          ),
        );
      } else {
        filePath = (await getApplicationDocumentsDirectory()).path +
            '/ChurchData/${area.name}.xlsx';
        await (await (File(filePath)).create(recursive: true)).writeAsBytes(
          await file.encode(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم التصدير بنجاح الى ' + filePath,
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
      await open.OpenFile.open(filePath);
    }
  } catch (err, stckTrace) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          err.toString(),
        ),
      ),
    );
    await FirebaseCrashlytics.instance
        .setCustomKey('LastErrorIn', 'Helpers.exportArea');
    await FirebaseCrashlytics.instance.recordError(err, stckTrace);
  }
  export = false;
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

List<RadioListTile> getOrderingOptions(
    BuildContext context, OrderOptions orderOptions, int index) {
  if (index == 0) {
    return Area.getStaticHumanReadableMap()
        .entries
        .map(
          (e) => RadioListTile(
            value: e.key,
            groupValue: orderOptions.areaOrderBy,
            title: Text(e.value),
            onChanged: (value) {
              orderOptions.setAreaOrderBy(value);
              Navigator.pop(context);
            },
          ),
        )
        .toList()
          ..addAll(
            [
              RadioListTile(
                value: 'true',
                groupValue: orderOptions.areaASC.toString(),
                title: Text('تصاعدي'),
                onChanged: (value) {
                  orderOptions.setAreaASC(value == 'true');
                  Navigator.pop(context);
                },
              ),
              RadioListTile(
                value: 'false',
                groupValue: orderOptions.areaASC.toString(),
                title: Text('تنازلي'),
                onChanged: (value) {
                  orderOptions.setAreaASC(value == 'true');
                  Navigator.pop(context);
                },
              ),
            ],
          );
  } else if (index == 1) {
    return Street.getHumanReadableMap2()
        .entries
        .map(
          (e) => RadioListTile(
            value: e.key,
            groupValue: orderOptions.streetOrderBy,
            title: Text(e.value),
            onChanged: (value) {
              orderOptions.setStreetOrderBy(value);
              Navigator.pop(context);
            },
          ),
        )
        .toList()
          ..addAll(
            [
              RadioListTile(
                value: 'true',
                groupValue: orderOptions.streetASC.toString(),
                title: Text('تصاعدي'),
                onChanged: (value) {
                  orderOptions.setStreetASC(value == 'true');
                  Navigator.pop(context);
                },
              ),
              RadioListTile(
                value: 'false',
                groupValue: orderOptions.streetASC.toString(),
                title: Text('تنازلي'),
                onChanged: (value) {
                  orderOptions.setStreetASC(value == 'true');
                  Navigator.pop(context);
                },
              ),
            ],
          );
  } else if (index == 2) {
    return Family.getHumanReadableMap2()
        .entries
        .map(
          (e) => RadioListTile(
            value: e.key,
            groupValue: orderOptions.familyOrderBy,
            title: Text(e.value),
            onChanged: (value) {
              orderOptions.setFamilyOrderBy(value);
              Navigator.pop(context);
            },
          ),
        )
        .toList()
          ..addAll(
            [
              RadioListTile(
                value: 'true',
                groupValue: orderOptions.familyASC.toString(),
                title: Text('تصاعدي'),
                onChanged: (value) {
                  orderOptions.setFamilyASC(value == 'true');
                  Navigator.pop(context);
                },
              ),
              RadioListTile(
                value: 'false',
                groupValue: orderOptions.familyASC.toString(),
                title: Text('تنازلي'),
                onChanged: (value) {
                  orderOptions.setFamilyASC(value == 'true');
                  Navigator.pop(context);
                },
              ),
            ],
          );
  } else //if(_tabController.index == 3){
    return Person.getHumanReadableMap2()
        .entries
        .map(
          (e) => RadioListTile(
            value: e.key,
            groupValue: orderOptions.streetOrderBy,
            title: Text(e.value),
            onChanged: (value) {
              orderOptions.setStreetOrderBy(value);
              Navigator.pop(context);
            },
          ),
        )
        .toList()
          ..addAll(
            [
              RadioListTile(
                value: 'true',
                groupValue: orderOptions.streetASC.toString(),
                title: Text('تصاعدي'),
                onChanged: (value) {
                  orderOptions.setStreetASC(value == 'true');
                  Navigator.pop(context);
                },
              ),
              RadioListTile(
                value: 'false',
                groupValue: orderOptions.streetASC.toString(),
                title: Text('تنازلي'),
                onChanged: (value) {
                  orderOptions.setStreetASC(value == 'true');
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
  Navigator.of(context).pop();
  bool ver2;

  var decoder = SpreadsheetDecoder.decodeBytes(
      (await FilePicker.platform
              .pickFiles(allowedExtensions: ['.xlsx', '.xls'], withData: true))
          .files[0]
          .bytes,
      update: true);
  mainScfld.currentState.openEndDrawer();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('جار الحصول على البيانات من الملف...'),
      duration: Duration(hours: 1),
    ),
  );
  ver2 = decoder.tables.containsKey('Main');

  if (!ver2) {
    await showDialog(
        context: context,
        builder: (context) {
          return DataDialog(
            actions: <Widget>[
              TextButton.icon(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                label: Text('إلغاء الأمر'),
              ),
              TextButton.icon(
                icon: Icon(Icons.add),
                onPressed: () =>
                    Navigator.of(context).pushNamed('Data/EditArea'),
                label: Text('إضافة'),
              ),
            ],
            content: ListenableProvider<SearchString>(
              create: (_) => SearchString(''),
              builder: (context, child) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SearchFilters(0),
                  Flexible(
                    child: Selector<OrderOptions, Tuple2<String, bool>>(
                      selector: (_, o) =>
                          Tuple2<String, bool>(o.areaOrderBy, o.areaASC),
                      builder: (context, options, child) =>
                          DataObjectList<Area>(
                        options: ListOptions<Area>(
                          tap: (Area area, _) =>
                              _legacyImport(decoder, area.ref, context),
                          generate: Area.fromDocumentSnapshot,
                          documentsData: () => Area.getAllForUser(
                              orderBy: options.item1,
                              descending: !options.item2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  } else {
    List area = decoder.tables['Main'].rows[0];
    var emptyArea = Area.getEmptyExportMap().keys.toList();
    area[emptyArea.indexOf('HasPhoto')] = area[3].toString() == 'true';
    area[emptyArea.indexOf('Location')] =
        area[emptyArea.indexOf('Location')].toString().split(',');
    area[emptyArea.indexOf('LocationConfirmed')] =
        area[emptyArea.indexOf('LocationConfirmed')].toString() == 'true';
    area[emptyArea.indexOf('LastVisit')] =
        int.parse(area[emptyArea.indexOf('LastVisit')]);
    area[emptyArea.indexOf('LastVisit')] =
        int.parse(area[emptyArea.indexOf('LastVisit')]);
    area[emptyArea.indexOf('FatherLastVisit')] =
        int.parse(area[emptyArea.indexOf('FatherLastVisit')]);
    area[emptyArea.indexOf('Allowed')] =
        area[emptyArea.indexOf('Allowed')].toString().split(',');
    await importArea(
        decoder,
        Area.createFromData(
          Area.getEmptyExportMap().map(
            (key, value) => MapEntry(
              key,
              area[emptyArea.indexOf(key)],
            ),
          ),
          area[0],
        ),
        context);
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

Future<dynamic> onForegroundMessage(Map<dynamic, dynamic> message,
    {bool foreground = true}) async {
  await Hive.box<Map<dynamic, dynamic>>('Notifications')
      .add((message['data'] as Map<dynamic, dynamic>).cast<String, dynamic>());
  if (foreground)
    ScaffoldMessenger.of(mainScfld.currentContext).showSnackBar(
      SnackBar(
        content: Text(message['notification']['body']),
        action: SnackBarAction(
          label: 'فتح الاشعارات',
          onPressed: () =>
              Navigator.of(mainScfld.currentContext).pushNamed('Notifications'),
        ),
      ),
    );
  return null;
}

Future<dynamic> onMessage(Map<String, dynamic> message) async {
  await onForegroundMessage(message, foreground: false);
  try {
    // ignore: unawaited_futures
    Navigator.of(mainScfld.currentContext).pushNamed('Notifications');
    pendingMessage['data']['type'] != 'Message'
        ? processLink(Uri.parse(pendingMessage['data']['attachement']),
            mainScfld.currentContext)
        : showMessage(
            mainScfld.currentContext,
            no.Notification.fromMessage(pendingMessage['data']),
          );
  } catch (e) {
    pendingMessage = message;
  }
  return null;
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
          await Future.delayed(Duration(milliseconds: 900), () => null);
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
          await Future.delayed(Duration(milliseconds: 900), () => null);
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
          await Future.delayed(Duration(milliseconds: 900), () => null);
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
          Area.fromDocumentSnapshot(
            await FirebaseFirestore.instance
                .doc('Areas/${deepLink.queryParameters['AreaId']}')
                .get(),
          ),
          context);
    } else if (deepLink.pathSegments[0] == 'viewStreet') {
      streetTap(
          Street.fromDocumentSnapshot(
            await FirebaseFirestore.instance
                .doc('Streets/${deepLink.queryParameters['StreetId']}')
                .get(),
          ),
          context);
    } else if (deepLink.pathSegments[0] == 'viewFamily') {
      familyTap(
          Family.fromDocumentSnapshot(
            await FirebaseFirestore.instance
                .doc('Families/${deepLink.queryParameters['FamilyId']}')
                .get(),
          ),
          context);
    } else if (deepLink.pathSegments[0] == 'viewPerson') {
      personTap(
          Person.fromDocumentSnapshot(
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
      if (context.read<User>().manageUsers) {
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
  List<User> users = await showDialog(
    context: context,
    builder: (context) {
      return MultiProvider(
        providers: [
          ListenableProvider<SearchString>(
            create: (_) => SearchString(''),
          ),
          ListenableProvider(
              create: (_) => ListOptions<User>(
                  isAdmin: User().manageUsers,
                  documentsData: () => User.getAllUsersLive()
                      .then((value) => Stream.value(value))))
        ],
        builder: (context, child) => DataDialog(
          actions: [
            TextButton(
              child: Text('تم'),
              onPressed: () {
                Navigator.pop(
                    context, context.read<ListOptions<User>>().selected);
              },
            )
          ],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SearchField(),
              Expanded(
                child: Selector<OrderOptions, Tuple2<String, bool>>(
                  selector: (_, o) =>
                      Tuple2<String, bool>(o.areaOrderBy, o.areaASC),
                  builder: (context, options, child) => UsersList(),
                ),
              ),
            ],
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
      'body': 'أرسل إليك ${context.read<User>().name} رسالة',
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
          child: Text('حسنًا'),
          onPressed: () {
            Navigator.of(context).pop();
          },
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

void showMessage(BuildContext context, no.Notification notification) async {
  var attachement = await getLinkObject(
    Uri.parse(notification.attachement),
  );
  String scndLine = await attachement.getSecondLine();
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
                  ? User.fromDocumentSnapshot(
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
    bool rslt = await showDialog(
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
                )
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
      } catch (err, stkTrace) {
        await FirebaseCrashlytics.instance
            .setCustomKey('LastErrorIn', 'Data.userTap');
        await FirebaseCrashlytics.instance.recordError(err, stkTrace);
      }
    }
  }
}

Future _legacyImport(SpreadsheetDecoder decoder, DocumentReference areaId,
    BuildContext context) async {
  List<Street> streets = [];
  List<Family> families = [];
  List<Person> persons = [];
  try {
    for (List<dynamic> row in decoder.tables['Areas'].rows) {
      if (decoder.tables.values.elementAt(0).rows.indexOf(row) == 0) continue;
      if (row.elementAt(0) == null) break;
      try {
        var testing = row.elementAt(3);
        if (row.elementAt(3) == null) {
          testing.toString();
        } else {
          streets.add(
            Street(
              row.elementAt(0).toString(),
              areaId,
              row.elementAt(2).toString(),
              Timestamp.fromDate(DateTime.parse(
                row.elementAt(3),
              )),
              auth.FirebaseAuth.instance.currentUser.uid,
            ),
          );
        }
      } catch (err) {
        streets.add(
          Street(
            row.elementAt(0).toString(),
            areaId,
            row.elementAt(2).toString(),
            Timestamp.now(),
            auth.FirebaseAuth.instance.currentUser.uid,
          ),
        );
      }
    }

    for (List<dynamic> row in decoder.tables['Families'].rows) {
      if (decoder.tables['Families'].rows.indexOf(row) == 0) continue;
      if (row.elementAt(0) == null) break;
      try {
        var testing = row.elementAt(3);
        if (row.elementAt(3) == null) {
          print(
            testing.toString(),
          );
        } else {
          families.add(
            Family(
              row.elementAt(0).toString(),
              areaId,
              null,
              row.elementAt(1).toString(),
              row.elementAt(2).toString(),
              Timestamp.fromDate(DateTime.parse(
                row.elementAt(3),
              )),
              tranucateToDay(),
              auth.FirebaseAuth.instance.currentUser.uid,
            ),
          );
        }
      } catch (e) {
        families.add(
          Family(
            row.elementAt(0).toString(),
            areaId,
            null,
            row.elementAt(1).toString(),
            '',
            tranucateToDay(),
            tranucateToDay(),
            auth.FirebaseAuth.instance.currentUser.uid,
          ),
        );
      }
    }

    for (List<dynamic> row in decoder.tables['Contacts'].rows) {
      if (decoder.tables['Contacts'].rows.indexOf(row) == 0) continue;
      if (row.elementAt(0) == null) break;
      families
          .where(
        (f) => f.id == row.elementAt(3).toString(),
      )
          .forEach((f) {
        f.streetId = FirebaseFirestore.instance.collection('Streets').doc(
              row.elementAt(4).toString(),
            );
        f.address = row.elementAt(1).toString();
      });
      persons.add(
        Person(
          areaId: areaId,
          streetId: FirebaseFirestore.instance.collection('Streets').doc(
                row.elementAt(4).toString(),
              ),
          familyId: FirebaseFirestore.instance.collection('Families').doc(
                row.elementAt(3).toString(),
              ),
          name: row.elementAt(0).toString(),
          phone: row.elementAt(2).toString(),
        ),
      );
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جار إعادة ترتيب البيانات...'),
        duration: Duration(minutes: 1),
      ),
    );
    for (Street item in streets) {
      String oldId = item.id;
      DocumentReference newId =
          FirebaseFirestore.instance.collection('Streets').doc();
      item.id = newId.id;
      families.where((f) => f.streetId.id == oldId).forEach((f) {
        f.streetId = newId;
      });
      persons.where((f) => f.streetId.id == oldId).forEach((f) {
        f.streetId = newId;
      });

      for (Family item in families) {
        String oldId = item.id;
        DocumentReference newId =
            FirebaseFirestore.instance.collection('Families').doc();
        item.id = newId.id;
        persons.where((f) => f.familyId.id == oldId).forEach((f) {
          f.familyId = newId;
        });
      }

      for (Person item in persons) {
        item.id = FirebaseFirestore.instance.collection('Persons').doc().id;
      }
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جار رفع البيانات ...'),
        duration: Duration(minutes: 5),
      ),
    );

    WriteBatch batchUpdate = FirebaseFirestore.instance.batch();
    int batchCount = 0;

    for (var i = 0; i < streets.length; i++) {
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
        FirebaseFirestore.instance.collection('Streets').doc(streets[i].id),
        streets[i].getMap(),
      );
      batchCount++;
    }

    for (var i = 0; i < families.length; i++) {
      if (batchCount % 500 == 0) {
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
        FirebaseFirestore.instance.collection('Families').doc(families[i].id),
        families[i].getMap(),
      );
      batchCount++;
    }
    bool end = false;
    for (var i = 0; i < persons.length; i++) {
      if (batchCount % 500 == 0) {
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
          if (i == persons.length - 1) {
            end = true;
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'تم استيراد بيانات ${streets.length} شارع و ${families.length} عائلة و ${persons.length} شخص بنجاح'),
                duration: Duration(seconds: 4),
              ),
            );
          }
        });
        batchUpdate = FirebaseFirestore.instance.batch();
      }
      batchUpdate.set(
        FirebaseFirestore.instance.collection('Persons').doc(persons[i].id),
        persons[i].getMap(),
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
                'تم استيراد بيانات ${streets.length} شارع و ${families.length} عائلة و ${persons.length} شخص بنجاح'),
            duration: Duration(seconds: 4),
          ),
        );
      });
    }
  } on Exception catch (err, stkTrace) {
    await FirebaseCrashlytics.instance
        .setCustomKey('LastErrorIn', 'Helpers._legacyImport');
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

  streets = null;
  families = null;
  persons = null;
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
          child: CachedNetworkImage(
            memCacheHeight: 221,
            imageUrl: url,
            progressIndicatorBuilder: (context, url, progress) =>
                CircularProgressIndicator(value: progress.progress),
          ),
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
