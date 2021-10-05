import 'dart:async';

import 'package:churchdata/models/data_object_widget.dart';
import 'package:churchdata/models/super_classes.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

abstract class BaseListController<L, U> {
  final BehaviorSubject<L> _objectsData;
  ValueStream<L> get objectsData => _objectsData.stream;
  L? get items => _objectsData.valueOrNull;

  StreamSubscription<L>? _objectsDataListener;

  final BehaviorSubject<bool> _selectionMode;
  BehaviorSubject<bool> get selectionMode => _selectionMode;
  bool? get selectionModeLatest => _selectionMode.valueOrNull;

  final BehaviorSubject<Map<String, U>?> _selected;
  ValueStream<Map<String, U>?> get selected => _selected.stream;
  Map<String, U>? get selectedLatest => _selected.valueOrNull;

  final BehaviorSubject<String> _searchQuery;
  BehaviorSubject<String> get searchQuery => _searchQuery;
  String? get searchQueryLatest => _searchQuery.valueOrNull;

  StreamSubscription<String>? _searchQueryListener;

  final void Function(U)? tap;
  final void Function(U)? onLongPress;

  final U? empty;
  final bool showNull;

  void selectAll();
  void selectNone() {
    if (!_selectionMode.value) _selectionMode.add(true);
    _selected.add({});
  }

  void toggleSelected(U item);

  void select(U item);

  void deselect(U item);

  BaseListController({
    this.onLongPress,
    this.tap,
    this.empty,
    this.showNull = false,
    bool selectionMode = false,
    Stream<L>? itemsStream,
    L? items,
    Map<String, U>? selected,
    Stream<String>? searchQuery,
  })  : assert(itemsStream != null || items != null),
        assert(showNull == false || (showNull == true && empty != null)),
        _selectionMode = BehaviorSubject<bool>.seeded(selectionMode),
        _selected = BehaviorSubject<Map<String, U>>.seeded(selected ?? {}),
        _searchQuery = searchQuery == null
            ? BehaviorSubject<String>.seeded('')
            : BehaviorSubject<String>(),
        _objectsData = itemsStream != null
            ? BehaviorSubject<L>()
            : BehaviorSubject<L>.seeded(items!) {
    //
    _searchQueryListener =
        searchQuery?.listen(_searchQuery.add, onError: _searchQuery.addError);

    _objectsDataListener =
        itemsStream?.listen(_objectsData.add, onError: _objectsData.addError);
  }

  Future<void> dispose() async {
    await _objectsDataListener?.cancel();
    if (!_objectsData.isClosed) await _objectsData.close();

    if (!_selected.isClosed) await _selected.close();
    if (!_selectionMode.isClosed) await _selectionMode.close();

    await _searchQueryListener?.cancel();
    if (!_searchQuery.isClosed) await _searchQuery.close();
  }
}

