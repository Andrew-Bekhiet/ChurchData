import 'package:churchdata/models/list_controllers.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'mini_lists/users_list.dart';

class UsersPage extends StatelessWidget {
  UsersPage({Key? key}) : super(key: key);

  final BehaviorSubject<bool> _showSearch = BehaviorSubject<bool>.seeded(false);
  final FocusNode searchFocus = FocusNode();

  final _listOptions = DataObjectListController<User>(
    itemsStream: Stream.fromFuture(User.getUsersForEdit()),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          StreamBuilder<bool>(
            initialData: false,
            stream: _showSearch,
            builder: (context, showSearch) {
              return !showSearch.data!
                  ? IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        searchFocus.requestFocus();
                        _showSearch.add(true);
                      },
                    )
                  : Container();
            },
          ),
          IconButton(
              icon: const Icon(Icons.link),
              tooltip: 'لينكات الدعوة',
              onPressed: () =>
                  navigator.currentState!.pushNamed('Invitations')),
        ],
        title: StreamBuilder<bool>(
          initialData: false,
          stream: _showSearch,
          builder: (context, showSearch) {
            return showSearch.data!
                ? TextField(
                    focusNode: searchFocus,
                    decoration: InputDecoration(
                        suffixIcon: IconButton(
                          icon: Icon(Icons.close,
                              color: Theme.of(context)
                                  .primaryTextTheme
                                  .titleLarge
                                  ?.color),
                          onPressed: () {
                            _listOptions.searchQuery.add('');
                            _showSearch.add(false);
                          },
                        ),
                        hintText: 'بحث ...'),
                    onChanged: _listOptions.searchQuery.add,
                  )
                : const Text('المستخدمون');
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: StreamBuilder<List>(
          stream: _listOptions.objectsData,
          builder: (context, snapshot) {
            return Text(
              (snapshot.data?.length ?? 0).toString() + ' مستخدم',
              textAlign: TextAlign.center,
              strutStyle: StrutStyle(height: IconTheme.of(context).size! / 7.5),
              style: Theme.of(context).primaryTextTheme.bodyLarge,
            );
          },
        ),
      ),
      body: UsersList(
        autoDisposeController: true,
        listOptions: _listOptions,
      ),
    );
  }
}
