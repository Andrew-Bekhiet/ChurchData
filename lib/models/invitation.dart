import 'package:churchdata/models/super_classes.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class Invitation extends DataObject {
  Invitation({
    required JsonRef ref,
    required String title,
    required this.generatedBy,
    required this.generatedOn,
    required this.expiryDate,
    this.link,
    this.usedBy,
    this.permissions,
  }) : super(ref, title, null);

  static Invitation? fromDoc(JsonDoc doc) =>
      doc.exists ? Invitation.createFromData(doc.data()!, doc.reference) : null;

  static Invitation fromQueryDoc(JsonQueryDoc doc) =>
      Invitation.createFromData(doc.data(), doc.reference);

  Invitation.createFromData(Json data, JsonRef ref)
      : usedBy = data['UsedBy'],
        generatedBy = data['GeneratedBy'],
        permissions = data['Permissions'],
        generatedOn = data['GeneratedOn'],
        expiryDate = data['ExpiryDate'],
        link = data['Link'],
        super.createFromData(data, ref) {
    name = data['Title'];
  }

  String get title => name;

  final String? link;
  String? usedBy;
  String generatedBy;
  Json? permissions;
  Timestamp? generatedOn;
  Timestamp expiryDate;

  bool get used => usedBy != null;

  @override
  Json getHumanReadableMap() {
    throw UnimplementedError();
  }

  @override
  Json getMap() {
    return {
      'Title': title,
      'UsedBy': usedBy,
      'GeneratedBy': generatedBy,
      'Permissions': permissions?.map(MapEntry.new) ?? {},
      'GeneratedOn': generatedOn,
      'ExpiryDate': expiryDate,
    };
  }

  @override
  Future<String> getSecondLine() async {
    if (used)
      return 'تم الاستخدام بواسطة: ' +
          (await User.getAllUsersLive())
              .docs
              .singleWhere((u) => u.id == usedBy)
              .data()['Name'];

    return SynchronousFuture(
      'ينتهي في ' + DateFormat('yyyy/M/d', 'ar-EG').format(expiryDate.toDate()),
    );
  }

  Invitation.empty()
      : expiryDate = Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 1, minutes: 10)),
        ),
        link = '',
        generatedBy = User.instance.uid!,
        super(firestore.collection('Invitations').doc(''), '', null) {
    name = '';
    permissions = {};
  }

  @override
  Invitation copyWith() {
    return Invitation.createFromData(getMap(), ref);
  }
}
