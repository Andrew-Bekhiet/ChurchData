import 'package:intl/intl.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:churchdata/models/super_classes.dart';
import 'package:churchdata/models/user.dart';

class Invitation extends DataObject {
  Invitation({
    String id,
    DocumentReference ref,
    String title,
    this.link,
    this.usedBy,
    this.generatedBy,
    this.permissions,
    this.generatedOn,
    this.expiryDate,
  }) : super(
            ref ?? FirebaseFirestore.instance.collection('Invitations').doc(id),
            title,
            null);

  static Invitation fromDoc(DocumentSnapshot doc) =>
      Invitation.createFromData(doc.data(), doc.reference);

  Invitation.createFromData(Map<String, dynamic> data, DocumentReference ref)
      : link = data['Link'],
        super.createFromData(data, ref) {
    name = data['Title'];
    usedBy = data['UsedBy'];
    generatedBy = data['GeneratedBy'];
    permissions = data['Permissions'];
    generatedOn = data['GeneratedOn'];
    expiryDate = data['ExpiryDate'];
  }

  String get title => name;

  final String link;
  String usedBy;
  String generatedBy;
  Map<String, dynamic> permissions;
  Timestamp generatedOn;
  Timestamp expiryDate;

  bool get used => usedBy != null;

  @override
  Map<String, dynamic> getHumanReadableMap() {
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> getMap() {
    return {
      'Title': title,
      'UsedBy': usedBy,
      'GeneratedBy': generatedBy,
      'Permissions': permissions?.map((k, v) => MapEntry(k, v)) ?? {},
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
    return 'ينتهي في ' +
        DateFormat('yyyy/M/d', 'ar-EG').format(expiryDate.toDate());
  }

  Invitation.empty()
      : link = '',
        super(FirebaseFirestore.instance.collection('Invitations').doc(''), '',
            null) {
    name = '';
    expiryDate =
        Timestamp.fromDate(DateTime.now().add(Duration(days: 1, minutes: 10)));
    permissions = {};
  }

  @override
  Invitation copyWith() {
    return Invitation.createFromData(getMap(), ref);
  }
}
