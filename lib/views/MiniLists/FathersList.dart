import 'dart:async';

import 'package:churchdata/Models/MiniModels.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FathersEditList extends StatefulWidget {
  final Future<QuerySnapshot> list;

  final Function(Father) tap;
  FathersEditList({this.list, this.tap});

  @override
  _FathersEditListState createState() => _FathersEditListState();
}

class FathersList extends StatefulWidget {
  final Future<Stream<QuerySnapshot>> list;

  final Function(List<Father>) finished;
  final Stream<Father> original;
  FathersList({this.list, this.finished, this.original});

  @override
  _FathersListState createState() => _FathersListState();
}

class InnerListState extends State<_InnerFathersList> {
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
              builder: (context, fathers) {
                if (!fathers.hasData) return CircularProgressIndicator();
                return ListView.builder(
                    itemCount: fathers.data.size,
                    itemBuilder: (context, i) {
                      Father current = Father.fromDoc(fathers.data.docs[i]);
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
                                subtitle: FutureBuilder(
                                    future: current.getChurchName(),
                                    builder: (con, name) {
                                      return name.hasData
                                          ? Text(name.data)
                                          : LinearProgressIndicator();
                                    }),
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

class _FathersEditListState extends State<FathersEditList> {
  String filter = '';
  @override
  Widget build(BuildContext c) {
    return FutureBuilder(
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
                        Father current = Father.fromDoc(data.data.docs[i]);
                        return current.name.contains(filter)
                            ? Card(
                                child: ListTile(
                                  onTap: () => widget.tap(current),
                                  title: Text(current.name),
                                  subtitle: FutureBuilder(
                                      future: current.getChurchName(),
                                      builder: (con, name) {
                                        return name.hasData
                                            ? Text(name.data)
                                            : LinearProgressIndicator();
                                      }),
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

class _FathersListState extends State<FathersList> {
  List<Father> result;

  @override
  Widget build(BuildContext c) {
    return FutureBuilder<Stream<QuerySnapshot>>(
        future: widget.list,
        builder: (c, o) {
          if (o.hasData) {
            return StreamBuilder<Father>(
                stream: widget.original,
                builder: (con, data) {
                  if (result == null && data.hasData) {
                    result = [data.data];
                  } else if (data.hasData) {
                    result.add(data.data);
                  } else {
                    result = [];
                  }
                  return _InnerFathersList(
                      o.data, result, widget.list, widget.finished);
                });
          } else {
            return Container();
          }
        });
  }
}

class _InnerFathersList extends StatefulWidget {
  final Stream<QuerySnapshot> data;
  final List<Father> result;
  final Function(List<Father>) finished;
  final Future<Stream<QuerySnapshot>> list;
  _InnerFathersList(this.data, this.result, this.list, this.finished);
  @override
  State<StatefulWidget> createState() => InnerListState();
}
