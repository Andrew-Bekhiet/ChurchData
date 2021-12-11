import 'package:churchdata/models/models.dart';
import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

class HistoryRecord {
  final JsonRef docId;
  final JsonRef? areaId;
  final JsonRef? streetId;
  final JsonRef? familyId;
  final JsonRef? personId;

  final String? by;
  final Timestamp time;

  const HistoryRecord({
    this.areaId,
    this.streetId,
    this.familyId,
    this.personId,
    required this.by,
    required this.time,
    required this.docId,
  });

  static HistoryRecord? fromDoc(JsonDoc doc) {
    if (!doc.exists) return null;
    return HistoryRecord(
        areaId: doc.data()!['AreaId'],
        streetId: doc.data()!['StreetId'],
        familyId: doc.data()!['FamilyId'],
        personId: doc.data()!['PersonId'],
        by: doc.data()!['By'],
        time: doc.data()!['Time'],
        docId: doc.reference);
  }

  static HistoryRecord fromQueryDoc(JsonQueryDoc doc) {
    return HistoryRecord(
        areaId: doc.data()['AreaId'],
        streetId: doc.data()['StreetId'],
        familyId: doc.data()['FamilyId'],
        personId: doc.data()['PersonId'],
        by: doc.data()['By'],
        time: doc.data()['Time'],
        docId: doc.reference);
  }

  static Stream<List<JsonQueryDoc>> getAllForUser(
      {required String collectionGroup,
      DateTimeRange? range,
      List<Area>? areas}) {
    return Rx.combineLatest2<User, List<Area>, Tuple2<User, List<Area>>>(
            User.instance.stream,
            Area.getAllForUser()
                .map((s) => s.docs.map(Area.fromQueryDoc).toList()),
            Tuple2<User, List<Area>>.new)
        .switchMap((value) {
      if (range != null && areas != null) {
        return Rx.combineLatestList<JsonQuery>(areas
                .map((a) => firestore
                    .collectionGroup(collectionGroup)
                    .where('AreaId', isEqualTo: a.ref)
                    .where(
                      'Time',
                      isLessThanOrEqualTo: Timestamp.fromDate(
                          range.end.add(const Duration(days: 1))),
                    )
                    .where('Time',
                        isGreaterThanOrEqualTo: Timestamp.fromDate(
                            range.start.subtract(const Duration(days: 1))))
                    .orderBy('Time', descending: true)
                    .snapshots())
                .toList())
            .map((s) => s.expand((n) => n.docs).toList());
      } else if (range != null) {
        if (value.item1.superAccess) {
          return firestore
              .collectionGroup(collectionGroup)
              .where(
                'Time',
                isLessThanOrEqualTo:
                    Timestamp.fromDate(range.end.add(const Duration(days: 1))),
              )
              .where('Time',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(
                      range.start.subtract(const Duration(days: 1))))
              .orderBy('Time', descending: true)
              .snapshots()
              .map((s) => s.docs);
        } else {
          return Rx.combineLatestList<JsonQuery>(value.item2
                  .map((a) => firestore
                      .collectionGroup(collectionGroup)
                      .where('AreaId', isEqualTo: a.ref)
                      .where(
                        'Time',
                        isLessThanOrEqualTo: Timestamp.fromDate(
                            range.end.add(const Duration(days: 1))),
                      )
                      .where('Time',
                          isGreaterThanOrEqualTo: Timestamp.fromDate(
                              range.start.subtract(const Duration(days: 1))))
                      .orderBy('Time', descending: true)
                      .snapshots())
                  .toList())
              .map((s) => s.expand((n) => n.docs).toList());
        }
      } else if (areas != null) {
        return Rx.combineLatestList<JsonQuery>(areas
                .map((a) => firestore
                    .collectionGroup(collectionGroup)
                    .where('AreaId', isEqualTo: a.ref)
                    .orderBy('Time', descending: true)
                    .snapshots())
                .toList())
            .map((s) => s.expand((n) => n.docs).toList());
      }
      return firestore
          .collectionGroup(collectionGroup)
          .orderBy('Time', descending: true)
          .snapshots()
          .map((s) => s.docs.toList());
    });
  }

  Type get parentType => docId.path.startsWith('Areas')
      ? Area
      : docId.path.startsWith('Streets')
          ? Street
          : docId.path.startsWith('Families')
              ? Family
              : docId.path.startsWith('Persons')
                  ? Person
                  : Type;
}
