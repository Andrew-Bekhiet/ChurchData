import 'package:churchdata/views/utils/List.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../MiniLists/UsersList.dart';

class UsersPage extends StatefulWidget {
  UsersPage({Key key}) : super(key: key);
  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  bool _showSearch = false;
  @override
  Widget build(BuildContext context) {
    return ListenableProvider<SearchString>(
      create: (_) => SearchString(''),
      builder: (context, child) => Scaffold(
        appBar: AppBar(
          actions: [
            if (!_showSearch)
              IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => setState(() => _showSearch = true)),
          ],
          title: _showSearch
              ? TextField(
                  decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => setState(
                          () {
                            context.read<SearchString>().value = '';
                            _showSearch = false;
                          },
                        ),
                      ),
                      hintStyle: Theme.of(context).primaryTextTheme.headline6,
                      hintText: 'بحث ...'),
                  onChanged: (t) => context.read<SearchString>().value = t,
                )
              : Text('المستخدمون'),
        ),
        body: UsersEditList(),
      ),
    );
  }
}
