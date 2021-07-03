import 'dart:async';

import 'package:churchdata/models/street.dart';
import 'package:churchdata/typedefs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive/hive.dart';
import 'package:location/location.dart';
import 'package:rxdart/rxdart.dart';

import '../utils/globals.dart';
import '../utils/helpers.dart';
import 'map_view.dart';
import 'person.dart';
import 'super_classes.dart';
import 'user.dart';

class Family extends DataObject
    with PhotoObject, ParentObject<Person>, ChildObject<Street> {
  JsonRef? _streetId;

  JsonRef? get streetId => _streetId;

  set streetId(JsonRef? streetId) {
    if (streetId != null && _streetId != streetId) {
      _streetId = streetId;
      setAreaIdFromStreet();
      return;
    }
    _streetId = streetId;
  }

  JsonRef? areaId;

  JsonRef? insideFamily;
  JsonRef? insideFamily2;

  String? address;
  String? notes;

  bool locationConfirmed;
  GeoPoint? locationPoint;

  Timestamp? lastVisit;
  Timestamp? fatherLastVisit;

  String? lastEdit;

  bool isStore;

  Family(String? id, this.areaId, this._streetId, String name, this.address,
      this.lastVisit, this.fatherLastVisit, this.lastEdit,
      {Color color = Colors.transparent,
      JsonRef? ref,
      this.isStore = false,
      this.locationPoint,
      this.insideFamily,
      this.insideFamily2,
      this.locationConfirmed = false,
      this.notes})
      : super(
            ref ??
                FirebaseFirestore.instance
                    .collection('Families')
                    .doc(id ?? 'null'),
            name,
            color) {
    hasPhoto = false;
    defaultIcon = Icons.group;
  }

  Family._createFromData(Json data, JsonRef ref)
      : locationConfirmed = data['LocationConfirmed'] ?? false,
        isStore = data['IsStore'] ?? false,
        super.createFromData(data, ref) {
    areaId = data['AreaId'];
    _streetId = data['StreetId'];
    insideFamily = data['InsideFamily'];
    insideFamily2 = data['InsideFamily2'];

    address = data['Address'];
    notes = data['Notes'];

    locationPoint = data['Location'];

    lastVisit = data['LastVisit'];
    fatherLastVisit = data['FatherLastVisit'];

    lastEdit = data['LastEdit'];

    hasPhoto = false;
    defaultIcon = isStore ? Icons.store : Icons.group;
  }

  @override
  JsonRef? get parentId => streetId;

  @override
  Reference get photoRef => throw UnimplementedError();

  Future<String?> getAreaName() async {
    return (await areaId?.get(dataSource))?.data()?['Name'];
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
              .docs)
          .cast<Person>();
    }
    return Person.getAll((await FirebaseFirestore.instance
                .collection('Persons')
                .where('AreaId', isEqualTo: areaId)
                .where('FamilyId', isEqualTo: ref)
                .get(dataSource))
            .docs)
        .cast<Person>();
  }

  @override
  Json getHumanReadableMap() => {
        'Name': name,
        'Address': address ?? '',
        'Notes': notes ?? '',
        'LastVisit': toDurationString(lastVisit),
        'FatherLastVisit': toDurationString(fatherLastVisit),
        'LastEdit': lastEdit,
        'IsStore': isStore ? 'محل' : 'عائلة'
      };

  Future<String?> getInsideFamilyName() async {
    return (await insideFamily?.get(dataSource))?.data()?['Name'];
  }

  Future<String?> getInsideFamily2Name() async {
    return (await insideFamily2?.get(dataSource))?.data()?['Name'];
  }

  @override
  Json getMap() => {
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
                    initialLocation: LatLng(
                        snapshot.data!.latitude!, snapshot.data!.longitude!),
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

  Stream<List<JsonQuery>> getMembersLive(
      {String orderBy = 'Name', bool descending = false}) {
    return Family.getFamilyMembersLive(areaId!, id, orderBy, descending);
  }

  @override
  Future<String?> getParentName() => getStreetName();

  @override
  Future<String?> getSecondLine() async {
    String key = Hive.box('Settings').get('FamilySecondLine');
    if (key == 'Members') {
      return getMembersString();
    } else if (key == 'AreaId') {
      return getAreaName();
    } else if (key == 'StreetId') {
      return getStreetName();
    } else if (key == 'LastEdit') {
      return (await FirebaseFirestore.instance
              .doc('Users/$lastEdit')
              .get(dataSource))
          .data()?['Name'];
    }
    return getHumanReadableMap()[key];
  }

  Future<String?> getStreetName() async {
    return (await streetId?.get(dataSource))?.data()?['Name'];
  }

  Future<void> setAreaIdFromStreet() async {
    areaId = (await streetId?.get(dataSource))?.data()?['AreaId'];
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
      User.instance.uid,
    );
  }

  static Family? fromDoc(JsonDoc data) =>
      data.exists ? Family._createFromData(data.data()!, data.reference) : null;

  static Family fromQueryDoc(JsonDoc data) => fromDoc(data)!;

  static Future<Family?> fromId(String id) async => Family.fromDoc(
        await FirebaseFirestore.instance.doc('Families/$id').get(),
      );

  static List<Family?> getAll(List<JsonDoc> families) {
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
        .map(fromQueryDoc)
        .toList();
  }

  static Stream<JsonQuery> getAllForUser({
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

  static Json getEmptyExportMap() => {
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

  static Stream<List<JsonQuery>> getFamilyMembersLive(JsonRef areaId, String id,
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
              ? Rx.combineLatest3<JsonQuery, JsonQuery, JsonQuery,
                      List<JsonQuery>>(
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
                  (a, b, c) => <JsonQuery>[a, b, c])
              : Rx.combineLatest3<JsonQuery, JsonQuery, JsonQuery,
                  List<JsonQuery>>(
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
                  (a, b, c) => <JsonQuery>[a, b, c],
                ),
        );
  }

  static Json getHumanReadableMap2() => {
        'Name': 'الاسم',
        'Address': 'العنوان',
        'Notes': 'الملاحظات',
        'Color': 'اللون',
        'LastVisit': 'أخر زيارة',
        'FatherLastVisit': 'أخر زيارة (الأب الكاهن)',
        'LastEdit': 'أخر شخص قام بالتعديل',
        'IsStore': 'محل؟'
      };

  @override
  Family copyWith() {
    return Family._createFromData(getMap(), ref);
  }
}
