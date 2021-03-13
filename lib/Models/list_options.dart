import 'package:churchdata/models/super_classes.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'data_object_widget.dart';

class ListOptions<T extends DataObject> with ChangeNotifier {
  BehaviorSubject<List<T>> _documentsData;

  Stream<List<T>> get documentsData => _documentsData;

  set documentsData(Stream<List<T>> documentsData) {
    _documentsData = documentsData != null
        ? (BehaviorSubject<List<T>>()..addStream(documentsData))
        : null;
    _documentsData = documentsData;
  }

  List<T> _items = <T>[];
  bool _selectionMode = false;

  List<T> selected = <T>[];

  final void Function(T) tap;
  final void Function(T) onLongPress;
  final void Function(List<T>) getStringCount;

  final T empty;
  final bool showNull;

  Widget Function(T,
      {@required void Function() onLongPress,
      @required void Function() onTap,
      Widget trailing}) itemBuilder;
  final Widget floatingActionButton;
  final bool doubleActionButton;
  final bool hasNotch;

  ListOptions({
    this.getStringCount,
    this.doubleActionButton = false,
    this.hasNotch = true,
    this.floatingActionButton,
    this.itemBuilder,
    this.onLongPress,
    this.tap,
    this.empty,
    List<T> items,
    this.showNull = false,
    bool selectionMode = false,
    Stream<List<T>> documentsData,
    List<T> selected,
  })  : assert(showNull == false || (showNull == true && empty != null)),
        _items = items,
        _selectionMode = selectionMode {
    _documentsData = documentsData != null
        ? (BehaviorSubject<List<T>>()..addStream(documentsData))
        : null;
    this.selected = selected ?? [];
    itemBuilder ??= (i,
            {void Function() onLongPress,
            void Function() onTap,
            Widget trailing}) =>
        DataObjectWidget<T>(i,
            onLongPress: onLongPress, onTap: onTap, trailing: trailing);
  }

  List<T> get items => _items;
  set items(List<T> items) {
    _items = items;
    notifyListeners();
  }

  bool get selectionMode => _selectionMode;

  set selectionMode(bool selectionMode) {
    _selectionMode = selectionMode;
    notifyListeners();
  }
}
