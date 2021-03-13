import 'dart:async';

import 'package:churchdata/models/list_options.dart';
import 'package:churchdata/models/order_options.dart';
import 'package:churchdata/models/person.dart';
import 'package:churchdata/models/search_string.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/models/data_dialog.dart';
import 'package:churchdata/models/list.dart';
import 'package:churchdata/models/search_filters.dart';
import 'package:churchdata/views/mini_lists/users_list.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart' hide User;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

class UserP extends StatefulWidget {
  final User user;

  UserP({Key key, @required this.user}) : super(key: key);
  @override
  _UserPState createState() => _UserPState();
}

class _UserPState extends State<UserP> {
  List<FocusNode> focuses = [
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode()
  ];
  Map<String, dynamic> old;
  GlobalKey<FormState> form = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: !kIsWeb,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              actions: [
                IconButton(
                  icon: Icon(Icons.close),
                  tooltip: 'إلغاء تنشيط الحساب',
                  onPressed: unApproveUser,
                ),
                IconButton(
                  icon: Icon(Icons.delete_forever),
                  tooltip: 'حذف الحساب',
                  onPressed: deleteUser,
                ),
              ],
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) => FlexibleSpaceBar(
                  title: AnimatedOpacity(
                    duration: Duration(milliseconds: 300),
                    opacity: constraints.biggest.height > kToolbarHeight * 1.7
                        ? 0
                        : 1,
                    child: Text(
                      widget.user.name,
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                  background: widget.user.getPhoto(false, false),
                ),
              ),
            ),
          ];
        },
        body: Form(
          key: form,
          child: Padding(
            padding: EdgeInsets.all(5),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'الاسم',
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                        ),
                      ),
                      focusNode: focuses[0],
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => focuses[1].requestFocus(),
                      initialValue: widget.user.name,
                      onChanged: nameChanged,
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'هذا الحقل مطلوب';
                        }
                        return null;
                      },
                    ),
                  ),
                  if (User.instance.manageUsers)
                    ListTile(
                      trailing: Checkbox(
                        value: widget.user.manageUsers,
                        onChanged: (v) =>
                            setState(() => widget.user.manageUsers = v),
                      ),
                      leading: Icon(
                          const IconData(0xef3d, fontFamily: 'MaterialIconsR')),
                      title: Text('إدارة المستخدمين'),
                      onTap: () => setState(() =>
                          widget.user.manageUsers = !widget.user.manageUsers),
                    ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget.user.manageAllowedUsers,
                      onChanged: (v) =>
                          setState(() => widget.user.manageAllowedUsers = v),
                    ),
                    leading: Icon(
                        const IconData(0xef3d, fontFamily: 'MaterialIconsR')),
                    title: Text('إدارة مستخدمين محددين'),
                    onTap: () => setState(() => widget.user.manageAllowedUsers =
                        !widget.user.manageAllowedUsers),
                  ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget.user.superAccess,
                      onChanged: (v) =>
                          setState(() => widget.user.superAccess = v),
                    ),
                    leading: Icon(
                      const IconData(0xef56, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('رؤية جميع البيانات'),
                    onTap: () => setState(() =>
                        widget.user.superAccess = !widget.user.superAccess),
                  ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget.user.write,
                      onChanged: (v) => setState(() => widget.user.write = v),
                    ),
                    leading: Icon(Icons.edit),
                    title: Text('تعديل البيانات'),
                    onTap: () =>
                        setState(() => widget.user.write = !widget.user.write),
                  ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget.user.exportAreas,
                      onChanged: (v) =>
                          setState(() => widget.user.exportAreas = v),
                    ),
                    leading: Icon(Icons.cloud_download),
                    title: Text('تصدير منطقة لملف إكسل'),
                    onTap: () => setState(() =>
                        widget.user.exportAreas = !widget.user.exportAreas),
                  ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget.user.birthdayNotify,
                      onChanged: (v) =>
                          setState(() => widget.user.birthdayNotify = v),
                    ),
                    leading: Icon(
                      const IconData(0xe7e9, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('إشعار أعياد الميلاد'),
                    onTap: () => setState(() => widget.user.birthdayNotify =
                        !widget.user.birthdayNotify),
                  ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget.user.confessionsNotify ?? false,
                      onChanged: (v) =>
                          setState(() => widget.user.confessionsNotify = v),
                    ),
                    leading: Icon(
                      const IconData(0xe7f7, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('إشعار الاعتراف'),
                    onTap: () => setState(
                      () => widget.user.confessionsNotify =
                          !(widget.user.confessionsNotify ?? false),
                    ),
                  ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget.user.tanawolNotify ?? false,
                      onChanged: (v) =>
                          setState(() => widget.user.tanawolNotify = v),
                    ),
                    leading: Icon(
                      const IconData(0xe7f7, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('إشعار التناول'),
                    onTap: () => setState(
                      () => widget.user.tanawolNotify =
                          !(widget.user.tanawolNotify ?? false),
                    ),
                  ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget.user.approveLocations,
                      onChanged: (v) =>
                          setState(() => widget.user.approveLocations = v),
                    ),
                    title: Text('التأكيد على المواقع'),
                    onTap: () => setState(() => widget.user.approveLocations =
                        !widget.user.approveLocations),
                    leading: Icon(
                      const IconData(0xe8e8, fontFamily: 'MaterialIconsR'),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: Focus(
                      focusNode: focuses[1],
                      child: InkWell(
                        onTap: _selectPerson,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'ربط بشخص',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor),
                            ),
                          ),
                          child: FutureBuilder<Person>(
                            future: widget.user.getPerson(),
                            builder: (contextt, dataServ) {
                              if (dataServ.connectionState ==
                                  ConnectionState.done) {
                                if (dataServ.data == null)
                                  return Container(width: 0.0, height: 0.0);
                                return Text(dataServ.data.name);
                              } else {
                                return LinearProgressIndicator();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: editAllowedUsers,
                    icon: Icon(Icons.shield),
                    label: Text('تعديل المستخدمين المسموح لهم بتعديل المستخدم',
                        softWrap: false,
                        textScaleFactor: 0.95,
                        overflow: TextOverflow.fade),
                  ),
                  ElevatedButton.icon(
                    onPressed: resetPassword,
                    icon: Icon(Icons.lock_open),
                    label: Text('إعادة تعيين كلمة السر'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          FloatingActionButton(
            tooltip: 'حفظ',
            heroTag: null,
            onPressed: save,
            child: Icon(Icons.save),
          ),
        ],
      ),
    );
  }

  void unApproveUser() {
    showDialog(
      context: context,
      builder: (context) => DataDialog(
        title: Text('إلغاء تنشيط حساب ${widget.user.name}'),
        content: Text('إلغاء تنشيط الحساب لن يقوم بالضرورة بحذف الحساب '),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: LinearProgressIndicator(),
                    duration: Duration(seconds: 15),
                  ),
                );
                Navigator.of(context).pop();
                await FirebaseFunctions.instance
                    .httpsCallable('unApproveUser')
                    .call({'affectedUser': widget.user.uid});
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.of(context).pop('unapproved');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم بنجاح'),
                    duration: Duration(seconds: 15),
                  ),
                );
              } catch (err, stkTrace) {
                await FirebaseCrashlytics.instance
                    .setCustomKey('LastErrorIn', 'UserPState.unapproveUser');
                await FirebaseCrashlytics.instance.recordError(err, stkTrace);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      err.toString(),
                    ),
                    duration: Duration(seconds: 7),
                  ),
                );
              }
            },
            child: Text('متابعة'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('تراجع'),
          ),
        ],
      ),
    );
  }

  void deleteUser() {
    showDialog(
      context: context,
      builder: (context) => DataDialog(
        title: Text('حذف حساب ${widget.user.name}'),
        content:
            Text('هل أنت متأكد من حذف حساب ' + widget.user.name + ' نهائيًا؟'),
        actions: <Widget>[
          TextButton(
            style: Theme.of(context).textButtonTheme.style.copyWith(
                foregroundColor:
                    MaterialStateProperty.resolveWith((state) => Colors.red)),
            onPressed: () async {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: LinearProgressIndicator(),
                    duration: Duration(seconds: 15),
                  ),
                );
                Navigator.of(context).pop();
                await FirebaseFunctions.instance
                    .httpsCallable('deleteUser')
                    .call({'affectedUser': widget.user.uid});
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.of(context).pop('deleted');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم بنجاح'),
                    duration: Duration(seconds: 15),
                  ),
                );
              } catch (err, stkTrace) {
                await FirebaseCrashlytics.instance
                    .setCustomKey('LastErrorIn', 'UserPState.delete');
                await FirebaseCrashlytics.instance.recordError(err, stkTrace);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      err.toString(),
                    ),
                    duration: Duration(seconds: 7),
                  ),
                );
              }
            },
            child: Text('حذف'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('تراجع'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    old = widget.user.getUpdateMap();
    super.initState();
  }

  void nameChanged(String value) {
    widget.user.name = value;
  }

  Future resetPassword() async {
    if (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('هل أنت متأكد من إعادة تعيين كلمة السر ل' +
                widget.user.name +
                '?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('نعم'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('لا'),
              ),
            ],
          ),
        ) !=
        true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: LinearProgressIndicator(),
        duration: Duration(seconds: 15),
      ),
    );
    try {
      // !kIsWeb
      //     ?
      await FirebaseFunctions.instance
          .httpsCallable('resetPassword')
          .call({'affectedUser': widget.user.uid});
      // : await functions()
      //     .httpsCallable('resetPassword')
      //     .call({'affectedUser': widget.user.uid});
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إعادة تعيين كلمة السر بنجاح'),
        ),
      );
    } catch (err, stkTrace) {
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'UserPState.resetPassword');
      await FirebaseCrashlytics.instance.recordError(err, stkTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            err.toString(),
          ),
        ),
      );
    }
  }

  Future save() async {
    try {
      if (form.currentState.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('جار الحفظ...'),
            duration: Duration(seconds: 15),
          ),
        );
        var update = widget.user.getUpdateMap();
        if (old['name'] != widget.user.name)
          await FirebaseFunctions.instance.httpsCallable('changeUserName').call(
              {'affectedUser': widget.user.uid, 'newName': widget.user.name});
        update.remove('name');
        if (update.isNotEmpty)
          await FirebaseFunctions.instance
              .httpsCallable('updatePermissions')
              .call({'affectedUser': widget.user.uid, 'permissions': update});
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        Navigator.of(context).pop(widget.user.uid);
      }
    } catch (err, stkTrace) {
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'UserPState.save');
      await FirebaseCrashlytics.instance.setCustomKey('User', widget.user.uid);
      await FirebaseCrashlytics.instance.recordError(err, stkTrace);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            err.toString(),
          ),
          duration: Duration(seconds: 7),
        ),
      );
    }
  }

  Future _selectPerson() async {
    await showDialog(
      context: context,
      builder: (context) {
        return DataDialog(
          content: Container(
            width: MediaQuery.of(context).size.width - 55,
            height: MediaQuery.of(context).size.height - 110,
            child: ListenableProvider<SearchString>(
              create: (_) => SearchString(''),
              builder: (context, child) => Column(
                children: [
                  SearchFilters(3,
                      textStyle: Theme.of(context).textTheme.bodyText2),
                  Expanded(
                      child: Selector<OrderOptions, Tuple2<String, bool>>(
                    selector: (_, o) =>
                        Tuple2<String, bool>(o.personOrderBy, o.personASC),
                    builder: (context, options, child) =>
                        DataObjectList<Person>(
                      options: ListOptions<Person>(
                        tap: (person) {
                          setState(() {
                            if (person != null)
                              widget.user.personRef = 'Persons/${person.id}';
                          });
                          Navigator.of(context).pop();
                        },
                        documentsData: Person.getAllForUser(
                                orderBy: options.item1,
                                descending: !options.item2)
                            .map((s) => s.docs.map(Person.fromDoc).toList()),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void editAllowedUsers() async {
    widget.user.allowedUsers = await showDialog(
          context: context,
          builder: (context) {
            return FutureBuilder<List<User>>(
              future: User.getUsers(widget.user.allowedUsers),
              builder: (c, users) => users.hasData
                  ? MultiProvider(
                      providers: [
                        ListenableProvider<SearchString>(
                          create: (_) => SearchString(''),
                        ),
                        ListenableProvider(
                            create: (_) => ListOptions<User>(
                                documentsData: Stream.fromFuture(
                                    User.getAllSemiManagers()),
                                selected: users.data))
                      ],
                      builder: (context, child) => AlertDialog(
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(
                                  context,
                                  context
                                      .read<ListOptions<User>>()
                                      .selected
                                      ?.map((f) => f.uid)
                                      ?.toList());
                            },
                            child: Text('تم'),
                          )
                        ],
                        content: Container(
                          width: 280,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SearchField(
                                  textStyle:
                                      Theme.of(context).textTheme.bodyText2),
                              Expanded(
                                child: Selector<OrderOptions,
                                    Tuple2<String, bool>>(
                                  selector: (_, o) => Tuple2<String, bool>(
                                      o.areaOrderBy, o.areaASC),
                                  builder: (context, options, child) =>
                                      UsersList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Center(child: CircularProgressIndicator()),
            );
          },
        ) ??
        widget.user.allowedUsers;
  }
}
