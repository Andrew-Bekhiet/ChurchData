import 'package:churchdata/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

class HistoryRecord {
  final DocumentReference docId;
  final DocumentReference areaId;
  final DocumentReference streetId;
  final DocumentReference familyId;
  final DocumentReference personId;

  final String by;
  final Timestamp time;

  const HistoryRecord({
    this.areaId,
    this.streetId,
    this.familyId,
    this.personId,
    this.by,
    this.time,
    this.docId,
  });

  static HistoryRecord fromDoc(DocumentSnapshot doc) {
    return HistoryRecord(
        areaId: doc.data()['AreaId'],
        streetId: doc.data()['StreetId'],
        familyId: doc.data()['FamilyId'],
        personId: doc.data()['PersonId'],
        by: doc.data()['By'],
        time: doc.data()['Time'],
        docId: doc.reference);
  }

  static Stream<List<QueryDocumentSnapshot>> getAllForUser(
      {@required String collectionGroup,
      DateTimeRange range,
      List<Area> areas}) {
    return Rx.combineLatest2<User, List<Area>, Tuple2<User, List<Area>>>(
        User.instance.stream,
        Area.getAllForUser().map((s) => s.docs.map(Area.fromDoc).toList()),
        (a, b) => Tuple2<User, List<Area>>(a, b)).switchMap((value) {
      if (range != null && areas != null) {
        return Rx.combineLatestList<QuerySnapshot>(areas
                .map((a) => FirebaseFirestore.instance
                    .collectionGroup(collectionGroup)
                    .where('AreaId', isEqualTo: a.ref)
                    .where(
                      'Time',
                      isLessThanOrEqualTo:
                          Timestamp.fromDate(range.end.add(Duration(days: 1))),
                    )
                    .where('Time',
                        isGreaterThanOrEqualTo: Timestamp.fromDate(
                            range.start.subtract(Duration(days: 1))))
                    .orderBy('Time', descending: true)
                    .snapshots())
                .toList())
            .map((s) => s.expand((n) => n.docs).toList());
      } else if (range != null) {
        if (value.item1.superAccess) {
          return FirebaseFirestore.instance
              .collectionGroup(collectionGroup)
              .where(
                'Time',
                isLessThanOrEqualTo:
                    Timestamp.fromDate(range.end.add(Duration(days: 1))),
              )
              .where('Time',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(
                      range.start.subtract(Duration(days: 1))))
              .orderBy('Time', descending: true)
              .snapshots()
              .map((s) => s.docs);
        } else {
          return Rx.combineLatestList<QuerySnapshot>(value.item2
                  .map((a) => FirebaseFirestore.instance
                      .collectionGroup(collectionGroup)
                      .where('AreaId', isEqualTo: a.ref)
                      .where(
                        'Time',
                        isLessThanOrEqualTo: Timestamp.fromDate(
                            range.end.add(Duration(days: 1))),
                      )
                      .where('Time',
                          isGreaterThanOrEqualTo: Timestamp.fromDate(
                              range.start.subtract(Duration(days: 1))))
                      .orderBy('Time', descending: true)
                      .snapshots())
                  .toList())
              .map((s) => s.expand((n) => n.docs).toList());
        }
      } else if (areas != null) {
        return Rx.combineLatestList<QuerySnapshot>(areas
                .map((a) => FirebaseFirestore.instance
                    .collectionGroup(collectionGroup)
                    .where('AreaId', isEqualTo: a.ref)
                    .orderBy('Time', descending: true)
                    .snapshots())
                .toList())
            .map((s) => s.expand((n) => n.docs).toList());
      }
      return FirebaseFirestore.instance
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
