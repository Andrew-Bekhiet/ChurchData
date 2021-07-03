import 'dart:async';

import 'package:churchdata/typedefs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

import '../utils/globals.dart';
import '../utils/helpers.dart';
import 'family.dart';
import 'super_classes.dart';
import 'user.dart';

class Person extends DataObject with PhotoObject, ChildObject<Family> {
  JsonRef? _familyId;

  JsonRef? get familyId => _familyId;

  set familyId(JsonRef? familyId) {
    if (familyId != null && _familyId != familyId) {
      _familyId = familyId;
      setStreetIdFromFamily();
      return;
    }
    _familyId = familyId;
  }

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

  String? phone;
  Json phones; //Other phones if any
  Timestamp? birthDate;

  Timestamp? lastConfession;
  Timestamp? lastTanawol;
  Timestamp? lastCall;

  bool isStudent;
  JsonRef? studyYear;
  JsonRef? college;
  JsonRef? job;
  String? jobDescription;
  String? qualification;
  String? type;
  bool isServant;

  JsonRef? servingAreaId;

  JsonRef? church;
  String? meeting;

  JsonRef? cFather;
  JsonRef? state;
  String? notes;
  JsonRef? servingType;

  String? lastEdit;

  Person(
      {String? id,
      JsonRef? ref,
      this.areaId,
      JsonRef? streetId,
      JsonRef? familyId,
      String name = '',
      this.phone = '',
      Json? phones,
      bool hasPhoto = false,
      this.birthDate,
      this.lastTanawol,
      this.lastCall,
      this.lastConfession,
      this.isStudent = false,
      this.studyYear,
      this.job,
      this.college,
      this.jobDescription = '',
      this.qualification = '',
      this.type = '',
      this.notes = '',
      this.isServant = false,
      this.servingAreaId,
      this.church,
      this.meeting = '',
      this.cFather,
      this.state,
      this.servingType,
      this.lastEdit,
      Color color = Colors.transparent})
      : _familyId = familyId,
        _streetId = streetId,
        phones = phones ?? {},
        super(
            ref ??
                FirebaseFirestore.instance
                    .collection('Persons')
                    .doc(id ?? 'null'),
            name,
            color) {
    this.hasPhoto = hasPhoto;
    phones ??= {};
    defaultIcon = Icons.person;
  }

  Person._createFromData(Json data, JsonRef ref)
      : isStudent = data['IsStudent'] ?? false,
        isServant = data['IsServant'],
        phones = data['Phones']?.cast<String, dynamic>() ?? {},
        super.createFromData(data, ref) {
    _familyId = data['FamilyId'];
    _streetId = data['StreetId'];
    areaId = data['AreaId'];

    phone = data['Phone'];

    hasPhoto = data['HasPhoto'] ?? false;
    defaultIcon = Icons.person;

    studyYear = data['StudyYear'];
    college = data['College'];

    birthDate = data['BirthDate'];
    lastConfession = data['LastConfession'];
    lastTanawol = data['LastTanawol'];
    lastCall = data['LastCall'];

    job = data['Job'];
    jobDescription = data['JobDescription'];
    qualification = data['Qualification'];

    type = data['Type'];

    notes = data['Notes'];
    servingAreaId = data['ServingAreaId'];

    church = data['Church'];
    meeting = data['Meeting'];
    cFather = data['CFather'];

    state = data['State'];
    servingType = data['ServingType'];

    lastEdit = data['LastEdit'];
  }

  Timestamp? get birthDay => birthDate != null
      ? Timestamp.fromDate(
          DateTime(1970, birthDate!.toDate().month, birthDate!.toDate().day),
        )
      : null;

  @override
  JsonRef? get parentId => familyId;

  @override
  Reference get photoRef =>
      FirebaseStorage.instance.ref().child('PersonsPhotos/$id');

  Future<String?> getAreaName() async {
    return (await areaId?.get(dataSource))?.data()?['Name'];
  }

  Future<String?> getCFatherName() async {
    return (await cFather?.get(dataSource))?.data()?['Name'];
  }

  Future<String?> getChurchName() async {
    return (await church?.get(dataSource))?.data()?['Name'];
  }

  Future<String?> getCollegeName() async {
    if (!isStudent) return '';
    return (await college?.get(dataSource))?.data()?['Name'];
  }

  Future<String?> getFamilyName() async {
    return (await familyId?.get(dataSource))?.data()?['Name'];
  }

