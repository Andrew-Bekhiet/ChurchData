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
import 'family.dart';
import 'map_view.dart';
import 'person.dart';
import 'super_classes.dart';
import 'user.dart';

class Area extends DataObject with PhotoObject, ParentObject<Street> {
  String? address;

  bool locationConfirmed;
  List<GeoPoint> locationPoints;

  Timestamp? lastVisit;
  Timestamp? fatherLastVisit;

  List<String> allowedUsers;
  String? lastEdit;

  Area({
    required String name,
    required this.allowedUsers,
    required JsonRef ref,
    this.address,
    bool hasPhoto = false,
    this.locationConfirmed = false,
    this.lastVisit,
    this.fatherLastVisit,
    this.lastEdit,
    Color color = Colors.transparent,
    List<GeoPoint>? locationPoints,
  })  : locationPoints = locationPoints ?? [],
        super(ref, name, color) {
    this.hasPhoto = hasPhoto;
    defaultIcon = Icons.pin_drop;
  }

  @override
  Area.createFromData(Json data, JsonRef ref)
      : allowedUsers = data['Allowed']?.cast<String>() ?? [],
        locationConfirmed = data['LocationConfirmed'] ?? false,
        locationPoints = data['Location']?.cast<GeoPoint>() ?? [],
        super.createFromData(data, ref) {
    address = data['Address'];

    hasPhoto = data['hasPhoto'] ?? false;

    lastVisit = data['LastVisit'];
    fatherLastVisit = data['FatherLastVisit'];

    lastEdit = data['LastEdit'];

    defaultIcon = Icons.pin_drop;
  }

  @override
  Reference get photoRef => firebaseStorage.ref().child('AreasPhotos/$id');

  @override
  Future<List<Street>> getChildren([
    String orderBy = 'Name',
    bool tranucate = false,
  ]) async {
    if (tranucate) {
      return Street.getAll(
        (await firestore
                .collection('Streets')
                .where('AreaId', isEqualTo: ref)
                .orderBy(orderBy)
                .limit(5)
                .get())
            .docs,
      ).cast<Street>();
    }
    return Street.getAll(
      (await firestore
              .collection('Streets')
              .where('AreaId', isEqualTo: ref)
              .orderBy(orderBy)
              .get())
          .docs,
    ).cast<Street>();
  }

  Future<List<Family>> getFamilyMembersList([
    String orderBy = 'Name',
    bool tranucate = false,
  ]) async {
    if (tranucate) {
      return Family.getAll(
        (await firestore
                .collection('Families')
                .where('AreaId', isEqualTo: ref)
                .limit(5)
                .orderBy(orderBy)
                .get())
            .docs,
      ).cast<Family>();
    }
    return Family.getAll(
      (await firestore
              .collection('Families')
              .where('AreaId', isEqualTo: ref)
              .orderBy(orderBy)
              .get())
          .docs,
    ).cast<Family>();
  }

  @override
  Json getHumanReadableMap() => {
        'Name': name,
        'Address': address ?? '',
        'LastVisit': toDurationString(lastVisit),
        'FatherLastVisit': toDurationString(fatherLastVisit),
      };

  @override
  Json getMap() => {
        'Name': name,
        'Address': address,
        'hasPhoto': hasPhoto,
        'Location': locationPoints.sublist(0),
        'LocationConfirmed': locationConfirmed,
        'Color': color.value,
        'LastVisit': lastVisit,
        'FatherLastVisit': fatherLastVisit,
        'Allowed': allowedUsers,
        'LastEdit': lastEdit,
      };

