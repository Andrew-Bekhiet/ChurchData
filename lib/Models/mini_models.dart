import 'dart:async';
import 'dart:ui';

import 'package:churchdata/models/super_classes.dart';
import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/globals.dart';

abstract class MiniModel extends DataObject {
  final String collectionName;
  MiniModel(this.collectionName, String id, [String name = '', Color? color])
      : super(firestore.collection(collectionName).doc(id), name, color);

  MiniModel.createFromData(this.collectionName, Json data, String id)
      : super.createFromData(
            data, firestore.collection(collectionName).doc(id));

  MiniModel.createNew(this.collectionName)
      : super(firestore.collection(collectionName).doc(), '', null);

  @override
  Json getHumanReadableMap() {
    return {};
  }

  @override
  Future<String?> getSecondLine() async {
    return null;
  }

  @override
  MiniModel copyWith() {
    throw UnimplementedError();
  }
}

class Church extends MiniModel with ParentObject<Father> {
  String? address;
  Church(String id, String name, {this.address}) : super(id, name);
  Church._createFromData(Json data, String id)
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
  Json getMap() {
    return {'Name': name, 'Address': address};
  }

  Stream<JsonQuery> getMembersLive() {
    return firestore
        .collection('Fathers')
        .where('ChurchId', isEqualTo: ref)
        .snapshots();
  }

  static Church? fromDoc(JsonDoc data) =>
      data.exists ? Church._createFromData(data.data()!, data.id) : null;

  static Church fromQueryDoc(JsonQueryDoc data) =>
      Church._createFromData(data.data(), data.id);

  static Future<JsonQuery> getAllForUser() {
    return firestore.collection('Churches').orderBy('Name').get(dataSource);
  }

  @override
  Future<List<Father>> getChildren(
      [String orderBy = 'Name', bool tranucate = false]) async {
    return (await firestore
            .collection('Fathers')
            .where('ChurchId', isEqualTo: ref)
            .get(dataSource))
        .docs
        .map(Father.fromQueryDoc)
        .toList();
  }
}

class PersonState extends MiniModel {
  PersonState(String id, String name, Color color)
      : super('States', id, name, color);
  PersonState._createFromData(Json data, String id)
      : super.createFromData('States', data, id) {
    color = Color(int.parse('0xFF' + data['Color']));
  }

  PersonState.createNew() : super.createNew('States');

  @override
  bool operator ==(dynamic other) {
    return other is PersonState && id == other.id;
  }

  @override
  Json getMap() {
    return {'Name': name, 'Color': color};
  }

  static PersonState? fromDoc(JsonDoc data) =>
      data.exists ? PersonState._createFromData(data.data()!, data.id) : null;

  static PersonState fromQueryDoc(JsonQueryDoc data) =>
      PersonState._createFromData(data.data(), data.id);

  static Future<JsonQuery> getAllForUser() {
    return firestore.collection('States').orderBy('Name').get(dataSource);
  }
}

class College extends MiniModel {
  College(String id, String name) : super('Colleges', id, name);
  College._createFromData(Json data, id)
      : super.createFromData('Colleges', data, id);

  College.createNew() : super.createNew('Colleges');

  @override
  bool operator ==(dynamic other) {
    return other is College && id == other.id;
  }

  @override
  Json getMap() {
    return {'Name': name};
  }

  static College? fromDoc(JsonDoc data) =>
      data.exists ? College._createFromData(data.data()!, data.id) : null;

  static College fromQueryDoc(JsonQueryDoc data) =>
      College._createFromData(data.data(), data.id);

  static Future<JsonQuery> getAllForUser() {
    return firestore.collection('Colleges').orderBy('Name').get(dataSource);
  }
}

class Father extends MiniModel with ChildObject<Church> {
  JsonRef? churchId;
  Father(String id, String name, this.churchId) : super('Fathers', id, name);
  Father._createFromData(Json data, String id)
      : super.createFromData('Fathers', data, id) {
    churchId = data['ChurchId'];
  }

  Father.createNew() : super.createNew('Fathers');

  @override
  bool operator ==(dynamic other) {
    return other is Father && id == other.id;
  }

  Future<String?> getChurchName() async {
    if (churchId == null) return null;
    return Church.fromDoc(
      await churchId!.get(),
    )?.name;
  }

  @override
  Json getMap() {
    return {'Name': name, 'ChurchId': churchId};
  }

  static Father? fromDoc(JsonDoc data) =>
      data.exists ? Father._createFromData(data.data()!, data.id) : null;

  static Father fromQueryDoc(JsonQueryDoc data) =>
      Father._createFromData(data.data(), data.id);

