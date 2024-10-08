import 'dart:async';

import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mini_models.dart';
import '../models/user.dart';
import 'mini_model_list.dart';

class ChurchesPage extends StatelessWidget {
  const ChurchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MiniModelList<Church>(
      title: 'الكنائس',
      collection: firestore.collection('Churches'),
      transformer: Church.fromQueryDoc,
      modify: (f) => churchTap(context, f, false),
      add: () => churchTap(context, Church.createNew(), true),
    );
  }
}

class FathersPage extends StatelessWidget {
  const FathersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MiniModelList<Father>(
      title: 'الأباء الكهنة',
      collection: firestore.collection('Fathers'),
      transformer: Father.fromQueryDoc,
      modify: (f) => fatherTap(context, f, false),
      add: () => fatherTap(context, Father.createNew(), true),
    );
  }
}

Future<void> churchTap(
  BuildContext context,
  Church church,
  bool editMode,
) async {
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      actions: <Widget>[
        if (context.watch<User>().write)
          TextButton.icon(
            icon: editMode ? const Icon(Icons.save) : const Icon(Icons.edit),
            onPressed: () async {
              if (editMode) {
                await firestore.collection('Churches').doc(church.id).set(
                      church.getMap(),
                    );
              }
              navigator.currentState!.pop();
              unawaited(churchTap(context, church, !editMode));
            },
            label: Text(editMode ? 'حفظ' : 'تعديل'),
          ),
        if (editMode)
          TextButton.icon(
            icon: const Icon(Icons.delete),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(church.name),
                  content: Text('هل أنت متأكد من حذف ${church.name}؟'),
                  actions: <Widget>[
                    TextButton.icon(
                      icon: const Icon(Icons.delete),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      label: const Text('نعم'),
                      onPressed: () async {
                        await firestore
                            .collection('Churches')
                            .doc(church.id)
                            .delete();
                        navigator.currentState!.pop();
                        navigator.currentState!.pop();
                      },
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
            },
            label: const Text('حذف'),
          ),
      ],
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (editMode)
              TextField(
                controller: TextEditingController(text: church.name),
                onChanged: (v) => church.name = v,
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
                child: Text(
                  church.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            Text(
              'العنوان:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (editMode)
              TextField(
                controller: TextEditingController(text: church.address),
                onChanged: (v) => church.address = v,
              )
            else if (church.address?.isNotEmpty ?? false)
              Text(church.address!),
            if (!editMode)
              Text(
                'الأباء بالكنيسة:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            if (!editMode)
              StreamBuilder<JsonQuery>(
                stream: church.getMembersLive(),
                builder: (con, data) {
                  if (data.hasData) {
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: data.data?.size ?? 0,
                      itemBuilder: (context, i) {
                        final Father current =
                            Father.fromQueryDoc(data.data!.docs[i]);
                        return Card(
                          child: ListTile(
                            onTap: () => fatherTap(context, current, false),
                            title: Text(current.name),
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    ),
  );
}

Future<void> fatherTap(
  BuildContext context,
  Father father,
  bool editMode,
) async {
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      actions: <Widget>[
        if (context.watch<User>().write)
          TextButton.icon(
            icon: editMode ? const Icon(Icons.save) : const Icon(Icons.edit),
            onPressed: () async {
              if (editMode) {
                await firestore.collection('Fathers').doc(father.id).set(
                      father.getMap(),
                    );
              }
              navigator.currentState!.pop();

              unawaited(fatherTap(context, father, !editMode));
            },
            label: Text(editMode ? 'حفظ' : 'تعديل'),
          ),
        if (editMode)
          TextButton.icon(
            icon: const Icon(Icons.delete),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(father.name),
                  content: Text('هل أنت متأكد من حذف ${father.name}؟'),
                  actions: <Widget>[
                    TextButton.icon(
                      icon: const Icon(Icons.delete),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      label: const Text('نعم'),
                      onPressed: () async {
                        await firestore
                            .collection('Fathers')
                            .doc(father.id)
                            .delete();
                        navigator.currentState!.pop();
                        navigator.currentState!.pop();
                      },
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
            },
            label: const Text('حذف'),
          ),
      ],
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (editMode)
              TextField(
                controller: TextEditingController(text: father.name),
                onChanged: (v) => father.name = v,
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
                child: Text(
                  father.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            Text(
              'داخل كنيسة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (editMode)
              FutureBuilder<JsonQuery>(
                future: Church.getAllForUser(),
                builder: (context, data) {
                  if (data.hasData) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: DropdownButtonFormField<JsonRef?>(
                        value: father.churchId,
                        items: data.data!.docs
                            .map(
                              (item) => DropdownMenuItem<JsonRef>(
                                value: item.reference,
                                child: Text(item.data()['Name']),
                              ),
                            )
                            .toList()
                          ..insert(
                            0,
                            const DropdownMenuItem(
                              child: Text(''),
                            ),
                          ),
                        onChanged: (value) {
                          father.churchId = value;
                        },
                        decoration: const InputDecoration(
                          labelText: 'الكنيسة',
                        ),
                      ),
                    );
                  } else
                    return const LinearProgressIndicator();
                },
              )
            else
              FutureBuilder<String?>(
                future: father.getChurchName(),
                builder: (con, name) {
                  if (name.hasData)
                    return Card(
                      child: ListTile(
                        title: Text(name.data!),
                        onTap: () async => churchTap(
                          context,
                          Church.fromDoc(
                            await father.churchId!.get(),
                          )!,
                          false,
                        ),
                      ),
                    );
                  else if (name.connectionState == ConnectionState.waiting)
                    return const LinearProgressIndicator();
                  return const Text('');
                },
              ),
          ],
        ),
      ),
    ),
  );
}
