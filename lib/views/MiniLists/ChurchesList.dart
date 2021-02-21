import 'dart:async';

import 'package:churchdata/Models/MiniModels.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChurchesEditList extends StatefulWidget {
  final Future<QuerySnapshot> list;

  final Function(Church) tap;
  ChurchesEditList({this.list, this.tap});

  @override
  _ChurchesEditListState createState() => _ChurchesEditListState();
}

class ChurchesList extends StatefulWidget {
  final Future<Stream<QuerySnapshot>> list;

  final Function(List<Church>) finished;
  final Stream<Church> original;
  ChurchesList({this.list, this.finished, this.original});

  @override
  _ChurchesListState createState() => _ChurchesListState();
}

class InnerListState extends State<_InnerChurchsList> {
  String filter = '';
  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      TextField(
          decoration: InputDecoration(hintText: 'بحث...'),
          onChanged: (text) {
            setState(() {
              filter = text;
            });
          }),
      Expanded(
        child: RefreshIndicator(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.data,
              builder: (context, churchs) {
                if (!churchs.hasData) return CircularProgressIndicator();
                return ListView.builder(
                    itemCount: churchs.data.size,
                    itemBuilder: (context, i) {
                      Church current = Church.fromDoc(churchs.data.docs[i]);
                      return current.name.contains(filter)
                          ? Card(
                              child: ListTile(
                                onTap: () {
                                  widget.result
                                          .map((f) => f.id)
                                          .contains(current.id)
                                      ? widget.result.removeWhere(
                                          (x) => x.id == current.id)
                                      : widget.result.add(current);
                                  setState(() {});
                                },
                                title: Text(current.name),
                                leading: Checkbox(
                                  value: widget.result
                                      .map((f) => f.id)
                                      .contains(current.id),
                                  onChanged: (x) {
                                    !x
                                        ? widget.result.removeWhere(
                                            (x) => x.id == current.id)
                                        : widget.result.add(current);
                                    setState(() {});
                                  },
                                ),
                              ),
                            )
                          : Container();
                    });
              },
            ),
            onRefresh: () {
              setState(() {});
              return null;
            }),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          TextButton(
            onPressed: () => widget.finished(widget.result),
            child: Text('تم'),
          ),
          TextButton(
            onPressed: () => widget.finished(null),
            child: Text('إلغاء الأمر'),
          ),
        ],
      )
    ]);
  }
}

class _ChurchesEditListState extends State<ChurchesEditList> {
  String filter = '';
  @override
  Widget build(BuildContext c) {
    return FutureBuilder<QuerySnapshot>(
      future: widget.list,
      builder: (con, data) {
        if (data.hasData) {
          return Column(children: <Widget>[
            TextField(
                decoration: InputDecoration(hintText: 'بحث...'),
                onChanged: (text) {
                  setState(() {
                    filter = text;
                  });
                }),
            Expanded(
              child: RefreshIndicator(
                  child: ListView.builder(
                      itemCount: data.data.size,
                      itemBuilder: (context, i) {
                        Church current = Church.fromDoc(data.data.docs[i]);
                        return current.name.contains(filter)
                            ? Card(
                                child: ListTile(
                                  onTap: () => widget.tap(current),
                                  title: Text(current.name),
                                  subtitle: Text(current.address),
                                ),
                              )
                            : Container();
                      }),
                  onRefresh: () {
                    setState(() {});
                    return widget.list;
                  }),
            ),
          ]);
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

class _ChurchesListState extends State<ChurchesList> {
  List<Church> result;

  @override
  Widget build(BuildContext c) {
    return FutureBuilder<Stream<QuerySnapshot>>(
        future: widget.list,
        builder: (c, o) {
          if (o.hasData) {
            return StreamBuilder<Church>(
                stream: widget.original,
                builder: (con, data) {
                  if (result == null && data.hasData) {
                    result = [data.data];
                  } else if (data.hasData) {
                    result.add(data.data);
                  } else {
                    result = [];
                  }
                  return _InnerChurchsList(
                      o.data, result, widget.list, widget.finished);
                });
          } else {
            return Container();
          }
        });
  }
}

class _InnerChurchsList extends StatefulWidget {
  final Stream<QuerySnapshot> data;
  final List<Church> result;
  final Function(List<Church>) finished;
  final Future<Stream<QuerySnapshot>> list;
  _InnerChurchsList(this.data, this.result, this.list, this.finished);
  @override
  State<StatefulWidget> createState() => InnerListState();
}
