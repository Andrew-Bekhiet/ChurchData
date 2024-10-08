import 'dart:async';

import 'package:churchdata/models/data_dialog.dart';
import 'package:churchdata/models/data_object_widget.dart';
import 'package:churchdata/models/list.dart';
import 'package:churchdata/models/list_controllers.dart';
import 'package:churchdata/models/person.dart';
import 'package:churchdata/models/search_filters.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/views/mini_lists/users_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class UserP extends StatefulWidget {
  final User user;

  const UserP({required this.user, super.key});
  @override
  _UserPState createState() => _UserPState();
}

class _UserPState extends State<UserP> {
  List<FocusNode> focuses = [
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode(),
  ];
  late Json old;
  GlobalKey<FormState> form = GlobalKey<FormState>();

  List<User>? childrenUsers;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 250.0,
              pinned: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'إلغاء تنشيط الحساب',
                  onPressed: unApproveUser,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  tooltip: 'حذف الحساب',
                  onPressed: deleteUser,
                ),
              ],
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) => FlexibleSpaceBar(
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: constraints.biggest.height > kToolbarHeight * 1.7
                        ? 0
                        : 1,
                    child: Text(
                      widget.user.name,
                      style: const TextStyle(
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
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'الاسم',
                      ),
                      focusNode: focuses[0],
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => focuses[1].requestFocus(),
                      initialValue: widget.user.name,
                      onChanged: nameChanged,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
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
                        onChanged: (v) => setState(
                          () => widget.user.manageUsers = v ?? false,
                        ),
                      ),
                      leading: const Icon(
                        IconData(0xef3d, fontFamily: 'MaterialIconsR'),
                      ),
                      title: const Text('إدارة المستخدمين'),
                      onTap: () => setState(
                        () =>
                            widget.user.manageUsers = !widget.user.manageUsers,
                      ),
                    ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget.user.manageAllowedUsers,
                      onChanged: (v) => setState(
                        () => widget.user.manageAllowedUsers = v ?? false,
                      ),
                    ),
                    leading: const Icon(
                      IconData(0xef3d, fontFamily: 'MaterialIconsR'),
                    ),
                    title: const Text('إدارة مستخدمين محددين'),
                    onTap: () => setState(
                      () => widget.user.manageAllowedUsers =
                          !widget.user.manageAllowedUsers,
                    ),
                  ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget.user.superAccess,
                      onChanged: (v) =>
                          setState(() => widget.user.superAccess = v ?? false),
                    ),
                    leading: const Icon(
                      IconData(0xef56, fontFamily: 'MaterialIconsR'),
                    ),
                    title: const Text('رؤية جميع البيانات'),
                    onTap: () => setState(
                      () => widget.user.superAccess = !widget.user.superAccess,
                    ),
                  ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget.user.manageDeleted,
                      onChanged: (v) => setState(
                        () => widget.user.manageDeleted = v ?? false,
                      ),
                    ),
                    leading: const Icon(Icons.delete_outlined),
                    title: const Text('استرجاع المحذوفات'),
                    onTap: () => setState(
                      () => widget.user.manageDeleted =
                          !widget.user.manageDeleted,
                    ),
                  ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget.user.write,
                      onChanged: (v) =>
                          setState(() => widget.user.write = v ?? false),
                    ),
                    leading: const Icon(Icons.edit),
                    title: const Text('تعديل البيانات'),
                    onTap: () =>
                        setState(() => widget.user.write = !widget.user.write),
                  ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget.user.exportAreas,
                      onChanged: (v) =>
                          setState(() => widget.user.exportAreas = v ?? false),
                    ),
                    leading: const Icon(Icons.cloud_download),
                    title: const Text('تصدير منطقة لملف إكسل'),
                    onTap: () => setState(
                      () => widget.user.exportAreas = !widget.user.exportAreas,
                    ),
                  ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget.user.birthdayNotify,
                      onChanged: (v) => setState(
                        () => widget.user.birthdayNotify = v ?? false,
                      ),
                    ),
                    leading: const Icon(
                      IconData(0xe7e9, fontFamily: 'MaterialIconsR'),
                    ),
                    title: const Text('إشعار أعياد الميلاد'),
                    onTap: () => setState(
                      () => widget.user.birthdayNotify =
                          !widget.user.birthdayNotify,
                    ),
                  ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget.user.confessionsNotify,
                      onChanged: (v) => setState(
                        () => widget.user.confessionsNotify = v ?? false,
                      ),
                    ),
                    leading: const Icon(
                      IconData(0xe7f7, fontFamily: 'MaterialIconsR'),
                    ),
                    title: const Text('إشعار الاعتراف'),
                    onTap: () => setState(
                      () => widget.user.confessionsNotify =
                          !widget.user.confessionsNotify,
                    ),
                  ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget.user.tanawolNotify,
                      onChanged: (v) => setState(
                        () => widget.user.tanawolNotify = v ?? false,
                      ),
                    ),
                    leading: const Icon(
                      IconData(0xe7f7, fontFamily: 'MaterialIconsR'),
                    ),
                    title: const Text('إشعار التناول'),
                    onTap: () => setState(
                      () => widget.user.tanawolNotify =
                          !widget.user.tanawolNotify,
                    ),
                  ),
                  ListTile(
                    trailing: Checkbox(
                      value: widget.user.approveLocations,
                      onChanged: (v) => setState(
                        () => widget.user.approveLocations = v ?? false,
                      ),
                    ),
                    title: const Text('التأكيد على المواقع'),
                    onTap: () => setState(
                      () => widget.user.approveLocations =
                          !widget.user.approveLocations,
                    ),
                    leading: const Icon(
                      IconData(0xe8e8, fontFamily: 'MaterialIconsR'),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Focus(
                      focusNode: focuses[1],
                      child: InkWell(
                        onTap: _selectPerson,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'ربط بشخص',
                          ),
                          child: widget.user.personRef != null
                              ? FutureBuilder<Person?>(
                                  future: widget.user.getPerson(),
                                  builder: (contextt, dataServ) {
                                    if (dataServ.hasData) {
                                      return Text(dataServ.data!.name);
                                    } else {
                                      return const LinearProgressIndicator();
                                    }
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: editChildrenUsers,
                    icon: const Icon(Icons.shield),
                    label: Text(
                      'تعديل المستخدمين المسؤول عنهم ' + widget.user.name,
                      softWrap: false,
                      textScaler: const TextScaler.linear(0.95),
                      overflow: TextOverflow.fade,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: resetPassword,
                    icon: const Icon(Icons.lock_open),
                    label: const Text('إعادة تعيين كلمة السر'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            tooltip: 'حفظ',
            heroTag: null,
            onPressed: save,
            child: const Icon(Icons.save),
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
        content: const Text('إلغاء تنشيط الحساب لن يقوم بالضرورة بحذف الحساب '),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              try {
                scaffoldMessenger.currentState!.showSnackBar(
                  const SnackBar(
                    content: LinearProgressIndicator(),
                    duration: Duration(seconds: 15),
                  ),
                );
                navigator.currentState!.pop();
                await firebaseFunctions
                    .httpsCallable('unApproveUser')
                    .call({'affectedUser': widget.user.uid});
                scaffoldMessenger.currentState!.hideCurrentSnackBar();
                navigator.currentState!.pop('unapproved');
                scaffoldMessenger.currentState!.showSnackBar(
                  const SnackBar(
                    content: Text('تم بنجاح'),
                    duration: Duration(seconds: 15),
                  ),
                );
              } catch (err, stkTrace) {
                await FirebaseCrashlytics.instance
                    .setCustomKey('LastErrorIn', 'UserPState.unapproveUser');
                await FirebaseCrashlytics.instance.recordError(err, stkTrace);
                scaffoldMessenger.currentState!.hideCurrentSnackBar();
                scaffoldMessenger.currentState!.showSnackBar(
                  SnackBar(
                    content: Text(
                      err.toString(),
                    ),
                    duration: const Duration(seconds: 7),
                  ),
                );
              }
            },
            child: const Text('متابعة'),
          ),
          TextButton(
            onPressed: () {
              navigator.currentState!.pop();
            },
            child: const Text('تراجع'),
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
            style: Theme.of(context).textButtonTheme.style?.copyWith(
                  foregroundColor:
                      WidgetStateProperty.resolveWith((state) => Colors.red),
                ),
            onPressed: () async {
              try {
                scaffoldMessenger.currentState!.showSnackBar(
                  const SnackBar(
                    content: LinearProgressIndicator(),
                    duration: Duration(seconds: 15),
                  ),
                );
                navigator.currentState!.pop();
                await firebaseFunctions
                    .httpsCallable('deleteUser')
                    .call({'affectedUser': widget.user.uid});
                scaffoldMessenger.currentState!.hideCurrentSnackBar();
                navigator.currentState!.pop('deleted');
                scaffoldMessenger.currentState!.showSnackBar(
                  const SnackBar(
                    content: Text('تم بنجاح'),
                    duration: Duration(seconds: 15),
                  ),
                );
              } catch (err, stkTrace) {
                await FirebaseCrashlytics.instance
                    .setCustomKey('LastErrorIn', 'UserPState.delete');
                await FirebaseCrashlytics.instance.recordError(err, stkTrace);
                scaffoldMessenger.currentState!.hideCurrentSnackBar();
                scaffoldMessenger.currentState!.showSnackBar(
                  SnackBar(
                    content: Text(
                      err.toString(),
                    ),
                    duration: const Duration(seconds: 7),
                  ),
                );
              }
            },
            child: const Text('حذف'),
          ),
          TextButton(
            onPressed: () {
              navigator.currentState!.pop();
            },
            child: const Text('تراجع'),
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
            title: Text(
              'هل أنت متأكد من إعادة تعيين كلمة السر ل' +
                  widget.user.name +
                  '؟',
            ),
            actions: [
              TextButton(
                onPressed: () => navigator.currentState!.pop(true),
                child: const Text('نعم'),
              ),
              TextButton(
                onPressed: () => navigator.currentState!.pop(false),
                child: const Text('لا'),
              ),
            ],
          ),
        ) !=
        true) return;
    scaffoldMessenger.currentState!.showSnackBar(
      const SnackBar(
        content: LinearProgressIndicator(),
        duration: Duration(seconds: 15),
      ),
    );
    try {
      // !kIsWeb
      //     ?
      await firebaseFunctions
          .httpsCallable('resetPassword')
          .call({'affectedUser': widget.user.uid});
      // : await functions()
      //     .httpsCallable('resetPassword')
      //     .call({'affectedUser': widget.user.uid});
      scaffoldMessenger.currentState!.hideCurrentSnackBar();
      scaffoldMessenger.currentState!.showSnackBar(
        const SnackBar(
          content: Text('تم إعادة تعيين كلمة السر بنجاح'),
        ),
      );
    } catch (err, stkTrace) {
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'UserPState.resetPassword');
      await FirebaseCrashlytics.instance.recordError(err, stkTrace);
      scaffoldMessenger.currentState!.showSnackBar(
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
      if (form.currentState!.validate()) {
        scaffoldMessenger.currentState!.showSnackBar(
          const SnackBar(
            content: Text('جار الحفظ...'),
            duration: Duration(seconds: 15),
          ),
        );
        final update = widget.user.getUpdateMap();
        if (old['name'] != widget.user.name)
          await firebaseFunctions.httpsCallable('changeUserName').call(
            {'affectedUser': widget.user.uid, 'newName': widget.user.name},
          );
        update
          ..remove('name')
          ..remove('allowedUsers');
        if (update.isNotEmpty)
          await firebaseFunctions
              .httpsCallable('updatePermissions')
              .call({'affectedUser': widget.user.uid, 'permissions': update});
        if (childrenUsers != null) {
          final batch = firestore.batch();
          final oldChildren = (await firestore
                  .collection('Users')
                  .where('allowedUsers', arrayContains: widget.user.uid)
                  .get())
              .docs
              .map(User.fromQueryDoc)
              .toList();
          for (final item in oldChildren) {
            if (!childrenUsers!.contains(item)) {
              batch.update(item.ref, {
                'allowedUsers': FieldValue.arrayRemove([widget.user.uid]),
              });
            }
          }
          for (final item in childrenUsers!) {
            if (!oldChildren.contains(item)) {
              batch.update(item.ref, {
                'allowedUsers': FieldValue.arrayUnion([widget.user.uid]),
              });
            }
          }
          await batch.commit();
        }
        scaffoldMessenger.currentState!.hideCurrentSnackBar();
        navigator.currentState!.pop(widget.user.uid);
      }
    } catch (err, stkTrace) {
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'UserPState.save');
      await FirebaseCrashlytics.instance.setCustomKey('User', widget.user.uid!);
      await FirebaseCrashlytics.instance.recordError(err, stkTrace);
      scaffoldMessenger.currentState!.hideCurrentSnackBar();
      scaffoldMessenger.currentState!.showSnackBar(
        SnackBar(
          content: Text(
            err.toString(),
          ),
          duration: const Duration(seconds: 7),
        ),
      );
    }
  }

  Future _selectPerson() async {
    final BehaviorSubject<OrderOptions> _orderOptions =
        BehaviorSubject<OrderOptions>.seeded(const OrderOptions());

    await showDialog(
      context: context,
      builder: (context) {
        final listOptions = DataObjectListController<Person>(
          tap: (value) {
            navigator.currentState!.pop();
            setState(() {
              widget.user.personRef = 'Persons/${value.id}';
            });
            FocusScope.of(context).nextFocus();
          },
          itemsStream: _orderOptions
              .switchMap(
                (value) => Person.getAllForUser(
                  orderBy: value.orderBy,
                  descending: !value.asc,
                ),
              )
              .map((s) => s.docs.map(Person.fromQueryDoc).toList()),
        );
        return Dialog(
          child: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                navigator.currentState!.pop();
                widget.user.personRef = (await navigator.currentState!
                            .pushNamed('Data/EditPerson') as JsonRef?)
                        ?.path ??
                    widget.user.personRef;
                setState(() {});
              },
              tooltip: 'إضافة شخص جديد',
              child: const Icon(Icons.person_add),
            ),
            body: SizedBox(
              width: MediaQuery.of(context).size.width - 55,
              height: MediaQuery.of(context).size.height - 110,
              child: Column(
                children: [
                  SearchFilters(
                    1,
                    options: listOptions,
                    orderOptions: BehaviorSubject<OrderOptions>.seeded(
                      const OrderOptions(),
                    ),
                    textStyle: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Expanded(
                    child: DataObjectList<Person>(
                      options: listOptions,
                      autoDisposeController: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    await _orderOptions.close();
  }

  Future<void> editChildrenUsers() async {
    childrenUsers = await navigator.currentState!.push(
      MaterialPageRoute(
        builder: (context) {
          return StreamBuilder<List<User>>(
            stream: firestore
                .collection('Users')
                .where('allowedUsers', arrayContains: widget.user.uid)
                .snapshots()
                .map((value) => value.docs.map(User.fromQueryDoc).toList()),
            builder: (c, users) => users.hasData
                ? MultiProvider(
                    providers: [
                      Provider<DataObjectListController<User>>(
                        create: (_) => DataObjectListController<User>(
                          selectionMode: true,
                          itemsStream: User.getAllForUser(),
                          selected: {
                            for (final item in users.data!) item.id: item,
                          },
                          itemBuilder:
                              (item, onLongPress, onTap, trailing, subtitle) =>
                                  DataObjectWidget(
                            item,
                            onLongPress: () {},
                            onTap: () {},
                            trailing: trailing,
                            showSubtitle: false,
                          ),
                        ),
                        dispose: (context, c) => c.dispose(),
                      ),
                    ],
                    builder: (context, child) => Scaffold(
                      persistentFooterButtons: [
                        TextButton(
                          onPressed: () {
                            navigator.currentState!.pop(
                              context
                                  .read<DataObjectListController<User>>()
                                  .selectedLatest
                                  ?.values
                                  .toList(),
                            );
                          },
                          child: const Text('تم'),
                        ),
                      ],
                      appBar: AppBar(
                        title: SearchField(
                          showSuffix: false,
                          searchStream: context
                              .read<DataObjectListController<User>>()
                              .searchQuery,
                          textStyle: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      body: const UsersList(
                        autoDisposeController: false,
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
