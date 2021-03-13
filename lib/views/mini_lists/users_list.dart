import 'package:churchdata/models/user.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:churchdata/models/data_object_widget.dart';
import 'package:churchdata/models/list.dart';
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
            onRefresh: () {
              setState(() {});
              return User.getUsersForEdit();
            },
            child: Builder(
              builder: (context) {
                List<User> documentData = future.data.sublist(0)
                  ..sort((u1, u2) => u1.name.compareTo(u2.name));
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
      builder: (context, options, filter, _) => StreamBuilder<List<User>>(
        stream: options.documentsData,
        builder: (context, stream) {
          if (stream.hasError) return Center(child: ErrorWidget(stream.error));
          if (!stream.hasData)
            return Center(child: CircularProgressIndicator());
          return RefreshIndicator(
            onRefresh: () {
              setState(() {});
              return options.documentsData.last;
            },
            child: Builder(
              builder: (context) {
                List<User> documentData = stream.data.sublist(0);
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
                      showSubtitle: false,
                      photo: current.getPhoto(),
                      onLongPress: User.instance.manageUsers
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
          );
        },
      ),
    );
  }
}