  @override
  Json getHumanReadableMap() => {
        'Name': name,
        'Phone': phone ?? '',
        'BirthDate': toDurationString(birthDate, appendSince: false),
        'BirthDay': birthDay != null
            ? DateFormat('d/M').format(
                birthDay!.toDate(),
              )
            : '',
        'IsStudent': isStudent ? 'طالب' : '',
        'JobDescription': jobDescription ?? '',
        'Qualification': qualification ?? '',
        'Notes': notes ?? '',
        'IsServant': isServant ? 'خادم' : '',
        'Meeting': meeting ?? '',
        'LastTanawol': toDurationString(lastTanawol),
        'LastCall': toDurationString(lastCall),
        'LastConfession': toDurationString(lastConfession),
        'LastEdit': lastEdit
      };

  Future<String?> getJobName() async {
    return (await job?.get(dataSource))?.data()?['Name'];
  }

  Widget getLeftWidget({bool ignoreSetting = false}) {
    return FutureBuilder<Json?>(
      future: Future(
        () async {
          if (ignoreSetting ||
              Hive.box('Settings')
                  .get('ShowPersonState', defaultValue: false)) {
            return (await state?.get(dataSource))?.data();
          }
          return null;
        },
      ),
      builder: (context, color) {
        return color.data == null
            ? SizedBox(width: 1, height: 1)
            : Container(
                height: 50,
                width: 50,
                color: Color(
                  int.parse('0xff${color.data!['Color']}'),
                ),
              );
      },
    );
  }

  @override
  Json getMap() => {
        'FamilyId': familyId,
        'StreetId': streetId,
        'AreaId': areaId,
        'Name': name,
        'Phone': phone,
        'Phones': (phones.map((k, v) => MapEntry(k, v)))
          ..removeWhere((k, v) => v.toString().isEmpty),
        'HasPhoto': hasPhoto,
        'Color': color.value,
        'BirthDate': birthDate,
        'BirthDay': birthDay,
        'IsStudent': isStudent,
        'StudyYear': studyYear,
        'College': college,
        'Job': job,
        'JobDescription': jobDescription,
        'Qualification': qualification,
        'Type': type,
        'Notes': notes,
        'IsServant': isServant,
        'ServingAreaId': servingAreaId,
        'Church': church,
        'Meeting': meeting,
        'CFather': cFather,
        'State': state,
        'ServingType': servingType,
        'LastTanawol': lastTanawol,
        'LastCall': lastCall,
        'LastConfession': lastConfession,
        'LastEdit': lastEdit,
      };

  @override
  Future<String?> getParentName() => getFamilyName();

  String getSearchString() {
    return (name +
            (phone ?? '') +
            (birthDate?.toString() ?? '') +
            (jobDescription ?? '') +
            (qualification ?? '') +
            (meeting ?? '') +
            (notes ?? '') +
            (type ?? ''))
        .toLowerCase()
        .replaceAll(
            RegExp(
              r'[أإآ]',
            ),
            'ا')
        .replaceAll(
            RegExp(
              r'[ى]',
            ),
            'ي');
  }

  @override
  Future<String?> getSecondLine() async {
    String key = Hive.box('Settings').get('PersonSecondLine');
    if (key == 'Members') {
      return '';
    } else if (key == 'AreaId') {
      return getAreaName();
    } else if (key == 'StreetId') {
      return getStreetName();
    } else if (key == 'FamilyId') {
      return getFamilyName();
    } else if (key == 'StudyYear') {
      return getStudyYearName();
    } else if (key == 'College') {
      return getCollegeName();
    } else if (key == 'Job') {
      return getJobName();
    } else if (key == 'Type') {
      return getStringType();
    } else if (key == 'ServingAreaId') {
      return getServingAreaName();
    } else if (key == 'Church') {
      return getChurchName();
    } else if (key == 'CFather') {
      return getCFatherName();
    } else if (key == 'LastEdit') {
      return (await FirebaseFirestore.instance
              .doc('Users/$lastEdit')
              .get(dataSource))
          .data()?['Name'];
    }
    return getHumanReadableMap()[key];
  }

  Future<String?> getServingAreaName() async {
    if (!isServant) return '';
    return (await servingAreaId?.get(dataSource))?.data()?['Name'];
  }

  Future<String?> getServingTypeName() async {
    return (await servingType?.get(dataSource))?.data()?['Name'];
  }

