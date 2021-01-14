import 'dart:async';

import 'package:churchdata/Models/User.dart';
import 'package:churchdata/utils/Helpers.dart';
import 'package:churchdata/views/utils/DataObjectWidget.dart';
import 'package:churchdata/views/utils/List.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UsersEditList extends StatefulWidget {
  UsersEditList({Key key}) : super(key: key);

  @override
  _UsersEditListState createState() => _UsersEditListState();
}

class UsersList extends StatefulWidget {
  UsersList({Key key}) : super(key: key);

  @override
  _UsersListState createState() => _UsersListState();
}

class _UsersEditListState extends State<UsersEditList> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SearchString>(
      builder: (context, filter, _) => FutureBuilder<List<User>>(
        future: User.getUsersForEdit(),
        builder: (context, future) {
          if (future.hasError) return Center(child: ErrorWidget(future.error));
          if (!future.hasData)
            return Center(child: CircularProgressIndicator());

          return RefreshIndicator(
            child: Builder(
              builder: (context) {
                List<User> documentData = future.data.sublist(0);
                if (filter.value != '')
                  documentData.retainWhere((element) => element.name
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
                      .contains(filter.value));
                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  addAutomaticKeepAlives: (documentData?.length ?? 0) < 300,
                  cacheExtent: 200,
                  itemCount: documentData?.length ?? 0,
                  itemBuilder: (context, i) {
                    var current = documentData[i];
                    return DataObjectWidget<User>(
                      current,
                      photo: current.getPhoto(),
                      onTap: () {
                        userTap(current, context);
                      },
                      subtitle: Text(
                        current.getPermissions(),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  },
                );
              },
            ),
            onRefresh: () {
              setState(() {});
              return User.getUsersForEdit();
            },
          );
        },
      ),
    );
  }
}

class _UsersListState extends State<UsersList> {
  @override
  Widget build(BuildContext c) {
    return Consumer2<ListOptions<User>, SearchString>(
      builder: (context, options, filter, _) =>
          FutureBuilder<Stream<QuerySnapshot>>(
        future: options.documentsData(),
        builder: (context, future) {
          if (future.hasError) return Center(child: ErrorWidget(future.error));
          if (!future.hasData)
            return Center(child: CircularProgressIndicator());
          return StreamBuilder<QuerySnapshot>(
            stream: future.data,
            builder: (context, stream) {
              if (stream.hasError)
                return Center(child: ErrorWidget(stream.error));
              if (!stream.hasData)
                return Center(child: CircularProgressIndicator());
              return RefreshIndicator(
                child: Builder(
                  builder: (context) {
                    List<DocumentSnapshot> documentData =
                        stream.data.docs.sublist(0);
                    if (filter.value != '')
                      documentData.retainWhere((element) => element
                          .data()['Name']
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
                          .contains(filter.value));
                    return ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      addAutomaticKeepAlives: (documentData?.length ?? 0) < 300,
                      cacheExtent: 200,
                      itemCount: documentData?.length ?? 0,
                      itemBuilder: (context, i) {
                        var current =
                            User.fromDocumentSnapshot(documentData[i]);
                        return DataObjectWidget<User>(
                          current,
                          showSubtitle: false,
                          photo: current.getPhoto(),
                          onLongPress: options.isAdmin
                              ? () => userTap(current, context)
                              : null,
                          onTap: () {
                            if (options.selected.contains(current)) {
                              setState(() {
                                options.selected.remove(current);
                              });
                            } else {
                              setState(() {
                                options.selected.add(current);
                              });
                            }
                          },
                          trailing: Checkbox(
                              value: options.selected.contains(current),
                              onChanged: (v) {
                                setState(() {
                                  if (v) {
                                    options.selected.add(current);
                                  } else {
                                    options.selected.remove(current);
                                  }
                                });
                              }),
                        );
                      },
                    );
                  },
                ),
                onRefresh: () {
                  setState(() {});
                  return options.documentsData();
                },
              );
            },
          );
        },
      ),
    );
  }
}
