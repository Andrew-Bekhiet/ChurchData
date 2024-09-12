import 'dart:async';

import 'package:churchdata/models/street.dart';
import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:location/location.dart';
import 'package:rxdart/rxdart.dart';

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

  Family({
    required this.areaId,
    required JsonRef? streetId,
    required String name,
    required JsonRef ref,
    this.address,
    this.lastVisit,
    this.fatherLastVisit,
    this.lastEdit,
    Color color = Colors.transparent,
    this.isStore = false,
    this.locationPoint,
    this.insideFamily,
    this.insideFamily2,
    this.locationConfirmed = false,
    this.notes,
  })  : _streetId = streetId,
        super(ref, name, color) {
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
    return (await areaId?.get())?.data()?['Name'];
  }

  @override
  Future<List<Person>> getChildren([
    String orderBy = 'Name',
    bool tranucate = false,
  ]) async {
    if (tranucate) {
      return Person.getAll(
        (await firestore
                .collection('Persons')
                .where('AreaId', isEqualTo: areaId)
                .where('FamilyId', isEqualTo: ref)
                .limit(5)
                .get())
            .docs,
      ).cast<Person>();
    }
    return Person.getAll(
      (await firestore
              .collection('Persons')
              .where('AreaId', isEqualTo: areaId)
              .where('FamilyId', isEqualTo: ref)
              .get())
          .docs,
    ).cast<Person>();
  }

  @override
  Json getHumanReadableMap() => {
        'Name': name,
        'Address': address ?? '',
        'Notes': notes ?? '',
        'LastVisit': toDurationString(lastVisit),
        'FatherLastVisit': toDurationString(fatherLastVisit),
        'LastEdit': lastEdit,
        'IsStore': isStore ? 'محل' : 'عائلة',
      };

  Future<String?> getInsideFamilyName() async {
    return (await insideFamily?.get())?.data()?['Name'];
  }

  Future<String?> getInsideFamily2Name() async {
    return (await insideFamily2?.get())?.data()?['Name'];
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
        'IsStore': isStore,
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
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                return MapView(
                  childrenDepth: 3,
                  initialLocation: LatLng(
                    snapshot.data!.latitude!,
                    snapshot.data!.longitude!,
                  ),
                  editMode: editMode,
                  family: this,
                );
              },
            );
          }
          return MapView(
            childrenDepth: 3,
            initialLocation: const LatLng(30.033333, 31.233334),
            editMode: editMode,
            family: this,
          );
        },
      );
    else if (locationPoint == null)
      return const Text(
        'لم يتم تحديد موقع للعائلة',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      );
    return MapView(editMode: editMode, family: this, childrenDepth: 3);
  }

  Stream<List<JsonQuery>> getMembersLive({
    String orderBy = 'Name',
    bool descending = false,
  }) {
    return Family.getFamilyMembersLive(areaId!, id, orderBy, descending);
  }

  @override
  Future<String?> getParentName() => getStreetName();

  @override
  Future<String?> getSecondLine() async {
    final String key = Hive.box('Settings').get('FamilySecondLine');
    if (key == 'Members') {
      return getMembersString();
    } else if (key == 'AreaId') {
      return getAreaName();
    } else if (key == 'StreetId') {
      return getStreetName();
    } else if (key == 'LastEdit') {
      return (await firestore.doc('Users/$lastEdit').get()).data()?['Name'];
    }

    return SynchronousFuture(getHumanReadableMap()[key]);
  }

  Future<String?> getStreetName() async {
    return (await streetId?.get())?.data()?['Name'];
  }

  Future<void> setAreaIdFromStreet() async {
    areaId = (await streetId?.get())?.data()?['AreaId'];
  }

  static Family empty() {
    return Family(
      ref: FirebaseFirestore.instance.collection('Families').doc('null'),
      name: '',
      areaId: null,
      streetId: null,
    );
  }

  static Family? fromDoc(JsonDoc data) =>
      data.exists ? Family._createFromData(data.data()!, data.reference) : null;

  static Family fromQueryDoc(JsonDoc data) => fromDoc(data)!;

  static Future<Family?> fromId(String id) async => Family.fromDoc(
        await firestore.doc('Families/$id').get(),
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
              : (await firestore
                      .collection('Areas')
                      .where('Allowed', arrayContains: u.uid)
                      .get())
                  .docs
                  .map((e) => e.reference)
                  .toList(),
        )
        .switchMap(
          (a) => a == null
              ? firestore
                  .collection('Families')
                  .orderBy(orderBy, descending: descending)
                  .snapshots()
              : firestore
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
        'IsStore': 'isStore',
      };

  static Stream<List<JsonQuery>> getFamilyMembersLive(
    JsonRef areaId,
    String id, [
    String orderBy = 'Name',
    bool descending = false,
  ]) {
    return User.instance.stream
        .asyncMap(
          (u) async => u.superAccess
              ? null
              : (await firestore
                      .collection('Areas')
                      .where('Allowed', arrayContains: u.uid)
                      .get())
                  .docs
                  .map((e) => e.reference)
                  .toList(),
        )
        .switchMap(
          (a) => a == null
              ? Rx.combineLatest3<JsonQuery, JsonQuery, JsonQuery,
                  List<JsonQuery>>(
                  firestore
                      .collection('Persons')
                      .where('AreaId', isEqualTo: areaId)
                      .where(
                        'FamilyId',
                        isEqualTo: firestore.collection('Families').doc(id),
                      )
                      .orderBy(orderBy, descending: descending)
                      .snapshots(),
                  firestore
                      .collection('Families')
                      .where(
                        'InsideFamily',
                        isEqualTo: firestore.collection('Families').doc(id),
                      )
                      .orderBy('Name')
                      .snapshots(),
                  firestore
                      .collection('Families')
                      .where(
                        'InsideFamily2',
                        isEqualTo: firestore.collection('Families').doc(id),
                      )
                      .orderBy('Name')
                      .snapshots(),
                  (a, b, c) => <JsonQuery>[a, b, c],
                )
              : Rx.combineLatest3<JsonQuery, JsonQuery, JsonQuery,
                  List<JsonQuery>>(
                  firestore
                      .collection('Persons')
                      .where('AreaId', isEqualTo: areaId)
                      .where(
                        'FamilyId',
                        isEqualTo: firestore.collection('Families').doc(id),
                      )
                      .orderBy(orderBy, descending: descending)
                      .snapshots(),
                  firestore
                      .collection('Families')
                      .where('AreaId', isEqualTo: areaId)
                      .where(
                        'InsideFamily',
                        isEqualTo: firestore.collection('Families').doc(id),
                      )
                      .orderBy('Name')
                      .snapshots(),
                  firestore
                      .collection('Families')
                      .where('AreaId', isEqualTo: areaId)
                      .where(
                        'InsideFamily2',
                        isEqualTo: firestore.collection('Families').doc(id),
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
        'IsStore': 'محل؟',
      };

  @override
  Family copyWith() {
    return Family._createFromData(getMap(), ref);
  }
}
