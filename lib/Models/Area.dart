import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive/hive.dart';
import 'package:location/location.dart';

import '../Models.dart';
import '../Models/super_classes.dart';
import '../utils/Helpers.dart';
import '../utils/globals.dart';
import '../views/utils/MapView.dart';
import 'User.dart';

class Area extends DataObject with PhotoObject, ParentObject<Street> {
  String address;

  bool locationConfirmed;
  List<GeoPoint> locationPoints;

  Timestamp lastVisit;
  Timestamp fatherLastVisit;

  List<String> allowedUsers;
  String lastEdit;

  Area(
    String id,
    String name,
    this.address,
    bool hasPhoto,
    this.locationConfirmed,
    this.lastVisit,
    this.fatherLastVisit,
    this.allowedUsers,
    this.lastEdit, {
    Color color = Colors.transparent,
    this.locationPoints,
  }) : super(id, name, color) {
    this.hasPhoto = hasPhoto;
    defaultIcon = Icons.pin_drop;
  }

  @override
  Area.createFromData(Map<dynamic, dynamic> data, String id)
      : super.createFromData(data, id) {
    address = data['Address'];

    hasPhoto = data['hasPhoto'] ?? false;

    locationPoints = data['Location']?.cast<GeoPoint>();
    locationConfirmed = data['LocationConfirmed'] ?? false;

    lastVisit = data['LastVisit'];
    fatherLastVisit = data['FatherLastVisit'];

    allowedUsers = data['Allowed']?.cast<String>();
    lastEdit = data['LastEdit'];

    defaultIcon = Icons.pin_drop;
  }

  @override
  Reference get photoRef =>
      FirebaseStorage.instance.ref().child('AreasPhotos/$id');

  @override
  DocumentReference get ref => FirebaseFirestore.instance.doc('Areas/$id');

  @override
  Future<List<Street>> getChildren(
      [String orderBy = 'Name', bool tranucate = false, int depth = 1]) async {
    if (tranucate) {
      return Street.getAll((await FirebaseFirestore.instance
              .collection('Streets')
              .where('AreaId', isEqualTo: ref)
              .orderBy(orderBy)
              .limit(5)
              .get(dataSource))
          .docs);
    }
    return Street.getAll((await FirebaseFirestore.instance
            .collection('Streets')
            .where('AreaId', isEqualTo: ref)
            .orderBy(orderBy)
            .get(dataSource))
        .docs);
  }

  @override
  Map<String, dynamic> getExportMap() => {
        'ID': id,
        'Name': name,
        'Address': address,
        'HasPhoto': hasPhoto ?? false,
        'Location': locationPoints?.join(','),
        'LocationConfirmed': locationConfirmed,
        'Color': color.value,
        'LastVisit': lastVisit?.millisecondsSinceEpoch?.toString(),
        'FatherLastVisit': fatherLastVisit?.millisecondsSinceEpoch?.toString(),
        'Allowed': allowedUsers.join(','),
        'LastEdit': lastEdit
      };

  Future<List<Family>> getFamilyMembersList(
      [String orderBy = 'Name', bool tranucate = false]) async {
    if (tranucate) {
      return Family.getAll((await FirebaseFirestore.instance
              .collection('Families')
              .where('AreaId', isEqualTo: ref)
              .limit(5)
              .orderBy(orderBy)
              .get(dataSource))
          .docs);
    }
    return Family.getAll((await FirebaseFirestore.instance
            .collection('Families')
            .where('AreaId', isEqualTo: ref)
            .orderBy(orderBy)
            .get(dataSource))
        .docs);
  }

  @override
  Map<String, dynamic> getHumanReadableMap() => {
        'Name': name ?? '',
        'Address': address ?? '',
        'LastVisit': toDurationString(lastVisit),
        'FatherLastVisit': toDurationString(fatherLastVisit),
      };

  @override
  Map<String, dynamic> getMap() => {
        'Name': name,
        'Address': address,
        'hasPhoto': hasPhoto ?? false,
        'Location': locationPoints?.sublist(0),
        'LocationConfirmed': locationConfirmed,
        'Color': color.value,
        'LastVisit': lastVisit,
        'FatherLastVisit': fatherLastVisit,
        'Allowed': allowedUsers,
        'LastEdit': lastEdit,
      };

  Widget getMapView(
      {int depth = 2, bool useGPSIfNull = false, bool editMode = false}) {
    if (locationPoints == null && useGPSIfNull)
      return FutureBuilder<PermissionStatus>(
        future: Location.instance.requestPermission(),
        builder: (context, data) {
          if (data.hasData && data.data == PermissionStatus.granted) {
            return FutureBuilder<LocationData>(
              future: Location.instance.getLocation(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                return MapView(
                    childrenDepth: depth,
                    initialLocation:
                        LatLng(snapshot.data.latitude, snapshot.data.longitude),
                    editMode: editMode,
                    area: this);
              },
            );
          }
          return MapView(
              childrenDepth: depth,
              initialLocation: LatLng(34, 50),
              editMode: editMode,
              area: this);
        },
      );
    else if (locationPoints == null)
      return Text(
        'لم يتم تحديد موقع للمنطقة',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      );
    return MapView(childrenDepth: depth, editMode: editMode, area: this);
  }

