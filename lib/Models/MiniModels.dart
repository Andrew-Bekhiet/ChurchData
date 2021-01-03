import 'dart:async';
import 'dart:ui';

import 'package:churchdata/Models/super_classes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/globals.dart';

abstract class MiniModel extends DataObject {
  final String collectionName;
  MiniModel(this.collectionName, String id, [String name = '', Color color])
      : super(id, name, color);

  MiniModel.createFromData(
      this.collectionName, Map<String, dynamic> data, String id)
      : super.createFromData(data, id);

  MiniModel.createNew(this.collectionName)
      : super(FirebaseFirestore.instance.collection(collectionName).doc().id,
            '', null);

  @override
  DocumentReference get ref =>
      FirebaseFirestore.instance.collection(collectionName).doc(id);

  @override
  Map<String, dynamic> getExportMap() {
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> getHumanReadableMap() {
    throw UnimplementedError();
  }

  @override
  Future<String> getSecondLine() {
    throw UnimplementedError();
  }
}

class Church extends MiniModel with ParentObject<Father> {
  String address;
  Church(String id, String name, {this.address}) : super(id, name);
  Church._createFromData(Map<String, dynamic> data, String id)
      : super.createFromData('Churches', data, id) {
    address = data['Address'];
  }

  Church.createNew() : super.createNew('Churches') {
    address = '';
  }

  @override
  bool operator ==(dynamic other) {
    return other is Church && id == other.id;
  }

  @override
  Map<String, dynamic> getMap() {
    return {'Name': name, 'Address': address};
  }

  Future<Stream<QuerySnapshot>> getMembersLive() async {
    return FirebaseFirestore.instance
        .collection('Fathers')
        .where('ChurchId', isEqualTo: ref)
        .snapshots();
  }

  static Church fromDocumentSnapshot(DocumentSnapshot data) =>
      Church._createFromData(data.data(), data.id);

  static Future<QuerySnapshot> getAllForUser({String userUID}) {
    return FirebaseFirestore.instance
        .collection('Churches')
        .orderBy('Name')
        .get(dataSource);
  }

  @override
  Future<List<Father>> getChildren(
      [String orderBy = 'Name', bool tranucate = false]) async {
    return (await FirebaseFirestore.instance
            .collection('Fathers')
            .where('ChurchId', isEqualTo: ref)
            .get(dataSource))
        .docs
        .map((i) => Father.fromDocumentSnapshot(i))
        .toList();
  }
}

class PersonState extends MiniModel {
  PersonState(String id, String name, Color color)
      : super('States', id, name, color);
  PersonState._createFromData(Map<String, dynamic> data, String id)
      : super.createFromData('States', data, id) {
    color = Color(int.parse('0xFF' + data['Color']));
  }

  PersonState.createNew() : super.createNew('States');

  @override
  bool operator ==(dynamic other) {
    return other is PersonState && id == other.id;
  }

  @override
  Map<String, dynamic> getMap() {
    return {'Name': name, 'Color': color};
  }

  static PersonState fromDocumentSnapshot(DocumentSnapshot data) =>
      PersonState._createFromData(data.data(), data.id);

  static Future<QuerySnapshot> getAllForUser({String userUID}) {
    return FirebaseFirestore.instance
        .collection('States')
        .orderBy('Name')
        .get(dataSource);
  }
}

class College extends MiniModel {
  College(String id, String name) : super('Colleges', id, name);
  College._createFromData(Map<String, dynamic> data, id)
      : super.createFromData('Colleges', data, id);

  College.createNew() : super.createNew('Colleges');

  @override
  bool operator ==(dynamic other) {
    return other is College && id == other.id;
  }

  @override
  Map<String, dynamic> getMap() {
    return {'Name': name};
  }

  static College fromDocumentSnapshot(DocumentSnapshot data) =>
      College._createFromData(data.data(), data.id);

  static Future<QuerySnapshot> getAllForUser({String userUID}) {
    return FirebaseFirestore.instance
        .collection('Colleges')
        .orderBy('Name')
        .get(dataSource);
  }
}

class Father extends MiniModel with ChildObject<Church> {
  DocumentReference churchId;
  Father(String id, String name, this.churchId) : super('Fathers', id, name);
  Father._createFromData(Map<String, dynamic> data, String id)
      : super.createFromData('Fathers', data, id) {
    churchId = data['ChurchId'];
  }

  Father.createNew() : super.createNew('Fathers');

  @override
  @override
  DocumentReference get ref =>
      FirebaseFirestore.instance.collection('Fathers').doc(id);

  @override
  bool operator ==(dynamic other) {
    return other is Father && id == other.id;
  }

