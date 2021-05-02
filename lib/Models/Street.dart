import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive/hive.dart';
import 'package:rxdart/rxdart.dart';
import 'package:location/location.dart';

import 'super_classes.dart';
import '../utils/helpers.dart';
import '../utils/globals.dart';
import 'map_view.dart';
import 'area.dart';
import 'family.dart';
import 'person.dart';
import 'user.dart';

class Street extends DataObject
    with PhotoObject, ParentObject<Family>, ChildObject<Area> {
  DocumentReference areaId;

  bool locationConfirmed;
  List<GeoPoint> locationPoints;

  Timestamp lastVisit;
  Timestamp fatherLastVisit;

  String lastEdit;

  Street(String id, this.areaId, String name, this.lastVisit, this.lastEdit,
      {Color color = Colors.transparent,
      DocumentReference ref,
      this.locationPoints,
      this.locationConfirmed = false})
      : super(
            ref ??
                FirebaseFirestore.instance
                    .collection('Streets')
                    .doc(id ?? 'null'),
            name,
            color);

  Street._createFromData(Map<dynamic, dynamic> data, DocumentReference ref)
      : super.createFromData(data, ref) {
    areaId = data['AreaId'];

    locationPoints = data['Location']?.cast<GeoPoint>();
    locationConfirmed = data['LocationConfirmed'] ?? false;

    lastVisit = data['LastVisit'];
    fatherLastVisit = data['FatherLastVisit'];

    lastEdit = data['LastEdit'];
  }

  @override
  DocumentReference get parentId => areaId;

  @override
  Widget photo([_ = false]) {
    return Builder(
      builder: (context) => Image.asset(
        'assets/streets.png',
        width: MediaQuery.of(context).size.shortestSide / 7.2,
        height: MediaQuery.of(context).size.longestSide / 15.7,
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.black
            : Colors.white,
      ),
    );
  }

  @override
  Reference get photoRef => throw UnimplementedError();

  Future<String> getAreaName() async {
    return (await areaId.get(dataSource)).data()['Name'];
  }

  @override
  Future<List<Family>> getChildren(
      [String orderBy = 'Name', bool tranucate = false]) async {
    if (tranucate) {
      return Family.getAll((await FirebaseFirestore.instance
              .collection('Families')
              .where('AreaId', isEqualTo: areaId)
              .where('StreetId', isEqualTo: ref)
              .orderBy(orderBy)
              .limit(5)
              .get(dataSource))
          .docs);
    }
    return Family.getAll((await FirebaseFirestore.instance
            .collection('Families')
            .where('AreaId', isEqualTo: areaId)
            .where('StreetId', isEqualTo: ref)
            .orderBy(orderBy)
            .get(dataSource))
        .docs);
  }

  @override
  Map<String, dynamic> getHumanReadableMap() => {
        'Name': name ?? '',
        'LastVisit': toDurationString(lastVisit),
        'FatherLastVisit': toDurationString(fatherLastVisit),
      };

  @override
  Map<String, dynamic> getMap() => {
        'Name': name,
        'AreaId': areaId,
        'Color': color.value,
        'Location': locationPoints?.sublist(0),
        'LocationConfirmed': locationConfirmed,
        'LastVisit': lastVisit,
        'FatherLastVisit': fatherLastVisit,
        'LastEdit': lastEdit,
      };

  Widget getMapView({bool useGPSIfNull = false, bool editMode = false}) {
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
                    childrenDepth: 3,
                    initialLocation:
                        LatLng(snapshot.data.latitude, snapshot.data.longitude),
                    editMode: editMode,
                    street: this);
              },
            );
          }
          return MapView(
              childrenDepth: 3,
              initialLocation: LatLng(34, 50),
              editMode: editMode,
              street: this);
        },
      );
    else if (locationPoints == null)
      return Text(
        'لم يتم تحديد موقع للشارع',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      );
    return MapView(
      childrenDepth: 3,
      editMode: editMode,
      street: this,
    );
  }

  Stream<QuerySnapshot> getMembersLive(
      {String orderBy = 'Name', bool descending = false}) {
    return Street.getStreetMembersLive(areaId, id, orderBy, descending);
  }

  @override
  Future<String> getParentName() => getAreaName();

  Future<List<Person>> getPersonMembersList([bool tranucate = false]) async {
    if (tranucate) {
      return Person.getAll((await FirebaseFirestore.instance
              .collection('Persons')
              .where('AreaId', isEqualTo: areaId)
              .where('StreetId', isEqualTo: ref)
              .limit(5)
              .get(dataSource))
          .docs);
    }
    return Person.getAll((await FirebaseFirestore.instance
            .collection('Persons')
            .where('AreaId', isEqualTo: areaId)
            .where('StreetId', isEqualTo: ref)
            .get(dataSource))
        .docs);
  }

  @override
  Future<String> getSecondLine() async {
    String key = Hive.box('Settings').get('StreetSecondLine');
    if (key == 'Members') {
      return await getMembersString();
    } else if (key == 'AreaId') {
      return await getAreaName();
    } else if (key == 'LastEdit') {
      return (await FirebaseFirestore.instance
              .doc('Users/$lastEdit')
              .get(dataSource))
          .data()['Name'];
    }
    return getHumanReadableMap()[key];
  }

  static Street empty() {
    return Street(
      null,
      null,
      '',
      tranucateToDay(),
      auth.FirebaseAuth.instance.currentUser.uid,
    );
  }

  static Street fromDoc(DocumentSnapshot data) =>
      data.exists ? Street._createFromData(data.data(), data.reference) : null;

  static Future<Street> fromId(String id) async => Street.fromDoc(
        await FirebaseFirestore.instance.doc('Streets/$id').get(),
      );

  static List<Street> getAll(List<DocumentSnapshot> streets) {
    return streets.map(Street.fromDoc).toList();
  }

  static Stream<QuerySnapshot> getAllForUser({
    String orderBy = 'Name',
    bool descending = false,
  }) {
    return User.instance.stream
        .asyncMap(
          (u) async => u.superAccess
              ? null
              : (await FirebaseFirestore.instance
                      .collection('Areas')
                      .where('Allowed', arrayContains: u.uid)
                      .get(dataSource))
                  .docs
                  .map((e) => e.reference)
                  .toList(),
        )
        .switchMap(
          (a) => a == null
              ? FirebaseFirestore.instance
                  .collection('Streets')
                  .orderBy(orderBy, descending: descending)
                  .snapshots()
              : FirebaseFirestore.instance
                  .collection('Streets')
                  .where(
                    'AreaId',
                    whereIn: a,
                  )
                  .orderBy(orderBy, descending: descending)
                  .snapshots(),
        );
  }

  static Future<List<Street>> getAllStreetsForUser({
    String orderBy = 'Name',
    bool descending = false,
  }) async {
    return (await getAllForUser(orderBy: orderBy, descending: descending)
            .asBroadcastStream()
            .first)
        .docs
        .map(fromDoc)
        .toList();
  }

  static Map<String, dynamic> getEmptyExportMap() => {
        'ID': 'id',
        'Name': 'name',
        'AreaId': 'areaId.id',
        'Color': 'color.value',
        'Location': 'locationPoints',
        'LocationConfirmed': 'locationConfirmed',
        'LastVisit': 'lastVisit',
        'FatherLastVisit': 'fatherLastVisit',
        'LastEdit': 'lastEdit'
      };

  static Map<String, dynamic> getHumanReadableMap2() => {
        'Name': 'الاسم',
        'Color': 'اللون',
        'LastVisit': 'أخر زيارة',
        'FatherLastVisit': 'أخر زيارة (الأب الكاهن)',
        'LastEdit': 'أخر شخص قام بالتعديل'
      };

  // @override
  // fireWeb.Reference get webPhotoRef => throw UnimplementedError();

  static Stream<QuerySnapshot> getStreetMembersLive(
      DocumentReference areaId, String id,
      [String orderBy = 'Name', bool descending = false]) {
    return FirebaseFirestore.instance
        .collection('Families')
        .where('AreaId', isEqualTo: areaId)
        .where(
          'StreetId',
          isEqualTo: FirebaseFirestore.instance.collection('Streets').doc(id),
        )
        .orderBy(orderBy, descending: descending)
        .snapshots();
  }

  @override
  Street copyWith() {
    return Street._createFromData(getMap(), ref);
  }
}
