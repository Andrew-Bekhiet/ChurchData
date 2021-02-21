import 'dart:async';

import 'package:churchdata/Models/MiniModels.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InnerListState extends State<_InnerJobsList> {
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
              builder: (context, jobs) {
                if (!jobs.hasData) return CircularProgressIndicator();
                return ListView.builder(
                    itemCount: jobs.data.size,
                    itemBuilder: (context, i) {
                      Job current = Job.fromDoc(jobs.data.docs[i]);
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

class JobsEditList extends StatefulWidget {
  final Future<QuerySnapshot> list;

  final Function(Job) tap;
  JobsEditList({this.list, this.tap});

  @override
  _JobsEditListState createState() => _JobsEditListState();
}

class JobsList extends StatefulWidget {
  final Future<Stream<QuerySnapshot>> list;

  final Function(List<Job>) finished;
  final Stream<Job> original;
  JobsList({this.list, this.finished, this.original});

  @override
  _JobsListState createState() => _JobsListState();
}

class _InnerJobsList extends StatefulWidget {
  final Stream<QuerySnapshot> data;
  final List<Job> result;
  final Function(List<Job>) finished;
  final Future<Stream<QuerySnapshot>> list;
  _InnerJobsList(this.data, this.result, this.list, this.finished);
  @override
  State<StatefulWidget> createState() => InnerListState();
}

class _JobsEditListState extends State<JobsEditList> {
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
                      itemCount: data.data.docs.length,
                      itemBuilder: (context, i) {
                        Job current = Job.fromDoc(data.data.docs[i]);
                        return current.name.contains(filter)
                            ? Card(
                                child: ListTile(
                                  onTap: () => widget.tap(current),
                                  title: Text(current.name),
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

class _JobsListState extends State<JobsList> {
  List<Job> result;

  @override
  Widget build(BuildContext c) {
    return FutureBuilder<Stream<QuerySnapshot>>(
        future: widget.list,
        builder: (c, o) {
          if (o.hasData) {
            return StreamBuilder<Job>(
                stream: widget.original,
                builder: (con, data) {
                  if (result == null && data.hasData) {
                    result = [data.data];
                  } else if (data.hasData) {
                    result.add(data.data);
                  } else {
                    result = [];
                  }
                  return _InnerJobsList(
                      o.data, result, widget.list, widget.finished);
                });
          } else {
            return Container();
          }
        });
  }
}
