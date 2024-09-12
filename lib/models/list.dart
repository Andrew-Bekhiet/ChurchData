import 'dart:async';

import 'package:churchdata/models/list_controllers.dart';
import 'package:churchdata/models/models.dart';
import 'package:churchdata/models/super_classes.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata_core/churchdata_core.dart' show formatPhone;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:group_list_view/group_list_view.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../utils/helpers.dart';
import 'invitation.dart';

export 'package:churchdata/models/order_options.dart';
export 'package:tuple/tuple.dart';

///Constructs a [DataObject] [ListView]
///
///You must provide [ListOptions<T>] in the parameter
///or use [Provider<ListOptions<T>>] above this widget
class DataObjectList<T extends DataObject> extends StatefulWidget {
  final DataObjectListController<T>? options;
  final bool autoDisposeController;

  const DataObjectList({
    required this.autoDisposeController,
    super.key,
    this.options,
  });

  @override
  _ListState<T> createState() => _ListState<T>();
}

class _ListState<T extends DataObject> extends State<DataObjectList<T>>
    with AutomaticKeepAliveClientMixin<DataObjectList<T>> {
  bool _builtOnce = false;
  late DataObjectListController<T> _listOptions;

  @override
  bool get wantKeepAlive => _builtOnce && ModalRoute.of(context)!.isCurrent;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _builtOnce = true;
    updateKeepAlive();

    return StreamBuilder(
      stream: _listOptions.grouped.switchMap(
        (g) {
          if (g) {
            return _listOptions.objectsData.map((data) {
              if (_listOptions.groupData == null)
                throw Exception('ListController.groupData is null');

              return _listOptions.groupData!(data);
            });
          } else {
            return _listOptions.objectsData;
          }
        },
      ),
      builder: (context, stream) {
        if (stream.hasError) return Center(child: ErrorWidget(stream.error!));
        if (!stream.hasData)
          return const Center(child: CircularProgressIndicator());

        if (stream.data is List<T>) {
          final List<T> _data = stream.data! as List<T>;
          if (_data.isEmpty)
            return Center(child: Text('لا يوجد ${_getPluralStringType()}'));

          return _UngroupedList<T>(data: _data, listController: _listOptions);
        } else if (stream.data is Map<String, List<T>>) {
          final Map<String, List<T>> _data =
              stream.data! as Map<String, List<T>>;
          if (_data.isEmpty)
            return Center(child: Text('لا يوجد ${_getPluralStringType()}'));

          return _GroupedList<T>(
            groupedData: _data,
            listController: _listOptions,
          );
        }
        return const Center(child: Text('لا يمكن عرض البيانات'));
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _listOptions =
        widget.options ?? context.read<DataObjectListController<T>>();
  }

  String _getPluralStringType() {
    if (T == Area) return 'مناطق';
    if (T == Street) return 'شوارع';
    if (T == Family) return 'عائلات';
    if (T == Person) return 'أشخاص';
    if (T == Invitation) return 'دعوات';
    return 'عناصر';
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    if (widget.autoDisposeController) await _listOptions.dispose();
  }
}

class _UngroupedList<T extends DataObject> extends StatelessWidget {
  const _UngroupedList({
    required this.data,
    required this.listController,
    super.key,
  });

  final List<T> data;
  final DataObjectListController<T> listController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      addAutomaticKeepAlives: data.length < 500,
      cacheExtent: 200,
      itemCount: data.length + 1,
      itemBuilder: (context, i) {
        if (i == data.length) return const SizedBox(height: 80);

        final T current = data[i];
        return listController.buildItem(
          current,
          onLongPress: listController.onLongPress ??
              (item) => _defaultLongPress(context, item, listController),
          onTap: (current) {
            if (!listController.selectionMode.value) {
              listController.tap == null
                  ? dataObjectTap(current)
                  : listController.tap!(current);
            } else {
              listController.toggleSelected(current);
            }
          },
          trailing: StreamBuilder<bool?>(
            stream: Rx.combineLatest2<Map<String, T>, bool, bool?>(
              listController.selected,
              listController.selectionMode,
              (a, b) => b ? a.containsKey(current.id) : null,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Checkbox(
                  value: snapshot.data,
                  onChanged: (v) {
                    if (v!) {
                      listController.select(current);
                    } else {
                      listController.deselect(current);
                    }
                  },
                );
              }
              return current is Person
                  ? current.getLeftWidget()
                  : const SizedBox(width: 1, height: 1);
            },
          ),
        );
      },
    );
  }
}

class _GroupedList<O extends DataObject> extends StatelessWidget {
  const _GroupedList({
    required this.groupedData,
    required this.listController,
    super.key,
  });

  final Map<String, List<O>> groupedData;
  final DataObjectListController<O> listController;