  static Future<JsonQuery> getAllForUser() {
    return firestore.collection('Fathers').orderBy('Name').get(dataSource);
  }

  @override
  Future<String?> getParentName() async {
    return (await churchId?.get(dataSource))?.data()?['Name'];
  }

  @override
  JsonRef? get parentId => churchId;
}

class Job extends MiniModel {
  Job(String id, String name) : super('Jobs', id, name);
  Job._createFromData(Json data, String id)
      : super.createFromData('Jobs', data, id);

  Job.createNew() : super.createNew('Jobs');

  @override
  bool operator ==(dynamic other) {
    return other is Job && id == other.id;
  }

  @override
  Json getMap() {
    return {'Name': name};
  }

  static Job? fromDoc(JsonDoc data) =>
      data.exists ? Job._createFromData(data.data()!, data.id) : null;

  static Job fromQueryDoc(JsonQueryDoc data) =>
      Job._createFromData(data.data(), data.id);

  static Future<JsonQuery> getAllForUser() {
    return firestore.collection('Jobs').orderBy('Name').get(dataSource);
  }
}

class PersonType extends MiniModel {
  PersonType(String id, String name) : super('Types', id, name);
  PersonType._createFromData(Json data, String id)
      : super.createFromData('Types', data, id);

  PersonType.createNew() : super.createNew('Types');

  @override
  bool operator ==(dynamic other) {
    return other is PersonType && id == other.id;
  }

  @override
  Json getMap() {
    return {'Name': name};
  }

  static PersonType? fromDoc(JsonDoc data) =>
      data.exists ? PersonType._createFromData(data.data()!, data.id) : null;

  static PersonType fromQueryDoc(JsonQueryDoc data) =>
      PersonType._createFromData(data.data(), data.id);

  static Future<JsonQuery> getAllForUser() {
    return firestore.collection('Types').orderBy('Name').get(dataSource);
  }
}

class ServingType extends MiniModel {
  ServingType(String id, String name) : super('ServingTypes', id, name);
  ServingType._createFromData(Json data, String id)
      : super.createFromData('ServingTypes', data, id);

  ServingType.createNew() : super.createNew('ServingTypes');

  @override
  bool operator ==(dynamic other) {
    return other is ServingType && id == other.id;
  }

  @override
  Json getMap() {
    return {'Name': name};
  }

  static ServingType? fromDoc(JsonDoc data) =>
      data.exists ? ServingType._createFromData(data.data()!, data.id) : null;

  static ServingType fromQueryDoc(JsonQueryDoc data) =>
      ServingType._createFromData(data.data(), data.id);

  static Future<JsonQuery> getAllForUser() {
    return firestore.collection('ServingTypes').orderBy('Name').get(dataSource);
  }
}

class StudyYear extends MiniModel {
  bool isCollegeYear;
  StudyYear(String id, String name, {this.isCollegeYear = false})
      : super('StudyYears', id, name);
  StudyYear._createFromData(Json data, String id)
      : isCollegeYear = data['IsCollegeYear'],
        super.createFromData('StudyYears', data, id);

  StudyYear.createNew()
      : isCollegeYear = false,
        super.createNew('StudyYears');

  @override
  bool operator ==(dynamic other) {
    return other is StudyYear && id == other.id;
  }

  @override
  Json getMap() {
    return {'Name': name, 'IsCollegeYear': isCollegeYear};
  }

  static StudyYear? fromDoc(JsonDoc data) =>
      data.exists ? StudyYear._createFromData(data.data()!, data.id) : null;

  static StudyYear fromQueryQueryDoc(JsonQueryDoc data) =>
      StudyYear._createFromData(data.data(), data.id);

  static Future<JsonQuery> getAllForUser() {
    return firestore.collection('StudyYears').orderBy('Name').get(dataSource);
  }
}

class History {
  static Future<List<History>> getAllFromRef(JsonCollectionRef ref) async {
    return (await ref
            .orderBy('Time', descending: true)
            .limit(1000)
            .get(dataSource))
        .docs
        .map(fromQueryDoc)
        .toList();
  }

  static History? fromDoc(JsonDoc doc) {
    return doc.exists
        ? History(doc.id, doc.data()!['By'], doc.data()!['Time'], doc.reference)
        : null;
  }

  static History fromQueryDoc(JsonQueryDoc doc) {
    return History(doc.id, doc.data()['By'], doc.data()['Time'], doc.reference);
  }

  String id;
  String? byUser;
  Timestamp? time;

  JsonRef ref;

  History(this.id, this.byUser, this.time, this.ref);
}