  Future<String> getChurchName() async {
    if (churchId == null) return '';
    return Church.fromDocumentSnapshot(
      await churchId.get(),
    ).name;
  }

  @override
  Map<String, dynamic> getMap() {
    return {'Name': name, 'ChurchId': churchId};
  }

  static Father fromDocumentSnapshot(DocumentSnapshot data) =>
      Father._createFromData(data.data(), data.id);

  static Future<QuerySnapshot> getAllForUser({String userUID}) {
    return FirebaseFirestore.instance
        .collection('Fathers')
        .orderBy('Name')
        .get(dataSource);
  }

  @override
  Future<String> getParentName() async {
    return (await churchId.get(dataSource)).data()['Name'];
  }

  @override
  DocumentReference get parentId => churchId;
}

class Job extends MiniModel {
  Job(String id, String name) : super('Jobs', id, name);
  Job._createFromData(Map<String, dynamic> data, String id)
      : super.createFromData('Jobs', data, id);

  Job.createNew() : super.createNew('Jobs');

  @override
  bool operator ==(dynamic other) {
    return other is Job && id == other.id;
  }

  @override
  Map<String, dynamic> getMap() {
    return {'Name': name};
  }

  static Job fromDocumentSnapshot(DocumentSnapshot data) =>
      Job._createFromData(data.data(), data.id);

  static Future<QuerySnapshot> getAllForUser({String userUID}) {
    return FirebaseFirestore.instance
        .collection('Jobs')
        .orderBy('Name')
        .get(dataSource);
  }
}

class PersonType extends MiniModel {
  PersonType(String id, String name) : super('Types', id, name);
  PersonType._createFromData(Map<String, dynamic> data, String id)
      : super.createFromData('Types', data, id);

  PersonType.createNew() : super.createNew('Types');

  @override
  bool operator ==(dynamic other) {
    return other is PersonType && id == other.id;
  }

  @override
  Map<String, dynamic> getMap() {
    return {'Name': name};
  }

  static PersonType fromDocumentSnapshot(DocumentSnapshot data) =>
      PersonType._createFromData(data.data(), data.id);

  static Future<QuerySnapshot> getAllForUser({String userUID}) {
    return FirebaseFirestore.instance
        .collection('Types')
        .orderBy('Name')
        .get(dataSource);
  }
}

class ServingType extends MiniModel {
  ServingType(String id, String name) : super('ServingTypes', id, name);
  ServingType._createFromData(Map<String, dynamic> data, String id)
      : super.createFromData('ServingTypes', data, id);

  ServingType.createNew() : super.createNew('ServingTypes');

  @override
  bool operator ==(dynamic other) {
    return other is ServingType && id == other.id;
  }

  @override
  Map<String, dynamic> getMap() {
    return {'Name': name};
  }

  static ServingType fromDocumentSnapshot(DocumentSnapshot data) =>
      ServingType._createFromData(data.data(), data.id);

  static Future<QuerySnapshot> getAllForUser({String userUID}) {
    return FirebaseFirestore.instance
        .collection('ServingTypes')
        .orderBy('Name')
        .get(dataSource);
  }
}

class StudyYear extends MiniModel {
  bool isCollegeYear;
  StudyYear(String id, String name) : super('StudyYears', id, name);
  StudyYear._createFromData(Map<String, dynamic> data, String id)
      : super.createFromData('StudyYears', data, id) {
    isCollegeYear = data['IsCollegeYear'];
  }

  StudyYear.createNew() : super.createNew('StudyYears') {
    isCollegeYear = false;
  }

  @override
  bool operator ==(dynamic other) {
    return other is StudyYear && id == other.id;
  }

  @override
  Map<String, dynamic> getMap() {
    return {'Name': name, 'IsCollegeYear': isCollegeYear};
  }

  static StudyYear fromDocumentSnapshot(DocumentSnapshot data) =>
      StudyYear._createFromData(data.data(), data.id);

  static Future<QuerySnapshot> getAllForUser({String userUID}) {
    return FirebaseFirestore.instance
        .collection('StudyYears')
        .orderBy('Name')
        .get(dataSource);
  }
}

class History {
  static Future<List<History>> getAllFromRef(CollectionReference ref) async {
    return (await ref
            .orderBy('Time', descending: true)
            .limit(1000)
            .get(dataSource))
        .docs
        .map((e) => fromDoc(e))
        .toList();
  }

  static History fromDoc(DocumentSnapshot doc) {
    return History(doc.id, doc.data()['By'], doc.data()['Time'], doc.reference);
  }

  String id;
  String byUser;
  Timestamp time;

  DocumentReference ref;

  History(this.id, this.byUser, this.time, this.ref);
}