class DataObjectListController<T extends DataObject>
    implements BaseListController<List<T>, T> {
  @override
  late final BehaviorSubject<List<T>> _objectsData;
  @override
  ValueStream<List<T>> get objectsData => _objectsData.stream;
  @override
  List<T>? get items => objectsData.valueOrNull;

  @override
  StreamSubscription<List<T>>? _objectsDataListener;

  final BehaviorSubject<Map<String, T>> _originalObjectsData;
  ValueStream<Map<String, T>> get originalObjectsData =>
      _originalObjectsData.stream;
  Map<String, T>? get originalObjectsDataLatest =>
      originalObjectsData.valueOrNull;

  StreamSubscription<Object>? _originalObjectsDataListener;

  @override
  final BehaviorSubject<bool> _selectionMode;
  @override
  BehaviorSubject<bool> get selectionMode => _selectionMode;
  @override
  bool? get selectionModeLatest => _selectionMode.valueOrNull;

  @override
  final BehaviorSubject<Map<String, T>> _selected;
  @override
  ValueStream<Map<String, T>> get selected => _selected.stream;
  @override
  Map<String, T>? get selectedLatest => _selected.valueOrNull;

  @override
  final BehaviorSubject<String> _searchQuery;
  @override
  BehaviorSubject<String> get searchQuery => _searchQuery;
  @override
  String? get searchQueryLatest => _searchQuery.valueOrNull;

  @override
  StreamSubscription<String>? _searchQueryListener;

  final List<T> Function(List<T>, String) _filter;
  @override
  final void Function(T)? tap;
  @override
  final void Function(T)? onLongPress;

  @override
  final T? empty;
  @override
  final bool showNull;

  final Widget Function(T, void Function(T)? onLongPress,
      void Function(T)? onTap, Widget? trailing, Widget? subtitle) itemBuilder;

  late final Widget Function(T,
      {void Function(T)? onLongPress,
      void Function(T)? onTap,
      Widget? trailing,
      Widget? subtitle}) buildItem;

  DataObjectListController({
    Widget Function(T, void Function(T)? onLongPress, void Function(T)? onTap,
            Widget? trailing, Widget? subtitle)?
        itemBuilder,
    this.onLongPress,
    this.tap,
    this.empty,
    this.showNull = false,
    bool selectionMode = false,
    Stream<List<T>>? itemsStream,
    List<T>? items,
    Map<String, T>? selected,
    List<T> Function(List<T>, String)? filter,
    Stream<String>? searchQuery,
  })  : assert(itemsStream != null || items != null),
        assert(showNull == false || (showNull == true && empty != null)),
        _filter = (filter ??
            ((o, f) => o
                .where((e) => filterString(e.name).contains(filterString(f)))
                .toList())),
        _searchQuery = searchQuery == null
            ? BehaviorSubject<String>.seeded('')
            : BehaviorSubject<String>(),
        _selected = BehaviorSubject<Map<String, T>>.seeded(selected ?? {}),
        _selectionMode = BehaviorSubject<bool>.seeded(selectionMode),
        _originalObjectsData = itemsStream != null
            ? BehaviorSubject<Map<String, T>>()
            : BehaviorSubject<Map<String, T>>.seeded(
                {for (final o in items!) o.id: o}),
        _objectsData = showNull
            ? BehaviorSubject<List<T>>.seeded([empty!])
            : BehaviorSubject<List<T>>(),
        itemBuilder = (itemBuilder ??
            (i, void Function(T)? onLongPress, void Function(T)? onTap,
                    Widget? trailing, Widget? subtitle) =>
                DataObjectWidget<T>(i,
                    subtitle: subtitle,
                    onLongPress:
                        onLongPress != null ? () => onLongPress(i) : null,
                    onTap: onTap != null ? () => onTap(i) : null,
                    trailing: trailing)) {
    //
    _searchQueryListener =
        searchQuery?.listen(_searchQuery.add, onError: _searchQuery.addError);

    buildItem = (i, {onLongPress, onTap, trailing, subtitle}) {
      return this.itemBuilder(i, onLongPress, onTap, trailing, subtitle);
    };

    _originalObjectsDataListener = itemsStream
        ?.listen((l) => _originalObjectsData.add({for (final o in l) o.id: o}));

    _objectsDataListener = Rx.combineLatest2<String, Map<String, T>, List<T>>(
      _searchQuery,
      _originalObjectsData,
      (search, items) => search.isNotEmpty
          ? _filter(items.values.toList(), search)
          : items.values.toList(),
    ).listen(_objectsData.add, onError: _objectsData.addError);
  }

  @override
  void selectAll() {
    if (!_selectionMode.value) _selectionMode.add(true);
    _selected.add({for (var item in _objectsData.value) item.id: item});
  }

  @override
  void selectNone([bool enterSelectionMode = true]) {
    if (enterSelectionMode && !_selectionMode.value) _selectionMode.add(true);
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

  @override
  Future<void> dispose() async {
    await _objectsDataListener?.cancel();
    if (!_objectsData.isClosed) await _objectsData.close();

    await _originalObjectsDataListener?.cancel();
    if (!_originalObjectsData.isClosed) await _originalObjectsData.close();

    if (!_selected.isClosed) await _selected.close();
    if (!_selectionMode.isClosed) await _selectionMode.close();

    await _searchQueryListener?.cancel();
    if (!_searchQuery.isClosed) await _searchQuery.close();
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
