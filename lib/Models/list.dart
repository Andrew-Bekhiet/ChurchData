import 'dart:async';
import 'dart:math' as math;

import 'package:churchdata/models/area.dart';
import 'package:churchdata/models/street.dart';
import 'package:churchdata/models/family.dart';
import 'package:churchdata/models/person.dart';
import 'package:churchdata/models/list_options.dart';
import 'package:churchdata/models/order_options.dart';
import 'package:churchdata/models/search_string.dart';
import 'package:churchdata/models/super_classes.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:churchdata/models/data_dialog.dart';
import 'package:churchdata/models/data_object_widget.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

export 'package:churchdata/models/list_options.dart' show ListOptions;
export 'package:churchdata/models/order_options.dart';
export 'package:churchdata/models/search_string.dart';
export 'package:tuple/tuple.dart';

class DataObjectList<T extends DataObject> extends StatefulWidget {
  final ListOptions<T> options;

  DataObjectList({Key key, @required this.options}) : super(key: key);

  @override
  _ListState<T> createState() => _ListState<T>();
}

class _InnerList<T extends DataObject> extends StatefulWidget {
  _InnerList({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _InnerListState<T>();
}

class _InnerListState<T extends DataObject> extends State<_InnerList<T>> {
  List<T> _documentsData;
  String _oldFilter = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<ListOptions<T>>(
      builder: (context, options, child) {
        if (_oldFilter == '' && options.items.length != _documentsData.length)
          _requery(false);
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 6),
          addAutomaticKeepAlives: (_documentsData?.length ?? 0) < 300,
          cacheExtent: 200,
          itemCount: (_documentsData?.length ?? 0) + 1,
          itemBuilder: (context, i) {
            if (i == _documentsData.length)
              return Container(height: MediaQuery.of(context).size.height / 19);
            var current = _documentsData[i];
            return options.itemBuilder(
              current,
              onLongPress: options.onLongPress ??
                  () async {
                    options.selectionMode = !options.selectionMode;

                    if (!options.selectionMode) {
                      if (options.selected.isNotEmpty) {
                        if (T == Person) {
                          await showDialog(
                            context: context,
                            builder: (context) => DataDialog(
                              content: Text('اختر أمرًا:'),
                              actions: <Widget>[
                                TextButton.icon(
                                  icon: Icon(Icons.sms),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    List<Person> people = options.selected
                                        .cast<Person>()
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
                                      (await Future.wait(options.selected
                                              .cast<Person>()
                                              .map(
                                                (f) => sharePerson(f),
                                              )))
                                          .join('\n'),
                                    );
                                  },
                                  label: Text('مشاركة القائمة'),
                                ),
                                TextButton.icon(
                                  icon: Icon(Icons.message),
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
                                                  color: Theme.of(context)
                                                      .primaryColor),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                    msg = Uri.encodeComponent(msg);
                                    if (msg != null) {
                                      for (Person person
                                          in options.selected.cast<Person>()) {
                                        String phone = getPhone(person.phone);
                                        await launch(
                                            'https://wa.me/$phone?text=$msg');
                                      }
                                    }
                                  },
                                  label: Text('ارسال رسالة واتساب للكل'),
                                ),
                                TextButton.icon(
                                  icon: Icon(Icons.person_add),
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    if ((await Permission.contacts.request())
                                        .isGranted) {
                                      for (Person item
                                          in options.selected.cast<Person>()) {
                                        try {
                                          final c = Contact()
                                            ..name.first = item.name
                                            ..phones = [Phone(item.phone)];
                                          await c.insert();
                                        } catch (err, stkTrace) {
                                          await FirebaseCrashlytics.instance
                                              .setCustomKey('LastErrorIn',
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
                            (await Future.wait(options.selected
                                    .map((f) => shareDataObject(f))
                                    .toList()))
                                .join('\n'),
                          );
                      }
                      options.selected = [];
                    } else {
                      options.selected.contains(current)
                          ? options.selected.remove(current)
                          : options.selected.add(current);
                    }
                  },
              onTap: () {
                if (!options.selectionMode) {
                  options.tap == null
                      ? dataObjectTap(current, context)
                      : options.tap(current);
                } else if (options.selected.contains(current)) {
                  setState(() {
                    options.selected.remove(current);
                  });
                } else {
                  setState(() {
                    options.selected.add(current);
                  });
                }
              },
              trailing: !options.selectionMode
                  ? (T is Person
                      ? FutureBuilder(
                          future: (current as Person).getLeftWidget(),
                          builder: (context, d) {
                            if (d.hasData) {
                              return d.data;
                            } else {
                              return CircularProgressIndicator();
                            }
                          },
                        )
                      : null)
                  : Checkbox(
                      value: options.selected.contains(current),
                      onChanged: (v) {
                        setState(
                          () {
                            if (v) {
                              options.selected.add(current);
                            } else {
                              options.selected.remove(current);
                            }
                          },
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    context.read<SearchString>().addListener(_requery);
    _requery();
  }

  void _requery([bool rebuild = true]) {
    if (!mounted) return;
    String filter = context.read<SearchString>().value;
    if (filter.isNotEmpty) {
      if (_oldFilter.length < filter.length &&
          filter.startsWith(_oldFilter) &&
          _documentsData != null)
        _documentsData = _documentsData
            .where((d) => d.name
                .toLowerCase()
                .replaceAll(
                    RegExp(
                      r'[أإآ]',
                    ),
                    'ا')
                .replaceAll(
                    RegExp(
                      r'[ى]',
                    ),
                    'ي')
                .contains(filter))
            .toList();
      else
        _documentsData = context
            .read<ListOptions<T>>()
            .items
            .where((d) => d.name
                .toLowerCase()
                .replaceAll(
                    RegExp(
                      r'[أإآ]',
                    ),
                    'ا')
                .replaceAll(
                    RegExp(
                      r'[ى]',
                    ),
                    'ي')
                .contains(filter))
            .toList();
    } else
      _documentsData = context.read<ListOptions<T>>().items;
    _oldFilter = filter;
    if (rebuild) setState(() {});
  }
}

class _ListState<T extends DataObject> extends State<DataObjectList<T>>
    with AutomaticKeepAliveClientMixin<DataObjectList<T>> {
  @override
  bool get wantKeepAlive => _builtOnce && ModalRoute.of(context).isCurrent;

  bool _builtOnce = false;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    _builtOnce = true;
    updateKeepAlive();

    return StreamBuilder<List<T>>(
      stream: widget.options.documentsData,
      builder: (context, stream) {
        if (stream.hasError) return Center(child: ErrorWidget(stream.error));
        if (!stream.hasData) return Center(child: CircularProgressIndicator());
        return ChangeNotifierProxyProvider0<ListOptions<T>>(
          create: (_) => ListOptions<T>(
              tap: widget.options.tap,
              empty: widget.options.empty,
              selected: widget.options.selected,
              showNull: widget.options.showNull,
              items: stream.data,
              selectionMode: widget.options.selectionMode),
          update: (_, old) => old..items = stream.data,
          builder: (context, _) => Selector<ListOptions<T>, List<T>>(
            selector: (_, op) => op.items,
            builder: (context, docs, child) {
              return Scaffold(
                primary: false,
                extendBody: true,
                body: child == null
                    ? _InnerList<T>()
                    : Column(
                        children: [
                          child,
                          Flexible(child: _InnerList<T>()),
                        ],
                      ),
                floatingActionButtonLocation: widget.options.hasNotch
                    ? FloatingActionButtonLocation.endDocked
                    : null,
                floatingActionButton: widget.options.floatingActionButton,
                bottomNavigationBar: BottomAppBar(
                  color: Theme.of(context).primaryColor,
                  shape: widget.options.hasNotch
                      ? widget.options.doubleActionButton
                          ? const DoubleCircularNotchedButton()
                          : const CircularNotchedRectangle()
                      : null,
                  child: Text(_getCountString(docs),
                      textAlign: TextAlign.center,
                      strutStyle: StrutStyle(
                          height: MediaQuery.of(context).size.height /
                              (!kIsWeb ? 285.71 : 100)),
                      style: Theme.of(context).primaryTextTheme.bodyText1),
                ),
              );
            },
            child: widget.options.showNull
                ? DataObjectWidget<T>(
                    widget.options.empty,
                    onTap: () => widget.options.tap(widget.options.empty),
                  )
                : null,
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    context.read<OrderOptions>().addListener(() {
      if (mounted) setState(() {});
    });
  }

  String _getCountString(List<T> list) {
    if (widget.options.getStringCount != null)
      widget.options.getStringCount(list);
    if (T == Area) return (list?.length ?? 0).toString() + ' منطقة';
    if (T == Street) return (list?.length ?? 0).toString() + ' شارع';
    if (T == Family) return (list?.length ?? 0).toString() + ' عائلة';
    if (T == Person) return (list?.length ?? 0).toString() + ' شخص';
    throw UnimplementedError();
  }
}

class DoubleCircularNotchedButton extends NotchedShape {
  const DoubleCircularNotchedButton();
  @override
  Path getOuterPath(Rect host, Rect guest) {
    if (guest == null || !host.overlaps(guest)) return Path()..addRect(host);

    final double notchRadius = guest.height / 2.0;

    const double s1 = 15.0;
    const double s2 = 1.0;

    final double r = notchRadius;
    final double a = -1.0 * r - s2;
    final double b = host.top - 0;

    final double n2 = math.sqrt(b * b * r * r * (a * a + b * b - r * r));
    final double p2xA = ((a * r * r) - n2) / (a * a + b * b);
    final double p2xB = ((a * r * r) + n2) / (a * a + b * b);
    final double p2yA = math.sqrt(r * r - p2xA * p2xA);
    final double p2yB = math.sqrt(r * r - p2xB * p2xB);

    ///Cut-out 1
    final List<Offset> px = List<Offset>.generate(6, (_) => Offset(0, 0));

    px[0] = Offset(a - s1, b);
    px[1] = Offset(a, b);
    final double cmpx = b < 0 ? -1.0 : 1.0;
    px[2] = cmpx * p2yA > cmpx * p2yB ? Offset(p2xA, p2yA) : Offset(p2xB, p2yB);

    px[3] = Offset(-1.0 * px[2].dx, px[2].dy);
    px[4] = Offset(-1.0 * px[1].dx, px[1].dy);
    px[5] = Offset(-1.0 * px[0].dx, px[0].dy);

    for (int i = 0; i < px.length; i += 1)
      px[i] += Offset(0 + (notchRadius + 12), 0); //Cut-out 1 positions

    ///Cut-out 2
    final List<Offset> py = List<Offset>.generate(6, (_) => Offset(0, 0));

    py[0] = Offset(a - s1, b);
    py[1] = Offset(a, b);
    final double cmpy = b < 0 ? -1.0 : 1.0;
    py[2] = cmpy * p2yA > cmpy * p2yB ? Offset(p2xA, p2yA) : Offset(p2xB, p2yB);

    py[3] = Offset(-1.0 * py[2].dx, py[2].dy);
    py[4] = Offset(-1.0 * py[1].dx, py[1].dy);
    py[5] = Offset(-1.0 * py[0].dx, py[0].dy);

    for (int i = 0; i < py.length; i += 1)
      py[i] += Offset(host.width - (notchRadius + 12), 0); //Cut-out 2 positions

    return Path()
      ..moveTo(host.left, host.top)
      ..lineTo(px[0].dx, px[0].dy)
      ..quadraticBezierTo(px[1].dx, px[1].dy, px[2].dx, px[2].dy)
      ..arcToPoint(
        px[3],
        radius: Radius.circular(notchRadius),
        clockwise: false,
      )
      ..quadraticBezierTo(px[4].dx, px[4].dy, px[5].dx, px[5].dy)
      ..lineTo(py[0].dx, py[0].dy)
      ..quadraticBezierTo(py[1].dx, py[1].dy, py[2].dx, py[2].dy)
      ..arcToPoint(
        py[3],
        radius: Radius.circular(notchRadius),
        clockwise: false,
      )
      ..quadraticBezierTo(py[4].dx, py[4].dy, py[5].dx, py[5].dy)
      ..lineTo(host.right, host.top)
      ..lineTo(host.right, host.bottom)
      ..lineTo(host.left, host.bottom)
      ..close();
  }
}