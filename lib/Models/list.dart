import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:churchdata/models/invitation.dart';
import 'package:churchdata/models/list_options.dart';
import 'package:churchdata/models/models.dart';
import 'package:churchdata/models/super_classes.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/helpers.dart';

export 'package:churchdata/models/order_options.dart';
export 'package:tuple/tuple.dart';

///Constructs a [DataObject] [ListView]
///
///You must provide [ListOptions<T>] in the parameter
///or use [Provider<ListOptions<T>>] above this widget
class DataObjectList<T extends DataObject> extends StatefulWidget {
  final DataObjectListOptions<T> options;

  DataObjectList({Key key, this.options}) : super(key: key);

  @override
  _ListState<T> createState() => _ListState<T>();
}

class _ListState<T extends DataObject> extends State<DataObjectList<T>>
    with AutomaticKeepAliveClientMixin<DataObjectList<T>> {
  bool _builtOnce = false;
  DataObjectListOptions<T> _listOptions;

  @override
  bool get wantKeepAlive => _builtOnce && ModalRoute.of(context).isCurrent;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _builtOnce = true;
    updateKeepAlive();

    return StreamBuilder<List<T>>(
      stream: _listOptions.objectsData,
      builder: (context, stream) {
        if (stream.hasError) return Center(child: ErrorWidget(stream.error));
        if (!stream.hasData)
          return const Center(child: CircularProgressIndicator());

        final List<T> _data = stream.data;
        if (_data.isEmpty)
          return Center(child: Text('لا يوجد ${_getPluralStringType()}'));

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 6),
          addAutomaticKeepAlives: _data.length < 500,
          cacheExtent: 200,
          itemCount: _data.length + 1,
          itemBuilder: (context, i) {
            if (i == _data.length)
              return Container(height: MediaQuery.of(context).size.height / 19);

            final T current = _data[i];
            return _listOptions.itemBuilder(
              current,
              onLongPress: _listOptions.onLongPress ?? _defaultLongPress,
              onTap: (T current) {
                if (!_listOptions.selectionModeLatest) {
                  _listOptions.tap == null
                      ? dataObjectTap(current, context)
                      : _listOptions.tap(current);
                } else {
                  _listOptions.toggleSelected(current);
                }
              },
              trailing: StreamBuilder<Map<String, T>>(
                stream: Rx.combineLatest2(_listOptions.selected,
                    _listOptions.selectionMode, (a, b) => b ? a : null),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Checkbox(
                      value: snapshot.data.containsKey(current.id),
                      onChanged: (v) {
                        if (v) {
                          _listOptions.select(current);
                        } else {
                          _listOptions.deselect(current);
                        }
                      },
                    );
                  }
                  return Container(width: 1, height: 1);
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _listOptions = widget.options ?? context.read<DataObjectListOptions<T>>();
  }

  void _defaultLongPress(T current) async {
    _listOptions.selectionMode.add(!_listOptions.selectionModeLatest);

    if (!_listOptions.selectionModeLatest) {
      if (_listOptions.selectedLatest.isNotEmpty) {
        if (T == Person) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              content: Text('اختر أمرًا:'),
              actions: <Widget>[
                TextButton.icon(
                  icon: Icon(Icons.sms),
                  onPressed: () {
                    Navigator.of(context).pop();
                    List<Person> people = _listOptions.selectedLatest.values
                        .cast<Person>()
                        .toList()
                          ..removeWhere((p) =>
                              p.phone == '' ||
                              p.phone == 'null' ||
                              p.phone == null);
                    if (people.isNotEmpty)
                      launch(
                        'sms:' +
                            people
                                .map(
                                  (f) => getPhone(f.phone),
                                )
                                .toList()
                                .cast<String>()
                                .join(','),
                      );
                  },
                  label: Text('ارسال رسالة جماعية'),
                ),
                TextButton.icon(
                  icon: Icon(Icons.share),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await Share.share(
                      (await Future.wait(
                        _listOptions.selectedLatest.values.cast<Person>().map(
                              (f) async => f.name + ': ' + await sharePerson(f),
                            ),
                      ))
                          .join('\n'),
                    );
                  },
                  label: Text('مشاركة القائمة'),
                ),
                TextButton.icon(
                  icon: ImageIcon(AssetImage('assets/whatsapp.png')),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    var con = TextEditingController();
                    String msg = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        actions: [
                          TextButton.icon(
                            icon: Icon(Icons.send),
                            label: Text('ارسال'),
                            onPressed: () {
                              Navigator.pop(context, con.text);
                            },
                          ),
                        ],
                        content: TextFormField(
                          controller: con,
                          maxLines: null,
                          decoration: InputDecoration(
                            labelText: 'اكتب رسالة',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor),
                            ),
                          ),
                        ),
                      ),
                    );
                    msg = Uri.encodeComponent(msg);
                    if (msg != null) {
                      for (Person person in _listOptions.selectedLatest.values
                          .cast<Person>()) {
                        String phone = getPhone(person.phone);
                        await launch('https://wa.me/$phone?text=$msg');
                      }
                    }
                  },
                  label: Text('ارسال رسالة واتساب للكل'),
                ),
                TextButton.icon(
                  icon: Icon(Icons.person_add),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    if ((await Permission.contacts.request()).isGranted) {
                      for (Person item in _listOptions.selectedLatest.values
                          .cast<Person>()) {
                        try {
                          final c = Contact()
                            ..name.first = item.name
                            ..phones = [Phone(item.phone)];
                          await c.insert();
                        } catch (err, stkTrace) {
                          await FirebaseCrashlytics.instance.setCustomKey(
                              'LastErrorIn',
                              'InnerPersonListState.build.addToContacts.tap');
                          await FirebaseCrashlytics.instance
                              .recordError(err, stkTrace);
                        }
                      }
                    }
                  },
                  label: Text('اضافة إلى جهات الاتصال بالهاتف'),
                ),
              ],
            ),
          );
        } else
          await Share.share(
            (await Future.wait(_listOptions.selectedLatest.values
                    .map((f) async => f.name + ': ' + await shareDataObject(f))
                    .toList()))
                .join('\n'),
          );
      }
      _listOptions.selected.add({});
    } else {
      _listOptions.select(current);
    }
  }

  String _getPluralStringType() {
    if (T == Area) return 'مناطق';
    if (T == Street) return 'شوارع';
    if (T == Family) return 'عائلات';
    if (T == Person) return 'أشخاص';
    if (T == Invitation) return 'دعوات';
    return 'عناصر';
  }
}