  Widget getMapView({
    int depth = 2,
    bool useGPSIfNull = false,
    bool editMode = false,
  }) {
    if (locationPoints.isEmpty && useGPSIfNull)
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
                  childrenDepth: depth,
                  initialLocation: LatLng(
                    snapshot.data!.latitude!,
                    snapshot.data!.longitude!,
                  ),
                  editMode: editMode,
                  area: this,
                );
              },
            );
          }
          return MapView(
            childrenDepth: depth,
            initialLocation: const LatLng(30.033333, 31.233334),
            editMode: editMode,
            area: this,
          );
        },
      );
    else if (locationPoints.isEmpty)
      return const Text(
        'لم يتم تحديد موقع للمنطقة',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      );
    return MapView(childrenDepth: depth, editMode: editMode, area: this);
  }

  Stream<JsonQuery> getMembersLive({
    String orderBy = 'Name',
    bool descending = false,
  }) {
    return Area.getAreaChildrenLive(id, orderBy, descending);
  }

  Future<List<Person>> getPersonMembersList([
    String orderBy = 'Name',
    bool tranucate = false,
  ]) async {
    if (tranucate) {
      return Person.getAll(
        (await firestore
                .collection('Persons')
                .where('AreaId', isEqualTo: ref)
                .limit(5)
                .orderBy(orderBy)
                .get())
            .docs,
      ).cast<Person>();
    }
    return Person.getAll(
      (await firestore
              .collection('Persons')
              .where('AreaId', isEqualTo: ref)
              .orderBy(orderBy)
              .get())
          .docs,
    ).cast<Person>();
  }

  @override
  Future<String> getSecondLine() async {
    final String key = Hive.box('Settings').get('AreaSecondLine');
    if (key == 'Members') {
      return getMembersString();
    } else if (key == 'Allowed') {
      return (await Future.wait(
        allowedUsers
            .take(5)
            .map(
              (item) => firestore.doc('Users/$item').get(),
            )
            .toList(),
      ))
          .map((e) => e.data()?['Name'])
          .join(',');
    } else if (key == 'LastEdit') {
      return (await firestore.doc('Users/$lastEdit').get()).data()?['Name'];
    }

    return SynchronousFuture(getHumanReadableMap()[key]);
  }

  static Area empty() {
    return Area(
      name: '',
      allowedUsers: [User.instance.uid!],
      ref: FirebaseFirestore.instance.collection('Areas').doc('null'),
    );
  }

  static Area? fromDoc(JsonDoc data) =>
      data.exists ? Area.createFromData(data.data()!, data.reference) : null;

  static Area fromQueryDoc(JsonQueryDoc data) => fromDoc(data)!;

  static Future<Area?> fromId(String id) async => Area.fromDoc(
        await firestore.doc('Areas/$id').get(),
      );

  static List<Area?> getAll(List<JsonDoc> areas) {
    return areas.map(Area.fromDoc).toList();
  }

  static Future<List<Area>> getAllAreasForUser({
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
    String? uid,
    String orderBy = 'Name',
    bool descending = false,
  }) {
    return User.instance.stream.switchMap(
      (u) => uid == null
          ? u.superAccess
              ? firestore
                  .collection('Areas')
                  .orderBy(orderBy, descending: descending)
                  .snapshots()
              : firestore
                  .collection('Areas')
                  .where('Allowed', arrayContains: uid ?? u.uid)
                  .orderBy(orderBy, descending: descending)
                  .snapshots()
          : firestore
              .collection('Areas')
              .where('Allowed', arrayContains: uid)
              .orderBy(orderBy, descending: descending)
              .snapshots(),
    );
  }

  static Stream<JsonQuery> getAreaChildrenLive(
    String id, [
    String orderBy = 'Name',
    bool descending = false,
  ]) {
    return firestore
        .collection('Streets')
        .where(
          'AreaId',
          isEqualTo: firestore.collection('Areas').doc(id),
        )
        .orderBy(orderBy, descending: descending)
        .snapshots();
  }

  static Json getEmptyExportMap() => {
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
        'LastEdit': 'lastEdit',
      };

  static Json getStaticHumanReadableMap() => {
        'Name': 'الاسم',
        'Address': 'العنوان',
        'LastVisit': 'أخر زيارة',
        'Color': 'اللون',
        'FatherLastVisit': 'أخر زيارة (الأب الكاهن)',
        'Allowed': 'الأشخاص المسموح لهم بالرؤية والتعديل',
        'LastEdit': 'أخر شخص قام بالتعديل',
      };

  @override
  Area copyWith() {
    return Area.createFromData(getMap(), ref);
  }

  // @override
  // fireWeb.Reference get webPhotoRef =>
  //     fireWeb.storage().ref('AreasPhotos/$id');
}