  Future<Stream<QuerySnapshot>> getMembersLive(
      {String orderBy = 'Name', bool descending = false}) async {
    return await Area.getAreaChildrenLive(id, orderBy, descending);
  }

  Future<List<Person>> getPersonMembersList(
      [String orderBy = 'Name', bool tranucate = false]) async {
    if (tranucate) {
      return Person.getAll((await FirebaseFirestore.instance
              .collection('Persons')
              .where('AreaId', isEqualTo: ref)
              .limit(5)
              .orderBy(orderBy)
              .get(dataSource))
          .docs);
    }
    return Person.getAll((await FirebaseFirestore.instance
            .collection('Persons')
            .where('AreaId', isEqualTo: ref)
            .orderBy(orderBy)
            .get(dataSource))
        .docs);
  }

  @override
  Future<String> getSecondLine() async {
    String key = Hive.box('Settings').get('AreaSecondLine');
    if (key == 'Members') {
      return await getMembersString();
    } else if (key == 'Allowed') {
      return (await Future.wait(
        allowedUsers
            .take(5)
            .map(
              (item) =>
                  FirebaseFirestore.instance.doc('Users/$item').get(dataSource),
            )
            .toList(),
      ))
          .map((e) => e.data()['Name'])
          .join(',');
    } else if (key == 'LastEdit') {
      return (await FirebaseFirestore.instance
              .doc('Users/$lastEdit')
              .get(dataSource))
          .data()['Name'];
    }
    return getHumanReadableMap()[key];
  }

  static Area empty() {
    return Area(
      '',
      '',
      '',
      false,
      false,
      tranucateToDay(),
      tranucateToDay(),
      [auth.FirebaseAuth.instance.currentUser.uid],
      auth.FirebaseAuth.instance.currentUser.uid,
    );
  }

  static Area fromDocumentSnapshot(DocumentSnapshot data) =>
      Area.createFromData(data.data(), data.id);

  static Future<Area> fromId(String id) async => Area.fromDocumentSnapshot(
        await FirebaseFirestore.instance.doc('Areas/$id').get(),
      );

  static List<Area> getAll(List<DocumentSnapshot> areas) {
    return areas
        .map(
          (a) => Area.fromDocumentSnapshot(a),
        )
        .toList();
  }

  static Future<List<Area>> getAllAreasForUser({
    String orderBy = 'Name',
    bool descending = false,
  }) async {
    if (User().superAccess) {
      return getAll((await FirebaseFirestore.instance
              .collection('Areas')
              .orderBy(orderBy, descending: descending)
              .get(dataSource))
          .docs);
    }
    return getAll((await FirebaseFirestore.instance
            .collection('Areas')
            .where('Allowed',
                arrayContains: auth.FirebaseAuth.instance.currentUser.uid)
            .orderBy(orderBy, descending: descending)
            .get(dataSource))
        .docs);
  }

  static Future<Stream<QuerySnapshot>> getAllForUser({
    String orderBy = 'Name',
    bool descending = false,
  }) async {
    if (User().superAccess) {
      return FirebaseFirestore.instance
          .collection('Areas')
          .orderBy(orderBy, descending: descending)
          .snapshots();
    }
    return FirebaseFirestore.instance
        .collection('Areas')
        .where('Allowed',
            arrayContains: auth.FirebaseAuth.instance.currentUser.uid)
        .orderBy(orderBy, descending: descending)
        .snapshots();
  }

  static Future<Stream<QuerySnapshot>> getAreaChildrenLive(String id,
      [String orderBy = 'Name', bool descending = false]) async {
    return FirebaseFirestore.instance
        .collection('Streets')
        .where(
          'AreaId',
          isEqualTo: FirebaseFirestore.instance.collection('Areas').doc(id),
        )
        .snapshots();
  }

  static Map<String, dynamic> getEmptyExportMap() => {
        'ID': 'id',
        'Name': 'name',
        'Address': 'address',
        'HasPhoto': 'hasPhoto',
        'Location': 'locationPoints',
        'LocationConfirmed': 'locationConfirmed',
        'Color': 'color.value',
        'LastVisit': 'lastVisit',
        'FatherLastVisit': 'fatherLastVisit',
        'Allowed': 'allowedUsers',
        'LastEdit': 'lastEdit'
      };

  static Map<String, dynamic> getStaticHumanReadableMap() => {
        'Name': 'الاسم',
        'Address': 'العنوان',
        'LastVisit': 'أخر زيارة',
        'Color': 'اللون',
        'FatherLastVisit': 'أخر زيارة (الأب الكاهن)',
        'Allowed': 'الأشخاص المسموح لهم بالرؤية والتعديل',
        'LastEdit': 'أخر شخص قام بالتعديل'
      };

  // @override
  // fireWeb.Reference get webPhotoRef =>
  //     fireWeb.storage().ref('AreasPhotos/$id');
}
