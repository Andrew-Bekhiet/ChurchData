import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:churchdata/models/list_options.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class UsersList extends StatefulWidget {
  final DataObjectListOptions<User> listOptions;

  const UsersList({Key key, this.listOptions}) : super(key: key);

  @override
  _UsersListState createState() => _UsersListState();
}

class _UsersListState extends State<UsersList> {
  DataObjectListOptions<User> _listOptions;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _listOptions =
        widget.listOptions ?? context.read<DataObjectListOptions<User>>();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<User>>(
      stream: _listOptions.objectsData,
      builder: (context, options) {
        if (options.hasError) return Center(child: ErrorWidget(options.error));
        if (!options.hasData)
          return const Center(child: CircularProgressIndicator());

        final List<User> _data = options.data;
        if (_data.isEmpty) return const Center(child: Text('لا يوجد مستخدمين'));

        mergeSort(_data, compare: (u1, u2) => u1.name.compareTo(u2.name));

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 4),
          itemCount: _data.length + 1,
          cacheExtent: 500,
          itemBuilder: (context, i) {
            if (i == _data.length)
              return Container(height: MediaQuery.of(context).size.height / 38);

            final User current = _data[i];
            return Padding(
              padding: const EdgeInsets.fromLTRB(3, 0, 9, 0),
              child: _listOptions.itemBuilder(
                current,
                onLongPress: _listOptions.onLongPress ??
                    (u) {
                      _listOptions.selectionMode
                          .add(!_listOptions.selectionModeLatest);
                      if (_listOptions.selectionModeLatest)
                        _listOptions.select(current);
                    },
                onTap: (User current) {
                  if (!_listOptions.selectionModeLatest) {
                    _listOptions.tap == null
                        ? dataObjectTap(current, context)
                        : _listOptions.tap(current);
                  } else {
                    _listOptions.toggleSelected(current);
                  }
                },
                trailing: StreamBuilder<Map<String, User>>(
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
              ),
            );
          },
        );
      },
    );
  }
}