  @override
  Widget build(BuildContext context) {
    return GroupListView(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      addAutomaticKeepAlives: groupedData.length < 500,
      sectionsCount: groupedData.length + 1,
      countOfItemInSection: (i) {
        if (i == groupedData.length) return 0;

        return groupedData.values.elementAt(i).length;
      },
      cacheExtent: 200,
      groupHeaderBuilder: (context, i) {
        if (i == groupedData.length) return const SizedBox(height: 80);

        return Card(
          child: ListTile(
            title: Text(groupedData.keys.elementAt(i)),
            onTap: () {
              listController.openedNodes.add({
                ...listController.openedNodes.value,
                groupedData.keys.elementAt(i): !(listController
                        .openedNodes.value[groupedData.keys.elementAt(i)] ??
                    false),
              });
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    listController.openedNodes.add({
                      ...listController.openedNodes.value,
                      groupedData.keys.elementAt(i): !(listController
                              .openedNodes
                              .value[groupedData.keys.elementAt(i)] ??
                          false),
                    });
                  },
                  icon: Icon(
                    listController.openedNodes
                                .value[groupedData.keys.elementAt(i)] ??
                            false
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      itemBuilder: (context, i) {
        final O current = groupedData.values.elementAt(i.section)[i.index];
        return listController.buildItem(
          current,
          onLongPress: listController.onLongPress ??
              (item) => _defaultLongPress(context, item, listController),
          onTap: (current) {
            if (!listController.selectionMode.value) {
              listController.tap == null
                  ? dataObjectTap(current)
                  : listController.tap!(current);
            } else {
              listController.toggleSelected(current);
            }
          },
          trailing: StreamBuilder<bool>(
            stream: Rx.combineLatest2<Map<String, O>, bool, bool>(
              listController.selected,
              listController.selectionMode,
              (a, b) => b ? a.containsKey(current.id) : false,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Checkbox(
                  value: snapshot.data,
                  onChanged: (v) {
                    if (v!) {
                      listController.select(current);
                    } else {
                      listController.deselect(current);
                    }
                  },
                );
              }
              return current is Person
                  ? current.getLeftWidget()
                  : const SizedBox(width: 1, height: 1);
            },
          ),
        );
      },
    );
  }
}

Future<void> _defaultLongPress<T extends DataObject>(
  BuildContext context,
  T current,
  DataObjectListController<T> _listController,
) async {
  final List<T> currentSelected =
      _listController.selected.value.values.toList();

  _listController.selectionMode.add(!_listController.selectionMode.value);

  if (!_listController.selectionMode.value) {
    if (currentSelected.isNotEmpty) {
      if (T == Person) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: const Text('اختر أمرًا:'),
            actions: <Widget>[
              TextButton.icon(
                icon: const Icon(Icons.sms),
                onPressed: () {
                  navigator.currentState!.pop();

                  final List<String> peoplePhones = currentSelected
                      .where(
                        (p) =>
                            p is Person &&
                            p.phone != null &&
                            p.phone!.isNotEmpty,
                      )
                      .map((p) => getPhone((p as Person).phone!))
                      .toList();

                  if (peoplePhones.isNotEmpty)
                    launchUrlString(
                      'sms:' + peoplePhones.join(','),
                    );
                },
                label: const Text('ارسال رسالة جماعية'),
              ),
              TextButton.icon(
                icon: const Icon(Icons.share),
                onPressed: () async {
                  navigator.currentState!.pop();

                  await Share.share(
                    (await Future.wait(
                      currentSelected.cast<Person>().map(
                            (f) async => f.name + ': ' + await sharePerson(f),
                          ),
                    ))
                        .join('\n'),
                  );
                },
                label: const Text('مشاركة القائمة'),
              ),
              TextButton.icon(
                icon: const ImageIcon(AssetImage('assets/whatsapp.png')),
                onPressed: () async {
                  navigator.currentState!.pop();

                  final con = TextEditingController();
                  String? msg = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      actions: [
                        TextButton.icon(
                          icon: const Icon(Icons.send),
                          label: const Text('ارسال'),
                          onPressed: () {
                            navigator.currentState!.pop(con.text);
                          },
                        ),
                      ],
                      content: TextFormField(
                        controller: con,
                        maxLines: null,
                        decoration: const InputDecoration(
                          labelText: 'اكتب رسالة',
                        ),
                      ),
                    ),
                  );

                  if (msg != null) {
                    msg = Uri.encodeComponent(msg);
                    for (final Person person in currentSelected
                        .cast<Person>()
                        .where((p) => p.phone != null && p.phone!.isNotEmpty)) {
                      final String phone = formatPhone(person.phone!);
                      await launchUrlString(
                        'whatsapp://send?phone=+$phone&text=$msg',
                      );
                    }
                  }
                },
                label: const Text('ارسال رسالة واتساب للكل'),
              ),
              TextButton.icon(
                icon: const Icon(Icons.person_add),
                onPressed: () async {
                  navigator.currentState!.pop();
                  if ((await Permission.contacts.request()).isGranted) {
                    for (final Person item in currentSelected
                        .cast<Person>()
                        .where((p) => p.phone != null && p.phone!.isNotEmpty)) {
                      try {
                        final c = Contact(
                          photo: item.hasPhoto
                              ? await item.photoRef.getData(100 * 1024 * 1024)
                              : null,
                          phones: [Phone(item.phone!)],
                        )..name.first = item.name;
                        await c.insert();
                      } catch (err, stkTrace) {
                        await FirebaseCrashlytics.instance.setCustomKey(
                          'LastErrorIn',
                          'InnerPersonListState.build.addToContacts.tap',
                        );
                        await FirebaseCrashlytics.instance
                            .recordError(err, stkTrace);
                      }
                    }
                  }
                },
                label: const Text('اضافة إلى جهات الاتصال بالهاتف'),
              ),
            ],
          ),
        );
      } else
        await Share.share(
          (await Future.wait(
            currentSelected
                .map((f) async => f.name + ': ' + await shareDataObject(f))
                .toList(),
          ))
              .join('\n'),
        );
    }
    _listController.selectNone(false);
  } else {
    _listController.select(current);
  }
}
