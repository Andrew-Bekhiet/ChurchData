import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:churchdata/models/data_object_widget.dart';
import 'package:churchdata/models/super_classes.dart';
import 'package:rxdart/rxdart.dart';

abstract class BaseListOptions<L, U> {
  final BehaviorSubject<L> _objectsData;
  BehaviorSubject<L> get objectsData => _objectsData;
  L get items => _objectsData.value;

  final BehaviorSubject<bool> _selectionMode;
  BehaviorSubject<bool> get selectionMode => _selectionMode;
  bool get selectionModeLatest => _selectionMode.value;

  final BehaviorSubject<Map<String, U>> _selected;
  BehaviorSubject<Map<String, U>> get selected => _selected;
  Map<String, U> get selectedLatest => _selected.value;

  final void Function(U) tap;
  final void Function(U) onLongPress;

  final U empty;
  final bool showNull;

  void selectAll();
  void selectNone() {
    if (!_selectionMode.value) _selectionMode.add(true);
    _selected.add({});
  }

  void toggleSelected(U item);

  void select(U item);

  void deselect(U item);

  BaseListOptions({
    this.onLongPress,
    this.tap,
    this.empty,
    this.showNull = false,
    bool selectionMode = false,
    Stream<L> itemsStream,
    L items,
    Map<String, U> selected,
  })  : assert(itemsStream != null || items != null),
        assert(showNull == false || (showNull == true && empty != null)),
        _selectionMode = BehaviorSubject<bool>.seeded(selectionMode),
        _selected = BehaviorSubject<Map<String, U>>.seeded(selected ?? {}),
        _objectsData = itemsStream != null
            ? (BehaviorSubject<L>()..addStream(itemsStream))
            : BehaviorSubject<L>.seeded(items);
}

class DataObjectListOptions<T extends DataObject>
    implements BaseListOptions<List<T>, T> {
  @override
  BehaviorSubject<List<T>> _objectsData;
  @override
  BehaviorSubject<List<T>> get objectsData => _objectsData;
  @override
  List<T> get items => objectsData.value;

  final BehaviorSubject<List<T>> originalObjectsData;

  @override
  final BehaviorSubject<bool> _selectionMode;
  @override
  BehaviorSubject<bool> get selectionMode => _selectionMode;
  @override
  bool get selectionModeLatest => _selectionMode.value;

  @override
  final BehaviorSubject<Map<String, T>> _selected;
  @override
  BehaviorSubject<Map<String, T>> get selected => _selected;
  @override
  Map<String, T> get selectedLatest => _selected.value;

  final BehaviorSubject<String> _searchQuery;
  BehaviorSubject<String> get searchQuery => _searchQuery;
  String get searchQueryLatest => _searchQuery.value;

  final List<T> Function(List<T>, String) _filter;
  @override
  final void Function(T) tap;
  @override
  final void Function(T) onLongPress;

  @override
  final T empty;
  @override
  final bool showNull;

  final Widget Function(T,
      {void Function(T) onLongPress,
      void Function(T) onTap,
      Widget trailing,
      Widget subtitle}) itemBuilder;

  DataObjectListOptions({
    Widget Function(T,
            {void Function(T) onLongPress,
            void Function(T) onTap,
            Widget trailing,
            Widget subtitle})
        itemBuilder,
    this.onLongPress,
    this.tap,
    this.empty,
    this.showNull = false,
    bool selectionMode = false,
    Stream<List<T>> itemsStream,
    List<T> items,
    Map<String, T> selected,
    @required Stream<String> searchQuery,
    List<T> Function(List<T>, String) filter,
  })  : assert(itemsStream != null || items != null),
        assert(showNull == false || (showNull == true && empty != null)),
        assert(searchQuery != null),
        _filter = (filter ??
            (o, f) =>
                o.where((e) => filterString(e.name).contains(f)).toList()),
        _searchQuery = BehaviorSubject<String>()..addStream(searchQuery),
        _selected = BehaviorSubject<Map<String, T>>.seeded(selected ?? {}),
        _selectionMode = BehaviorSubject<bool>.seeded(selectionMode),
        originalObjectsData = itemsStream != null
            ? (BehaviorSubject<List<T>>()..addStream(itemsStream))
            : BehaviorSubject<List<T>>.seeded(items),
        itemBuilder = itemBuilder ??
            ((i,
                    {void Function(T) onLongPress,
                    void Function(T) onTap,
                    Widget trailing,
                    Widget subtitle}) =>
                DataObjectWidget<T>(i,
                    subtitle: subtitle,
                    onLongPress:
                        onLongPress != null ? () => onLongPress(i) : null,
                    onTap: onTap != null ? () => onTap(i) : null,
                    trailing: trailing)) {
    _objectsData = (showNull
        ? BehaviorSubject<List<T>>.seeded([empty])
        : BehaviorSubject<List<T>>())
      ..addStream(Rx.combineLatest2<String, List<T>, List<T>>(
          _searchQuery,
          originalObjectsData,
          (search, items) =>
              search.isNotEmpty ? _filter(items, search) : items));
  }

  @override
  void selectAll() {
    if (!_selectionMode.value) _selectionMode.add(true);
    _selected.add({for (var item in items ?? []) item.id: item});
  }

  @override
  void selectNone() {
    if (!_selectionMode.value) _selectionMode.add(true);
    _selected.add({});
  }

  @override
  void toggleSelected(T item) {
    if (_selected.value.containsKey(item.id)) {
      deselect(item);
    } else {
      select(item);
    }
  }

  @override
  void select(T item) {
    assert(!_selected.value.containsKey(item.id));
    _selected.add({..._selected.value, item.id: item});
  }

  @override
  void deselect(T item) {
    assert(_selected.value.containsKey(item.id));
    _selected.add(_selected.value..remove(item.id));
  }
}

String filterString(String s) => s
    .toLowerCase()
    .replaceAll(
        RegExp(
          r'[أإآ]',
        ),
        'ا')
    .replaceAll('ى', 'ي');
