import 'package:churchdata/models/list_options.dart';
import 'package:churchdata/models/user.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'mini_lists/users_list.dart';

class UsersPage extends StatelessWidget {
  UsersPage({Key key}) : super(key: key);

  final BehaviorSubject<bool> _showSearch = BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<String> _search = BehaviorSubject<String>.seeded('');
  final FocusNode searchFocus = FocusNode();

  @override
  Widget build(BuildContext context) {
    var _listOptions = DataObjectListOptions<User>(
      itemsStream: Stream.fromFuture(User.getUsersForEdit()),
      searchQuery: _search,
    );
    return Scaffold(
      appBar: AppBar(
        actions: [
          StreamBuilder<bool>(
            initialData: false,
            stream: _showSearch,
            builder: (context, showSearch) {
              return !showSearch.data
                  ? IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () {
                        searchFocus.requestFocus();
                        _showSearch.add(true);
                      },
                    )
                  : Container();
            },
          ),
          IconButton(
              icon: Icon(Icons.link),
              tooltip: 'لينكات الدعوة',
              onPressed: () => Navigator.pushNamed(context, 'Invitations')),
        ],
        title: StreamBuilder<bool>(
          initialData: false,
          stream: _showSearch,
          builder: (context, showSearch) {
            return showSearch.data
                ? TextField(
                    focusNode: searchFocus,
                    decoration: InputDecoration(
                        suffixIcon: IconButton(
                          icon: Icon(Icons.close,
                              color: Theme.of(context)
                                  .primaryTextTheme
                                  .headline6
                                  .color),
                          onPressed: () {
                            _search.add('');
                            _showSearch.add(false);
                          },
                        ),
                        hintText: 'بحث ...'),
                    onChanged: _search.add,
                  )
                : Text('المستخدمون');
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).primaryColor,
        shape: const CircularNotchedRectangle(),
        child: StreamBuilder(
          stream: _listOptions.objectsData,
          builder: (context, snapshot) {
            return Text(
              (snapshot.data?.length ?? 0).toString() + ' مستخدم',
              textAlign: TextAlign.center,
              strutStyle: StrutStyle(height: IconTheme.of(context).size / 7.5),
              style: Theme.of(context).primaryTextTheme.bodyText1,
            );
          },
        ),
      ),
      body: UsersList(
        listOptions: _listOptions,
      ),
    );
  }
}
