import 'dart:convert';

import 'package:churchdata/views/utils/DataDialog.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Models/Notification.dart' as n;
import '../../utils/globals.dart';

class NotificationsPage extends StatefulWidget {
  NotificationsPage({Key key}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الإشعارات'),
      ),
      body: FutureBuilder<SharedPreferences>(
        future: settingsInstance,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(
              child: CircularProgressIndicator(),
            );
          snapshot.data.getStringList('Notifications') ??
              snapshot.data.setStringList(
                'Notifications',
                [],
              );
          return ListView.builder(
              itemCount: snapshot.data.getStringList('Notifications').length,
              itemBuilder: (context, i) {
                return n.Notification.fromMessage(
                    jsonDecode(snapshot.data.getStringList('Notifications')[i])
                        as Map<String, dynamic>, () async {
                  if (await showDialog(
                        context: context,
                        builder: (context) => DataDialog(
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text('نعم'),
                            )
                          ],
                          content: Text('هل تريد حذف هذا الاشعار؟'),
                        ),
                      ) ==
                      true) {
                    await (await settingsInstance).setStringList(
                      'Notifications',
                      (await settingsInstance).getStringList('Notifications')
                        ..remove(
                            snapshot.data.getStringList('Notifications')[i]),
                    );
                    setState(() {});
                  }
                });
              });
        },
      ),
    );
  }
}
