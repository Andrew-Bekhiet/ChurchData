import 'package:churchdata/views/utils/DataDialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Models/MiniModels.dart';
import '../../Models/User.dart';
import 'MiniLists.dart';

class ChurchesPage extends StatefulWidget {
  ChurchesPage({Key key}) : super(key: key);
  @override
  _ChurchesPageState createState() => _ChurchesPageState();
}

class CollegesPage extends StatefulWidget {
  CollegesPage({Key key}) : super(key: key);
  @override
  _CollegesPageState createState() => _CollegesPageState();
}

class FathersPage extends StatefulWidget {
  FathersPage({Key key}) : super(key: key);
  @override
  _FathersPageState createState() => _FathersPageState();
}

class JobsPage extends StatefulWidget {
  JobsPage({Key key}) : super(key: key);
  @override
  _JobsPageState createState() => _JobsPageState();
}

class PersonTypesPage extends StatefulWidget {
  PersonTypesPage({Key key}) : super(key: key);
  @override
  _PersonTypesPageState createState() => _PersonTypesPageState();
}

class ServingTypesPage extends StatefulWidget {
  ServingTypesPage({Key key}) : super(key: key);
  @override
  _ServingTypesPageState createState() => _ServingTypesPageState();
}

class StudyYearsPage extends StatefulWidget {
  StudyYearsPage({Key key}) : super(key: key);
  @override
  _StudyYearsPageState createState() => _StudyYearsPageState();
}

class _ChurchesPageState extends State<ChurchesPage> {
  @override
  Widget build(BuildContext context) {
    return Selector<User, bool>(
      selector: (_, user) => user.write,
      builder: (context, write, _) => Scaffold(
        appBar: AppBar(
          title: Text('الكنائس'),
        ),
        floatingActionButton: write
            ? FloatingActionButton(
                onPressed: () {
                  churchTap(Church.createNew(), true);
                },
                child: Icon(Icons.add),
              )
            : null,
        body: ChurchesEditList(
          list: Church.getAllForUser(),
          tap: (_) => churchTap(_, false),
        ),
      ),
    );
  }

