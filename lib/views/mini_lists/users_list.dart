import 'package:churchdata/models/list_controllers.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class UsersList extends StatefulWidget {
  final DataObjectListController<User>? listOptions;
  final bool autoDisposeController;

  const UsersList(
      {Key? key, this.listOptions, required this.autoDisposeController})
      : super(key: key);

  @override
  _UsersListState createState() => _UsersListState();
}

class _UsersListState extends State<UsersList> {
  late DataObjectListController<User> _listOptions;

  @override
  void initState() {
    super.initState();
    _listOptions =
        widget.listOptions ?? context.read<DataObjectListController<User>>();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<User>>(
      stream: _listOptions.objectsData,
      builder: (context, options) {
        if (options.hasError) return Center(child: ErrorWidget(options.error!));
        if (!options.hasData)
          return const Center(child: CircularProgressIndicator());

        final List<User> _data = options.data!;
        if (_data.isEmpty) return const Center(child: Text('لا يوجد مستخدمين'));

        mergeSort<User>(_data, compare: (u1, u2) => u1.name.compareTo(u2.name));

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
              child: _listOptions.buildItem(
                current,
                onLongPress: _listOptions.onLongPress ??
                    (u) {
                      _listOptions.selectionMode
                          .add(!_listOptions.selectionMode.value);
                      if (_listOptions.selectionMode.value)
                        _listOptions.select(current);
                    },
                onTap: (User current) {
                  if (!_listOptions.selectionMode.value) {
                    _listOptions.tap == null
                        ? dataObjectTap(current, context)
                        : _listOptions.tap!(current);
                  } else {
                    _listOptions.toggleSelected(current);
                  }
                },
                trailing: StreamBuilder<Map<String, User>?>(
                  stream: Rx.combineLatest2<Map<String, User>, bool,
                      Map<String, User>?>(
                    _listOptions.selected,
                    _listOptions.selectionMode,
                    (a, b) => b ? a : null,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Checkbox(
                        value: snapshot.data!.containsKey(current.id),
                        onChanged: (v) {
                          if (v == true) {
                            _listOptions.select(current);
                          } else {
                            _listOptions.deselect(current);
                          }
                        },
                      );
                    }
                    return SizedBox(width: 1, height: 1);
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
