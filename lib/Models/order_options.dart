import 'dart:async';

import 'package:churchdata/models/super_classes.dart';
import 'package:flutter/material.dart';

import 'area.dart';
import 'family.dart';
import 'person.dart';
import 'street.dart';

class OrderOptions extends ChangeNotifier {
  String areaOrderBy;
  String streetOrderBy;
  String familyOrderBy;
  String personOrderBy;

  bool areaASC;
  bool streetASC;
  bool familyASC;
  bool personASC;

  StreamController<bool> areaSelectAll = StreamController.broadcast();
  StreamController<bool> streetSelectAll = StreamController.broadcast();
  StreamController<bool> familySelectAll = StreamController.broadcast();
  StreamController<bool> personSelectAll = StreamController.broadcast();

  OrderOptions({
    this.areaOrderBy = 'Name',
    this.streetOrderBy = 'Name',
    this.familyOrderBy = 'Name',
    this.personOrderBy = 'Name',
    this.areaASC = true,
    this.streetASC = true,
    this.familyASC = true,
    this.personASC = true,
  });

  void setAreaOrderBy(String orderBy) {
    areaOrderBy = orderBy;
    notifyListeners();
  }

  void setStreetOrderBy(String orderBy) {
    streetOrderBy = orderBy;
    notifyListeners();
  }

  void setFamilyOrderBy(String orderBy) {
    familyOrderBy = orderBy;
    notifyListeners();
  }

  void setPersonOrderBy(String orderBy) {
    personOrderBy = orderBy;
    notifyListeners();
  }

  void setAreaASC(bool asc) {
    areaASC = asc;
    notifyListeners();
  }

  void setStreetASC(bool asc) {
    streetASC = asc;
    notifyListeners();
  }

  void setFamilyASC(bool asc) {
    familyASC = asc;
    notifyListeners();
  }

  void setPersonASC(bool asc) {
    personASC = asc;
    notifyListeners();
  }

  StreamController<bool> selectAllOf<T extends DataObject>() {
    if (T == Area) return areaSelectAll;
    if (T == Street) return streetSelectAll;
    if (T == Family) return familySelectAll;
    if (T == Person) return personSelectAll;
    throw UnimplementedError();
  }

  @override
  void dispose() {
    areaSelectAll.close();
    streetSelectAll.close();
    familySelectAll.close();
    personSelectAll.close();
    super.dispose();
  }
}