  void churchTap(Church church, bool editMode) async {
    TextStyle title = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).textTheme.headline6.color,
    );
    await showDialog(
      context: context,
      builder: (context) => DataDialog(
        actions: <Widget>[
          if (context.read<User>().write)
            TextButton.icon(
              icon: editMode ? Icon(Icons.save) : Icon(Icons.edit),
              onPressed: () async {
                if (editMode) {
                  await FirebaseFirestore.instance
                      .collection('Churches')
                      .doc(church.id)
                      .set(
                        church.getMap(),
                      );
                }
                Navigator.of(context).pop();
                setState(() {
                  churchTap(church, !editMode);
                });
              },
              label: Text(editMode ? 'حفظ' : 'تعديل'),
            ),
          if (editMode)
            TextButton.icon(
              icon: Icon(Icons.delete),
              style: TextButton.styleFrom(primary: Colors.red),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => DataDialog(
                    title: Text(church.name),
                    content: Text('هل أنت متأكد من حذف ${church.name}؟'),
                    actions: <Widget>[
                      TextButton.icon(
                          icon: Icon(Icons.delete),
                          style: TextButton.styleFrom(primary: Colors.red),
                          label: Text('نعم'),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('Churches')
                                .doc(church.id)
                                .delete();
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                            setState(() {
                              editMode = !editMode;
                            });
                          }),
                      TextButton(
                          child: Text('تراجع'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          }),
                    ],
                  ),
                );
              },
              label: Text('حذف'),
            ),
        ],
        content: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              editMode
                  ? TextField(
                      controller: TextEditingController(text: church.name),
                      onChanged: (v) => church.name = v,
                    )
                  : Padding(
                      padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
                      child: DefaultTextStyle(
                          child: Text(church.name),
                          style: Theme.of(context).dialogTheme.titleTextStyle ??
                              Theme.of(context).textTheme.headline6),
                    ),
              DefaultTextStyle(
                style: title,
                child: Text('العنوان:'),
              ),
              editMode
                  ? TextField(
                      controller: TextEditingController(text: church.address),
                      onChanged: (v) => church.address = v,
                    )
                  : Text(church.address),
              if (!editMode) Text('الأباء بالكنيسة:', style: title),
              if (!editMode)
                FutureBuilder(
                  future: church.getMembersLive(),
                  builder: (context, widgetListData) {
                    return widgetListData.connectionState !=
                            ConnectionState.done
                        ? Container()
                        : StreamBuilder<QuerySnapshot>(
                            stream: widgetListData.data,
                            builder: (con, data) {
                              if (data.hasData) {
                                return ListView.builder(
                                    physics: ClampingScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: data.data.size,
                                    itemBuilder: (context, i) {
                                      Father current =
                                          Father.fromDocumentSnapshot(
                                              data.data.docs[i]);
                                      return Card(
                                        child: ListTile(
                                          onTap: () =>
                                              fatherTap(current, false),
                                          title: Text(current.name),
                                        ),
                                      );
                                    });
                              } else {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                            },
                          );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void fatherTap(Father father, bool editMode) async {
    TextStyle title = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).textTheme.headline6.color,
    );
    await showDialog(
      context: context,
      builder: (context) => DataDialog(
        actions: <Widget>[
          if (context.read<User>().write)
            TextButton.icon(
              icon: editMode ? Icon(Icons.save) : Icon(Icons.edit),
              onPressed: () async {
                if (editMode) {
                  await FirebaseFirestore.instance
                      .collection('Fathers')
                      .doc(father.id)
                      .set(
                        father.getMap(),
                      );
                }
                Navigator.of(context).pop();
                setState(() {
                  fatherTap(father, !editMode);
                });
              },
              label: Text(editMode ? 'حفظ' : 'تعديل'),
            ),
          if (editMode)
            TextButton.icon(
              icon: Icon(Icons.delete),
              style: TextButton.styleFrom(primary: Colors.red),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => DataDialog(
                    title: Text(father.name),
                    content: Text('هل أنت متأكد من حذف ${father.name}؟'),
                    actions: <Widget>[
                      TextButton.icon(
                          icon: Icon(Icons.delete),
                          style: TextButton.styleFrom(primary: Colors.red),
                          label: Text('نعم'),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('Fathers')
                                .doc(father.id)
                                .delete();
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                            setState(() {
                              editMode = !editMode;
                            });
                          }),
                      TextButton(
                          child: Text('تراجع'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          }),
                    ],
                  ),
                );
              },
              label: Text('حذف'),
            ),
        ],
        content: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              editMode
                  ? TextField(
                      controller: TextEditingController(text: father.name),
                      onChanged: (v) => father.name = v,
                    )
                  : Padding(
                      padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
                      child: DefaultTextStyle(
                          child: Text(father.name),
                          style: Theme.of(context).dialogTheme.titleTextStyle ??
                              Theme.of(context).textTheme.headline6),
                    ),
              Text('داخل كنيسة', style: title),
              editMode
                  ? FutureBuilder<QuerySnapshot>(
                      future: Church.getAllForUser(),
                      builder: (context, data) {
                        if (data.hasData) {
                          return Container(
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: DropdownButtonFormField(
                              value: father.churchId?.path,
                              items: data.data.docs
                                  .map(
                                    (item) => DropdownMenuItem(
                                      child: Text(item.data()['Name']),
                                      value: item.reference.path,
                                    ),
                                  )
                                  .toList()
                                    ..insert(
                                      0,
                                      DropdownMenuItem(
                                        child: Text(''),
                                        value: null,
                                      ),
                                    ),
                              onChanged: (value) {
                                father.churchId =
                                    FirebaseFirestore.instance.doc(value);
                              },
                              decoration: InputDecoration(
                                labelText: 'الكنيسة',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor),
                                ),
                              ),
                            ),
                          );
                        } else
                          return LinearProgressIndicator();
                      },
                    )
                  : FutureBuilder(
                      future: father.getChurchName(),
                      builder: (con, name) {
                        return name.hasData
                            ? Card(
                                child: ListTile(
                                  title: Text(name.data),
                                  onTap: () async => churchTap(
                                      Church.fromDocumentSnapshot(
                                        await father.churchId.get(),
                                      ),
                                      false),
                                ),
                              )
                            : LinearProgressIndicator();
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollegesPageState extends State<CollegesPage> {
  @override
  Widget build(BuildContext context) {
    return Selector<User, bool>(
      selector: (_, user) => user.write,
      builder: (context, write, _) => Scaffold(
        appBar: AppBar(
          title: Text('الكليات'),
        ),
        floatingActionButton: write
            ? FloatingActionButton(
                onPressed: () {
                  collegeTap(College.createNew(), true);
                },
                child: Icon(Icons.add),
              )
            : null,
        body: CollegesEditList(
          list: College.getAllForUser(),
          tap: (_) => collegeTap(_, false),
        ),
      ),
    );
  }

  void collegeTap(College college, bool editMode) async {
    await showDialog(
      context: context,
      builder: (context) => DataDialog(
        actions: <Widget>[
          if (context.read<User>().write)
            TextButton.icon(
              icon: editMode ? Icon(Icons.save) : Icon(Icons.edit),
              onPressed: () async {
                if (editMode) {
                  await FirebaseFirestore.instance
                      .collection('Colleges')
                      .doc(college.id)
                      .set(
                        college.getMap(),
                      );
                }
                Navigator.of(context).pop();
                setState(() {
                  collegeTap(college, !editMode);
                });
              },
              label: Text(editMode ? 'حفظ' : 'تعديل'),
            ),
          if (editMode)
            TextButton.icon(
              icon: Icon(Icons.delete),
              style: TextButton.styleFrom(primary: Colors.red),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => DataDialog(
                    title: Text(college.name),
                    content: Text('هل أنت متأكد من حذف ${college.name}؟'),
                    actions: <Widget>[
                      TextButton.icon(
                          icon: Icon(Icons.delete),
                          style: TextButton.styleFrom(primary: Colors.red),
                          label: Text('نعم'),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('Colleges')
                                .doc(college.id)
                                .delete();
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                            setState(() {
                              editMode = !editMode;
                            });
                          }),
                      TextButton(
                          child: Text('تراجع'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          }),
                    ],
                  ),
                );
              },
              label: Text('حذف'),
            ),
        ],
        content: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              editMode
                  ? TextField(
                      controller: TextEditingController(text: college.name),
                      onChanged: (v) => college.name = v,
                    )
                  : Padding(
                      padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
                      child: DefaultTextStyle(
                          child: Text(college.name),
                          style: Theme.of(context).dialogTheme.titleTextStyle ??
                              Theme.of(context).textTheme.headline6),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FathersPageState extends State<FathersPage> {
  @override
  Widget build(BuildContext context) {
    return Selector<User, bool>(
      selector: (_, user) => user.write,
      builder: (context, write, _) => Scaffold(
        appBar: AppBar(
          title: Text('الأباء الكهنة'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            fatherTap(Father.createNew(), true);
          },
          child: Icon(Icons.add),
        ),
        body: write
            ? FathersEditList(
                list: Father.getAllForUser(),
                tap: (_) => fatherTap(_, false),
              )
            : null,
      ),
    );
  }

  void churchTap(Church church, bool editMode) async {
    TextStyle title = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).textTheme.headline6.color,
    );

    await showDialog(
      context: context,
      builder: (context) => DataDialog(
        actions: <Widget>[
          if (context.read<User>().write)
            TextButton.icon(
              icon: editMode ? Icon(Icons.save) : Icon(Icons.edit),
              onPressed: () async {
                if (editMode) {
                  await FirebaseFirestore.instance
                      .collection('Churches')
                      .doc(church.id)
                      .set(
                        church.getMap(),
                      );
                }
                Navigator.of(context).pop();
                setState(() {
                  churchTap(church, !editMode);
                });
              },
              label: Text(editMode ? 'حفظ' : 'تعديل'),
            ),
          if (editMode)
            TextButton.icon(
              icon: Icon(Icons.delete),
              style: TextButton.styleFrom(primary: Colors.red),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => DataDialog(
                    title: Text(church.name),
                    content: Text('هل أنت متأكد من حذف ${church.name}؟'),
                    actions: <Widget>[
                      TextButton.icon(
                          icon: Icon(Icons.delete),
                          style: TextButton.styleFrom(primary: Colors.red),
                          label: Text('نعم'),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('Churches')
                                .doc(church.id)
                                .delete();
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                            setState(() {
                              editMode = !editMode;
                            });
                          }),
                      TextButton(
                          child: Text('تراجع'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          }),
                    ],
                  ),
                );
              },
              label: Text('حذف'),
            )
        ],
        content: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              editMode
                  ? TextField(
                      controller: TextEditingController(text: church.name),
                      onChanged: (v) => church.name = v,
                    )
                  : Padding(
                      padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
                      child: DefaultTextStyle(
                          child: Text(church.name),
                          style: Theme.of(context).dialogTheme.titleTextStyle ??
                              Theme.of(context).textTheme.headline6),
                    ),
              DefaultTextStyle(
                style: title,
                child: Text('العنوان:'),
              ),
              editMode
                  ? TextField(
                      controller: TextEditingController(text: church.address),
                      onChanged: (v) => church.address = v,
                    )
                  : Text(church.address),
              if (!editMode) Text('الأباء بالكنيسة:', style: title),
              if (!editMode)
                FutureBuilder(
                  future: church.getMembersLive(),
                  builder: (context, widgetListData) {
                    return widgetListData.connectionState !=
                            ConnectionState.done
                        ? Container()
                        : StreamBuilder<QuerySnapshot>(
                            stream: widgetListData.data,
                            builder: (con, data) {
                              if (data.hasData) {
                                return ListView.builder(
                                    physics: ClampingScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: data.data.size,
                                    itemBuilder: (context, i) {
                                      Father current =
                                          Father.fromDocumentSnapshot(
                                              data.data.docs[i]);
                                      return Card(
                                        child: ListTile(
                                          onTap: () =>
                                              fatherTap(current, false),
                                          title: Text(current.name),
                                        ),
                                      );
                                    });
                              } else {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                            },
                          );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void fatherTap(Father father, bool editMode) async {
    await showDialog(
      context: context,
      builder: (context) => DataDialog(
        actions: <Widget>[
          if (context.read<User>().write)
            TextButton.icon(
              icon: editMode ? Icon(Icons.save) : Icon(Icons.edit),
              onPressed: () async {
                if (editMode) {
                  await FirebaseFirestore.instance
                      .collection('Fathers')
                      .doc(father.id)
                      .set(
                        father.getMap(),
                      );
                }
                Navigator.of(context).pop();
                setState(() {
                  fatherTap(father, !editMode);
                });
              },
              label: Text(editMode ? 'حفظ' : 'تعديل'),
            ),
          if (editMode)
            TextButton.icon(
              icon: Icon(Icons.delete),
              style: TextButton.styleFrom(primary: Colors.red),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => DataDialog(
                    title: Text(father.name),
                    content: Text('هل أنت متأكد من حذف ${father.name}؟'),
                    actions: <Widget>[
                      TextButton.icon(
                          icon: Icon(Icons.delete),
                          style: TextButton.styleFrom(primary: Colors.red),
                          label: Text('نعم'),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('Fathers')
                                .doc(father.id)
                                .delete();
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                            setState(() {
                              editMode = !editMode;
                            });
                          }),
                      TextButton(
                          child: Text('تراجع'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          }),
                    ],
                  ),
                );
              },
              label: Text('حذف'),
            ),
        ],
        content: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              editMode
                  ? TextField(
                      controller: TextEditingController(text: father.name),
                      onChanged: (v) => father.name = v,
                    )
                  : Padding(
                      padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
                      child: DefaultTextStyle(
                          child: Text(father.name),
                          style: Theme.of(context).dialogTheme.titleTextStyle ??
                              Theme.of(context).textTheme.headline6),
                    ),
              editMode
                  ? FutureBuilder<QuerySnapshot>(
                      future: Church.getAllForUser(),
                      builder: (context, data) {
                        if (data.hasData) {
                          return Container(
                            padding: EdgeInsets.symmetric(vertical: 4.0),
                            child: DropdownButtonFormField(
                              value: father.churchId?.path,
                              items: data.data.docs
                                  .map(
                                    (item) => DropdownMenuItem(
                                      child: Text(item.data()['Name']),
                                      value: item.reference.path,
                                    ),
                                  )
                                  .toList()
                                    ..insert(
                                      0,
                                      DropdownMenuItem(
                                        child: Text(''),
                                        value: null,
                                      ),
                                    ),
                              onChanged: (value) {
                                father.churchId =
                                    FirebaseFirestore.instance.doc(value);
                              },
                              decoration: InputDecoration(
                                labelText: 'الكنيسة',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor),
                                ),
                              ),
                            ),
                          );
                        } else
                          return LinearProgressIndicator();
                      },
                    )
                  : FutureBuilder(
                      future: father.getChurchName(),
                      builder: (con, name) {
                        return name.hasData
                            ? Card(
                                child: ListTile(
                                  title: Text(father.churchId == null
                                      ? 'غير موجودة'
                                      : name.data),
                                  onTap: father.churchId != null
                                      ? () async => churchTap(
                                          Church.fromDocumentSnapshot(
                                            await father.churchId.get(),
                                          ),
                                          false)
                                      : null,
                                ),
                              )
                            : LinearProgressIndicator();
                      }),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobsPageState extends State<JobsPage> {
  @override
  Widget build(BuildContext context) {
    return Selector<User, bool>(
      selector: (_, user) => user.write,
      builder: (context, write, _) => Scaffold(
        appBar: AppBar(
          title: Text('الوظائف'),
        ),
        floatingActionButton: write
            ? FloatingActionButton(
                onPressed: () {
                  jobTap(Job.createNew(), true);
                },
                child: Icon(Icons.add),
              )
            : null,
        body: JobsEditList(
          list: Job.getAllForUser(),
          tap: (_) => jobTap(_, false),
        ),
      ),
    );
  }

  void jobTap(Job job, bool editMode) async {
    await showDialog(
      context: context,
      builder: (context) => DataDialog(
        actions: <Widget>[
          if (context.read<User>().write)
            TextButton.icon(
              icon: editMode ? Icon(Icons.save) : Icon(Icons.edit),
              onPressed: () async {
                if (editMode) {
                  await FirebaseFirestore.instance
                      .collection('Jobs')
                      .doc(job.id)
                      .set(
                        job.getMap(),
                      );
                }
                Navigator.of(context).pop();
                setState(() {
                  jobTap(job, !editMode);
                });
              },
              label: Text(editMode ? 'حفظ' : 'تعديل'),
            ),
          if (editMode)
            TextButton.icon(
              icon: Icon(Icons.delete),
              style: TextButton.styleFrom(primary: Colors.red),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => DataDialog(
                    title: Text(job.name),
                    content: Text('هل أنت متأكد من حذف ${job.name}؟'),
                    actions: <Widget>[
                      TextButton.icon(
                          icon: Icon(Icons.delete),
                          style: TextButton.styleFrom(primary: Colors.red),
                          label: Text('نعم'),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('Jobs')
                                .doc(job.id)
                                .delete();
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                            setState(() {
                              editMode = !editMode;
                            });
                          }),
                      TextButton(
                          child: Text('تراجع'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          }),
                    ],
                  ),
                );
              },
              label: Text('حذف'),
            ),
        ],
        content: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              editMode
                  ? TextField(
                      controller: TextEditingController(text: job.name),
                      onChanged: (v) => job.name = v,
                    )
                  : Padding(
                      padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
                      child: DefaultTextStyle(
                          child: Text(job.name),
                          style: Theme.of(context).dialogTheme.titleTextStyle ??
                              Theme.of(context).textTheme.headline6),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonTypesPageState extends State<PersonTypesPage> {
  @override
  Widget build(BuildContext context) {
    return Selector<User, bool>(
      selector: (_, user) => user.write,
      builder: (context, write, _) => Scaffold(
        appBar: AppBar(
          title: Text('أنواع الأشخاص'),
        ),
        floatingActionButton: write
            ? FloatingActionButton(
                onPressed: () {
                  personTypeTap(PersonType.createNew(), true);
                },
                child: Icon(Icons.add),
              )
            : null,
        body: PersonTypesEditList(
          list: PersonType.getAllForUser(),
          tap: (_) => personTypeTap(_, false),
        ),
      ),
    );
  }

  void personTypeTap(PersonType type, bool editMode) async {
    await showDialog(
      context: context,
      builder: (context) => DataDialog(
        actions: <Widget>[
          if (context.read<User>().write)
            TextButton.icon(
              icon: editMode ? Icon(Icons.save) : Icon(Icons.edit),
              onPressed: () async {
                if (editMode) {
                  await type.ref.set(
                    type.getMap(),
                  );
                }
                Navigator.of(context).pop();
                setState(() {
                  personTypeTap(type, !editMode);
                });
              },
              label: Text(editMode ? 'حفظ' : 'تعديل'),
            ),
          if (editMode)
            TextButton.icon(
              icon: Icon(Icons.delete),
              style: TextButton.styleFrom(primary: Colors.red),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => DataDialog(
                    title: Text(type.name),
                    content: Text('هل أنت متأكد من حذف ${type.name}؟'),
                    actions: <Widget>[
                      TextButton.icon(
                          icon: Icon(Icons.delete),
                          style: TextButton.styleFrom(primary: Colors.red),
                          label: Text('نعم'),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('Types')
                                .doc(type.id)
                                .delete();
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                            setState(() {
                              editMode = !editMode;
                            });
                          }),
                      TextButton(
                          child: Text('تراجع'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          }),
                    ],
                  ),
                );
              },
              label: Text('حذف'),
            ),
        ],
        content: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              editMode
                  ? TextField(
                      controller: TextEditingController(text: type.name),
                      onChanged: (v) => type.name = v,
                    )
                  : Padding(
                      padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
                      child: DefaultTextStyle(
                          child: Text(type.name),
                          style: Theme.of(context).dialogTheme.titleTextStyle ??
                              Theme.of(context).textTheme.headline6),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServingTypesPageState extends State<ServingTypesPage> {
  @override
  Widget build(BuildContext context) {
    return Selector<User, bool>(
      selector: (_, user) => user.write,
      builder: (context, write, _) => Scaffold(
        appBar: AppBar(
          title: Text('أنواع الخدمة'),
        ),
        floatingActionButton: write
            ? FloatingActionButton(
                onPressed: () {
                  servingTypeTap(ServingType.createNew(), true);
                },
                child: Icon(Icons.add),
              )
            : null,
        body: ServingTypesEditList(
          list: ServingType.getAllForUser(),
          tap: (_) => servingTypeTap(_, false),
        ),
      ),
    );
  }

  void servingTypeTap(ServingType stype, bool editMode) async {
    await showDialog(
      context: context,
      builder: (context) => DataDialog(
        actions: <Widget>[
          if (context.read<User>().write)
            TextButton.icon(
              icon: editMode ? Icon(Icons.save) : Icon(Icons.edit),
              onPressed: () async {
                if (editMode) {
                  await FirebaseFirestore.instance
                      .collection('ServingTypes')
                      .doc(stype.id)
                      .set(
                        stype.getMap(),
                      );
                }
                Navigator.of(context).pop();
                setState(() {
                  servingTypeTap(stype, !editMode);
                });
              },
              label: Text(editMode ? 'حفظ' : 'تعديل'),
            ),
          if (editMode)
            TextButton.icon(
              icon: Icon(Icons.delete),
              style: TextButton.styleFrom(primary: Colors.red),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => DataDialog(
                    title: Text(stype.name),
                    content: Text('هل أنت متأكد من حذف ${stype.name}؟'),
                    actions: <Widget>[
                      TextButton.icon(
                          icon: Icon(Icons.delete),
                          style: TextButton.styleFrom(primary: Colors.red),
                          label: Text('نعم'),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('ServingTypes')
                                .doc(stype.id)
                                .delete();
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                            setState(() {
                              editMode = !editMode;
                            });
                          }),
                      TextButton(
                          child: Text('تراجع'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          }),
                    ],
                  ),
                );
              },
              label: Text('حذف'),
            ),
        ],
        content: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              editMode
                  ? TextField(
                      controller: TextEditingController(text: stype.name),
                      onChanged: (v) => stype.name = v,
                    )
                  : Padding(
                      padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
                      child: DefaultTextStyle(
                          child: Text(stype.name),
                          style: Theme.of(context).dialogTheme.titleTextStyle ??
                              Theme.of(context).textTheme.headline6),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudyYearsPageState extends State<StudyYearsPage> {
  @override
  Widget build(BuildContext context) {
    return Selector<User, bool>(
      selector: (_, user) => user.write,
      builder: (context, write, _) => Scaffold(
        appBar: AppBar(
          title: Text('السنوات الدراسية'),
        ),
        floatingActionButton: write
            ? FloatingActionButton(
                onPressed: () {
                  studyYearTap(StudyYear.createNew(), true);
                },
                child: Icon(Icons.add),
              )
            : null,
        body: StudyYearsEditList(
          list: StudyYear.getAllForUser(),
          tap: (_) => studyYearTap(_, false),
        ),
      ),
    );
  }

  void studyYearTap(StudyYear year, bool editMode) async {
    await showDialog(
      context: context,
      builder: (context) => DataDialog(
        actions: <Widget>[
          if (context.read<User>().write)
            TextButton.icon(
              icon: editMode ? Icon(Icons.save) : Icon(Icons.edit),
              onPressed: () async {
                if (editMode) {
                  await FirebaseFirestore.instance
                      .collection('StudyYears')
                      .doc(year.id)
                      .set(
                        year.getMap(),
                      );
                }
                Navigator.of(context).pop();
                setState(() {
                  studyYearTap(year, !editMode);
                });
              },
              label: Text(editMode ? 'حفظ' : 'تعديل'),
            ),
          if (editMode)
            TextButton.icon(
              icon: Icon(Icons.delete),
              style: TextButton.styleFrom(primary: Colors.red),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => DataDialog(
                    title: Text(year.name),
                    content: Text('هل أنت متأكد من حذف ${year.name}؟'),
                    actions: <Widget>[
                      TextButton.icon(
                          icon: Icon(Icons.delete),
                          style: TextButton.styleFrom(primary: Colors.red),
                          label: Text('نعم'),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('StudyYears')
                                .doc(year.id)
                                .delete();
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                            setState(() {
                              editMode = !editMode;
                            });
                          }),
                      TextButton(
                          child: Text('تراجع'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          }),
                    ],
                  ),
                );
              },
              label: Text('حذف'),
            ),
        ],
        content: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              editMode
                  ? TextField(
                      controller: TextEditingController(text: year.name),
                      onChanged: (v) => year.name = v,
                    )
                  : Padding(
                      padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
                      child: DefaultTextStyle(
                          child: Text(year.name),
                          style: Theme.of(context).dialogTheme.titleTextStyle ??
                              Theme.of(context).textTheme.headline6),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
