import 'package:churchdata/models/list.dart';
import 'package:churchdata/models/list_options.dart';
import 'package:churchdata/models/mini_models.dart';
import 'package:churchdata/models/user.dart';
import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:flutter/material.dart';

class MiniModelList<T extends MiniModel> extends StatelessWidget {
  final String title;
  final JsonCollectionRef collection;
  final void Function()? add;
  final void Function(T)? modify;
  final T Function(JsonQueryDoc) transformer;

  const MiniModelList(
      {Key? key,
      required this.title,
      required this.collection,
      this.add,
      this.modify,
      required this.transformer})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: DataObjectList(
        options: DataObjectListOptions<T>(
          itemBuilder: (current, onLongPress, onTap, trailing, subtitle) =>
              ListTile(
            title: Text(current.name),
            onTap: () => onTap?.call(current),
          ),
          tap: modify ?? (item) => _defaultModify(context, item, false),
          itemsStream: collection.snapshots().map(
                (s) => s.docs.map(transformer).toList(),
              ),
        ),
        autoDisposeController: true,
      ),
      floatingActionButton: User.instance.write
          ? FloatingActionButton(
              onPressed: add ??
                  () async {
                    final name = TextEditingController();
                    await showDialog(
                      context: context,
                      builder: (context) => StatefulBuilder(
                        builder: (context, setState) {
                          return AlertDialog(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                TextField(
                                  decoration:
                                      InputDecoration(labelText: 'الاسم'),
                                  controller: name,
                                ),
                              ],
                            ),
                            actions: <Widget>[
                              TextButton.icon(
                                icon: Icon(Icons.save),
                                onPressed: () async {
                                  await collection.add(
                                    {
                                      'Name': name.text,
                                    },
                                  );
                                  navigator.currentState!.pop();
                                },
                                label: Text('حفظ'),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
              child: Icon(Icons.add),
            )
          : null,
    );
  }

  void _defaultModify(BuildContext context, T item, bool editMode) async {
    final name = TextEditingController(text: item.name);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actions: <Widget>[
          if (User.instance.write)
            TextButton.icon(
              icon: editMode ? Icon(Icons.save) : Icon(Icons.edit),
              onPressed: () async {
                if (editMode) {
                  await item.ref.update({'Name': name.text});
                }
                navigator.currentState!.pop();
                if (modify == null)
                  _defaultModify(context, item..name = name.text, !editMode);
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
                  builder: (context) => AlertDialog(
                    title: Text(item.name),
                    content: Text('هل أنت متأكد من حذف ${item.name}؟'),
                    actions: <Widget>[
                      TextButton.icon(
                        icon: Icon(Icons.delete),
                        style: TextButton.styleFrom(primary: Colors.red),
                        label: Text('نعم'),
                        onPressed: () async {
                          await item.ref.delete();
                          navigator.currentState!.pop();
                          navigator.currentState!.pop();
                        },
                      ),
                      TextButton(
                        onPressed: () {
                          navigator.currentState!.pop();
                        },
                        child: Text('تراجع'),
                      ),
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
              if (editMode)
                TextField(
                  controller: name,
                )
              else
                Padding(
                  padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
                  child: DefaultTextStyle(
                    style: Theme.of(context).dialogTheme.titleTextStyle ??
                        Theme.of(context).textTheme.headline6!,
                    child: Text(item.name),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
