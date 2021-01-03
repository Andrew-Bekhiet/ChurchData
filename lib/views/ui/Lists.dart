import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../Models/MiniModels.dart';

export '../../views/utils/List.dart' show DataObjectList;

class TypesList extends StatefulWidget {
  final Future<QuerySnapshot> list;

  final Function(PersonType, BuildContext) tap;
  final bool showNull;
  TypesList({this.list, this.tap, this.showNull = false});

  @override
  _TypesListState createState() => _TypesListState();
}

class _TypesListState extends State<TypesList> {
  String filter = '';
  @override
  Widget build(BuildContext c) {
    return FutureBuilder<QuerySnapshot>(
        future: widget.list,
        builder: (con, data) {
          if (data.hasData) {
            return Column(children: <Widget>[
              TextField(
                  decoration: InputDecoration(
                    hintText: 'بحث...',
                  ),
                  onChanged: (text) {
                    setState(() {
                      filter = text;
                    });
                  }),
              if (widget.showNull)
                Card(
                  child: ListTile(
                    onTap: () {
                      widget.tap(PersonType('', 'لا يوجد'), context);
                    },
                    title: Text('لا يوجد'),
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                    child: ListView.builder(
                        itemCount: data.data.size,
                        itemBuilder: (context, i) {
                          PersonType current = PersonType.fromDocumentSnapshot(
                              data.data.docs[i]);
                          return current.name.contains(filter)
                              ? Card(
                                  child: ListTile(
                                    onTap: () => widget.tap(current, context),
                                    title: Text(current.name),
                                  ),
                                )
                              : Container();
                        }),
                    onRefresh: () {
                      setState(() {});
                      return null;
                    }),
              )
            ]);
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        });
  }
}
