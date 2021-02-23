import 'package:async/async.dart';
import 'package:churchdata/Models/super_classes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'User.dart';

class ListOptions<T extends DataObject> with ChangeNotifier {
  final bool showNull;
  List<DocumentSnapshot> _items = [];

  bool _selectionMode = false;

  bool isAdmin = false;

  Stream<QuerySnapshot> _documentsData;

  Stream<List<QuerySnapshot>> _familiesData;

  List<T> selected = <T>[];

  Map<String, AsyncMemoizer<String>> cache = {};
  final void Function(T, BuildContext) tap;

  covariant DataObject Function(DocumentSnapshot) generate;

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
      List<DocumentSnapshot> items,
      this.showNull = false,
      bool selectionMode = false,
      Stream<QuerySnapshot> documentsData,
      Stream<List<QuerySnapshot>> familiesData,
      bool isAdmin})
      : assert((items != null && items != []) ||
            documentsData != null ||
            familiesData != null),
        assert(showNull == false || (showNull == true && empty != null)) {
    this.isAdmin = isAdmin ?? User.instance.superAccess ?? false;
    _documentsData = documentsData?.asBroadcastStream();
    _familiesData = familiesData?.asBroadcastStream();
    if (items != null && (cache?.length ?? 0) != items.length) {
      cache = {for (var d in items) d.id: AsyncMemoizer<String>()};
    }
  }
  Stream<QuerySnapshot> get documentsData => _documentsData;

  set documentsData(Stream<QuerySnapshot> documentsData) {
    _documentsData = documentsData.asBroadcastStream();
  }

  Stream<List<QuerySnapshot>> get familiesData => _familiesData;
  set familiesData(Stream<List<QuerySnapshot>> familiesData) {
    _familiesData = familiesData.asBroadcastStream();
  }

  List<DocumentSnapshot> get items => _items;
  set items(List<DocumentSnapshot> items) {
    _items = items;
    notifyListeners();
  }

  bool get selectionMode => _selectionMode;

  set selectionMode(bool selectionMode) {
    _selectionMode = selectionMode;
    notifyListeners();
  }
}