  Future<String?> getStreetName() async {
    return (await streetId?.get(dataSource))?.data()?['Name'];
  }

  Future<String?> getStringType() async {
    if (type == null || type!.isEmpty) return null;
    return (await FirebaseFirestore.instance
            .collection('Types')
            .doc(type)
            .get(dataSource))
        .data()?['Name'];
  }

  Future<String?> getStudyYearName() async {
    if (!isStudent) return '';
    return (await studyYear?.get(dataSource))?.data()?['Name'];
  }

  Json getUserRegisterationMap() => {
        'Name': name,
        'Phone': phone,
        'HasPhoto': hasPhoto,
        'Color': color.value,
        'BirthDate': birthDate?.millisecondsSinceEpoch,
        'BirthDay': birthDay?.millisecondsSinceEpoch,
        'IsStudent': isStudent,
        'StudyYear': studyYear?.path,
        'College': college?.path,
        'Job': job?.path,
        'JobDescription': jobDescription,
        'Qualification': qualification,
        'Type': type,
        'Notes': notes,
        'IsServant': isServant,
        'Church': church?.path,
        'Meeting': meeting,
        'CFather': cFather?.path,
        'ServingType': servingType?.path,
        'LastTanawol': lastTanawol?.millisecondsSinceEpoch,
        'LastConfession': lastConfession?.millisecondsSinceEpoch
      };

  Future<void> setAreaIdFromStreet() async {
    areaId = (await streetId?.get(dataSource))?.data()?['AreaId'];
  }

  Future<void> setStreetIdFromFamily() async {
    streetId = (await familyId?.get(dataSource))?.data()?['StreetId'];
  }

  static Person? fromDoc(JsonDoc data) =>
      data.exists ? Person._createFromData(data.data()!, data.reference) : null;

  static Person fromQueryDoc(JsonQueryDoc data) => fromDoc(data)!;

  static Future<Person?> fromId(String id) async => Person.fromDoc(
        await FirebaseFirestore.instance.doc('Persons/$id').get(),
      );

  static List<Person?> getAll(List<JsonDoc> persons) {
    return persons.map(Person.fromDoc).toList();
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
                  .collection('Persons')
                  .orderBy(orderBy, descending: descending)
                  .snapshots()
              : FirebaseFirestore.instance
                  .collection('Persons')
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
        'FamilyId': 'familyId',
        'StreetId': 'streetId',
        'AreaId': 'areaId',
        'Name': 'name',
        'Phone': 'phone',
        'HasPhoto': 'hasPhoto',
        'Color': 'color',
        'BirthDate': 'birthDate',
        'BirthDay': 'birthDay',
        'IsStudent': 'isStudent',
        'StudyYear': 'studyYear',
        'College': 'college',
        'Job': 'job',
        'JobDescription': 'jobDescription',
        'Qualification': 'qualification',
        'Type': 'type',
        'Notes': 'notes',
        'IsServant': 'isServant',
        'ServingAreaId': 'servingAreaId',
        'Church': 'church',
        'Meeting': 'meeting',
        'CFather': 'cFather',
        'State': 'state',
        'ServantUserId': 'servantUserId',
        'ServingType': 'servingType',
        'LastTanawol': 'lastTanawol',
        'LastConfession': 'lastConfession',
        'LastEdit': 'lastEdit'
      };

  static Json getHumanReadableMap2() => {
        'Name': 'الاسم',
        'Phone': 'رقم الهاتف',
        'Color': 'اللون',
        'BirthDate': 'تاريخ الميلاد',
        'BirthDay': 'يوم الميلاد',
        'IsStudent': 'طالب؟',
        'JobDescription': 'تفاصيل الوظيفة',
        'Qualification': 'المؤهل',
        'Notes': 'ملاحظات',
        'IsServant': 'خادم؟',
        'Meeting': 'الاجتماع المشارك به',
        'Type': 'نوع الفرد',
        'LastTanawol': 'تاريخ أخر تناول',
        'LastCall': 'تاريخ أخر مكالمة',
        'LastConfession': 'تاريخ أخر اعتراف',
        'LastEdit': 'أخر شخص قام بالتعديل'
      };

  // @override
  // fireWeb.Reference get webPhotoRef =>
  //     fireWeb.storage().ref('PersonsPhotos/$id');

  @override
  Person copyWith() {
    return Person._createFromData(getMap(), ref);
  }
}
