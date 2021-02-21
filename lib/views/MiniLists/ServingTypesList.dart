import 'dart:async';

import 'package:churchdata/Models/MiniModels.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ServingTypesEditList extends StatefulWidget {
  final Future<QuerySnapshot> list;

  final Function(ServingType) tap;
  ServingTypesEditList({this.list, this.tap});

  @override
  _ServingTypesEditListState createState() => _ServingTypesEditListState();
}

class _ServingTypesEditListState extends State<ServingTypesEditList> {
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
                        ServingType current =
                            ServingType.fromDoc(data.data.docs[i]);
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
