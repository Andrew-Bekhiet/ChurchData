import 'dart:async';

import 'package:churchdata/models/street.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive/hive.dart';
import 'package:location/location.dart';
import 'package:rxdart/rxdart.dart';

import 'super_classes.dart';
import '../utils/helpers.dart';
import '../utils/globals.dart';
import 'map_view.dart';
import 'person.dart';
import 'user.dart';

class Family extends DataObject
    with PhotoObject, ParentObject<Person>, ChildObject<Street> {
  DocumentReference streetId;
  DocumentReference areaId;

  DocumentReference insideFamily;
  DocumentReference insideFamily2;

  String address;
  String notes;

  bool locationConfirmed;
  GeoPoint locationPoint;

  Timestamp lastVisit;
  Timestamp fatherLastVisit;

  String lastEdit;

  bool isStore;

  Family(String id, this.areaId, this.streetId, String name, this.address,
      this.lastVisit, this.fatherLastVisit, this.lastEdit,
      {Color color = Colors.transparent,
      DocumentReference ref,
      this.isStore = false,
      this.locationPoint,
      this.insideFamily,
      this.insideFamily2,
      this.locationConfirmed,
      this.notes})
      : super(ref ?? FirebaseFirestore.instance.collection('Families').doc(id),
            name, color) {
    hasPhoto = false;
    defaultIcon = Icons.group;
  }

  Family._createFromData(Map<dynamic, dynamic> data, DocumentReference ref)
      : super.createFromData(data, ref) {
    areaId = data['AreaId'];
    streetId = data['StreetId'];
    insideFamily = data['InsideFamily'];
    insideFamily2 = data['InsideFamily2'];

    isStore = data['IsStore'] ?? false;
    address = data['Address'];
    notes = data['Notes'];

    locationPoint = data['Location'];
    locationConfirmed = data['LocationConfirmed'] ?? false;

    lastVisit = data['LastVisit'];
    fatherLastVisit = data['FatherLastVisit'];

    lastEdit = data['LastEdit'];

    hasPhoto = false;
    defaultIcon = isStore ? Icons.store : Icons.group;
  }

  @override
  DocumentReference get parentId => streetId;

  @override
  Reference get photoRef => throw UnimplementedError();

  Future<String> getAreaName() async {
    return (await areaId.get(dataSource)).data()['Name'];
  }

  @override
  Future<List<Person>> getChildren(
      [String orderBy = 'Name', bool tranucate = false]) async {
    if (tranucate) {
      return Person.getAll((await FirebaseFirestore.instance
              .collection('Persons')
              .where('AreaId', isEqualTo: areaId)
              .where('FamilyId', isEqualTo: ref)
              .limit(5)
              .get(dataSource))
          .docs);
    }
    return Person.getAll((await FirebaseFirestore.instance
            .collection('Persons')
            .where('AreaId', isEqualTo: areaId)
            .where('FamilyId', isEqualTo: ref)
            .get(dataSource))
        .docs);
  }

  @override
  Map<String, dynamic> getHumanReadableMap() => {
        'Name': name ?? '',
        'Address': address ?? '',
        'Notes': notes ?? '',
        'LastVisit': toDurationString(lastVisit),
        'FatherLastVisit': toDurationString(fatherLastVisit),
        'LastEdit': lastEdit,
        'IsStore': isStore ? 'محل' : 'عائلة'
      };

  Future<String> getInsideFamilyName() async {
    return (await insideFamily.get(dataSource)).data()['Name'];
  }

  Future<String> getInsideFamily2Name() async {
    return (await insideFamily2.get(dataSource)).data()['Name'];
  }

  @override
  Map<String, dynamic> getMap() => {
        'AreaId': areaId,
        'StreetId': streetId,
        'Name': name,
        'Address': address,
        'Notes': notes,
        'Color': color.value,
        'Location': locationPoint,
        'LocationConfirmed': locationConfirmed,
        'LastVisit': lastVisit,
        'FatherLastVisit': fatherLastVisit,
        'LastEdit': lastEdit,
        'InsideFamily': insideFamily,
        'InsideFamily2': insideFamily2,
        'IsStore': isStore
      };

  Widget getMapView({bool useGPSIfNull = false, bool editMode = false}) {
    if (locationPoint == null && useGPSIfNull)
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
                    family: this);
              },
            );
          }
          return MapView(
              childrenDepth: 3,
              initialLocation: LatLng(34, 50),
              editMode: editMode,
              family: this);
        },
      );
    else if (locationPoint == null)
      return Text(
        'لم يتم تحديد موقع للعائلة',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      );
    return MapView(editMode: editMode, family: this, childrenDepth: 3);
  }

  Stream<List<QuerySnapshot>> getMembersLive(
      {String orderBy = 'Name', bool descending = false}) {
    return Family.getFamilyMembersLive(areaId, id, orderBy, descending);
  }

  @override
  Future<String> getParentName() => getStreetName();

  @override
  Future<String> getSecondLine() async {
    String key = Hive.box('Settings').get('FamilySecondLine');
    if (key == 'Members') {
      return await getMembersString();
    } else if (key == 'AreaId') {
      return await getAreaName();
    } else if (key == 'StreetId') {
      return await getStreetName();
    } else if (key == 'LastEdit') {
      return (await FirebaseFirestore.instance
              .doc('Users/$lastEdit')
              .get(dataSource))
          .data()['Name'];
    }
    return getHumanReadableMap()[key];
  }

  Future<String> getStreetName() async {
    return (await streetId.get(dataSource)).data()['Name'];
  }

  Future setAreaIdFromStreet() async {
    areaId = (await streetId.get(dataSource)).data()['AreaId'];
  }

  static Family empty() {
    return Family(
      null,
      null,
      null,
      '',
      '',
      tranucateToDay(),
      tranucateToDay(),
      auth.FirebaseAuth.instance.currentUser.uid,
    );
  }

  static Family fromDoc(DocumentSnapshot data) =>
      data.exists ? Family._createFromData(data.data(), data.reference) : null;

  static Future<Family> fromId(String id) async => Family.fromDoc(
        await FirebaseFirestore.instance.doc('Families/$id').get(),
      );

  static List<Family> getAll(List<DocumentSnapshot> families) {
    return families.map(Family.fromDoc).toList();
  }

  static Future<List<Family>> getAllFamiliesForUser({
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
                  .collection('Families')
                  .orderBy(orderBy, descending: descending)
                  .snapshots()
              : FirebaseFirestore.instance
                  .collection('Families')
                  .where(
                    'AreaId',
                    whereIn: a,
                  )
                  .orderBy(orderBy, descending: descending)
                  .snapshots(),
        );
  }

  static Map<String, dynamic> getEmptyExportMap() => {
        'ID': 'id',
        'AreaId': 'areaId.id',
        'StreetId': 'streetId.id',
        'Name': 'name',
        'Address': 'address',
        'Color': 'color.value',
        'Location': 'locationPoint',
        'LocationConfirmed': 'locationConfirmed',
        'LastVisit': 'lastVisit',
        'FatherLastVisit': 'fatherLastVisit',
        'LastEdit': 'lastEdit',
        'IsStore': 'isStore'
      };

  static Stream<List<QuerySnapshot>> getFamilyMembersLive(
      DocumentReference areaId, String id,
      [String orderBy = 'Name', bool descending = false]) {
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
              ? Rx.combineLatest3(
                  FirebaseFirestore.instance
                      .collection('Persons')
                      .where('AreaId', isEqualTo: areaId)
                      .where(
                        'FamilyId',
                        isEqualTo: FirebaseFirestore.instance
                            .collection('Families')
                            .doc(id),
                      )
                      .orderBy(orderBy, descending: descending)
                      .snapshots(),
                  FirebaseFirestore.instance
                      .collection('Families')
                      .where(
                        'InsideFamily',
                        isEqualTo: FirebaseFirestore.instance
                            .collection('Families')
                            .doc(id),
                      )
                      .orderBy('Name')
                      .snapshots(),
                  FirebaseFirestore.instance
                      .collection('Families')
                      .where(
                        'InsideFamily2',
                        isEqualTo: FirebaseFirestore.instance
                            .collection('Families')
                            .doc(id),
                      )
                      .orderBy('Name')
                      .snapshots(),
                  (a, b, c) => <QuerySnapshot>[a, b, c])
              : Rx.combineLatest3(
                  FirebaseFirestore.instance
                      .collection('Persons')
                      .where('AreaId', isEqualTo: areaId)
                      .where(
                        'FamilyId',
                        isEqualTo: FirebaseFirestore.instance
                            .collection('Families')
                            .doc(id),
                      )
                      .orderBy(orderBy, descending: descending)
                      .snapshots(),
                  FirebaseFirestore.instance
                      .collection('Families')
                      .where('AreaId', isEqualTo: areaId)
                      .where(
                        'InsideFamily',
                        isEqualTo: FirebaseFirestore.instance
                            .collection('Families')
                            .doc(id),
                      )
                      .orderBy('Name')
                      .snapshots(),
                  FirebaseFirestore.instance
                      .collection('Families')
                      .where('AreaId', isEqualTo: areaId)
                      .where(
                        'InsideFamily2',
                        isEqualTo: FirebaseFirestore.instance
                            .collection('Families')
                            .doc(id),
                      )
                      .orderBy('Name')
                      .snapshots(),
                  (a, b, c) => <QuerySnapshot>[a, b, c]),
        );
  }

  // @override
  // fireWeb.Reference get webPhotoRef => throw UnimplementedError();

  static Map<String, dynamic> getHumanReadableMap2() => {
        'Name': 'الاسم',
        'Address': 'العنوان',
        'Notes': 'الملاحظات',
        'Color': 'اللون',
        'LastVisit': 'أخر زيارة',
        'FatherLastVisit': 'أخر زيارة (الأب الكاهن)',
        'LastEdit': 'أخر شخص قام بالتعديل',
        'IsStore': 'محل؟'
      };
}
