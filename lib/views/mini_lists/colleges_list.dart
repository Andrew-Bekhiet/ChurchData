import 'dart:async';

import 'package:churchdata/models/mini_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CollegesEditList extends StatefulWidget {
  final Future<QuerySnapshot> list;

  final Function(College) tap;
  CollegesEditList({this.list, this.tap});

  @override
  _CollegesEditListState createState() => _CollegesEditListState();
}

class _CollegesEditListState extends State<CollegesEditList> {
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
                onRefresh: () {
                  setState(() {});
                  return widget.list;
                },
                child: ListView.builder(
                  itemCount: data.data.size,
                  itemBuilder: (context, i) {
                    College current = College.fromDoc(data.data.docs[i]);
                    return current.name.contains(filter)
                        ? Card(
                            child: ListTile(
                              onTap: () => widget.tap(current),
                              title: Text(current.name),
                            ),
                          )
                        : Container();
                  },
                ),
              ),
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
