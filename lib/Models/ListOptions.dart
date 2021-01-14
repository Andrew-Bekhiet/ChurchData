import 'package:async/async.dart';
import 'package:churchdata/Models/super_classes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'User.dart';

class UsersCheckListOptions with ChangeNotifier {
  bool grouped = false;
  bool showTrueOnly = false;
  List<User> users = [];
  bool enabled = true;
  Future<List<User>> usersData;

  UsersCheckListOptions(
      {this.grouped,
      this.showTrueOnly,
      this.users,
      this.enabled,
      this.usersData})
      : assert((users != null && users != []) || usersData != null);

  void changeDocs(List<User> docs) {
    users = docs;
    notifyListeners();
  }

  bool changeEnabled(bool enalbed) {
    enabled = enabled;
    return enabled;
  }

  bool changeGrouped(bool grouped) {
    this.grouped = grouped;
    notifyListeners();
    return grouped;
  }

  bool changeShowTrueOnly(bool showTrueOnly) {
    this.showTrueOnly = showTrueOnly;
    notifyListeners();
    return showTrueOnly;
  }
}

class ListOptions<T extends DataObject> with ChangeNotifier {
  final bool showNull;
  List<DocumentSnapshot> items = [];
  bool selectionMode = false;
  bool isAdmin = false;
  Future<Stream<QuerySnapshot>> Function() documentsData;
  Future<List<QueryDocumentSnapshot>> Function() familyData;

  List<T> selected = <T>[];
  List<AsyncMemoizer<String>> cache = <AsyncMemoizer<String>>[];

  final void Function(T, BuildContext) tap;
  final DataObject Function(DocumentSnapshot) generate;
  final T empty;

  final Widget floatingActionButton;
  final bool doubleActionButton;
  final bool hasNotch;

  ListOptions(
      {this.doubleActionButton = false,
      this.hasNotch = true,
      this.floatingActionButton,
      this.tap,
      this.generate,
      this.empty,
      this.items,
      this.showNull = false,
      this.selectionMode = false,
      this.documentsData,
      this.familyData,
      bool isAdmin})
      : assert((items != null && items != []) ||
            documentsData != null ||
            familyData != null),
        assert(showNull == false || (showNull == true && empty != null)) {
    this.isAdmin = isAdmin ?? User().superAccess ?? false;
    if (items != null && (cache?.length ?? 0) != items.length) {
      cache = List.generate(items.length, (_) => AsyncMemoizer<String>());
    }
  }

  void changeItems(List<DocumentSnapshot> items) {
    this.items = items;
    if (items != null && (cache?.length ?? 0) != items.length) {
      cache = List.generate(items.length, (_) => AsyncMemoizer<String>());
    }
    notifyListeners();
  }

  void changeSelectionMode(bool selectionMode) {
    this.selectionMode = selectionMode;
    notifyListeners();
  }

  void changeIsAdmin(bool isAdmin) {
    this.isAdmin = isAdmin;
    notifyListeners();
  }
}
