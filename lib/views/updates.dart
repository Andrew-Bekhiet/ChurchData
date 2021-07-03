import 'dart:async';
import 'package:churchdata/models/data_dialog.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart' hide User;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import '../utils/globals.dart';

class Update extends StatefulWidget {
  Update({Key? key}) : super(key: key);
  @override
  _UpdateState createState() => _UpdateState();
}

class Updates {
  static Future showUpdateDialog(BuildContext context,
      {bool canCancel = true}) async {
    Version latest = Version.parse(
      RemoteConfig.instance.getString('LatestVersion'),
    );
    if (latest > Version.parse((await PackageInfo.fromPlatform()).version) &&
        canCancel) {
      await showDialog(
        barrierDismissible: canCancel,
        context: context,
        builder: (context) {
          return DataDialog(
            content: Text(canCancel
                ? 'هل تريد التحديث إلى إصدار $latest؟'
                : 'للأسف فإصدار البرنامج الحالي غير مدعوم\nيرجى تحديث البرنامج'),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  if (await canLaunch(
                    RemoteConfig.instance
                        .getString('DownloadLink')
                        .replaceFirst('https://', 'https:'),
                  )) {
                    await launch(
                      RemoteConfig.instance
                          .getString('DownloadLink')
                          .replaceFirst('https://', 'https:'),
                    );
                  } else {
                    navigator.currentState!.pop();
                    await Clipboard.setData(ClipboardData(
                      text: RemoteConfig.instance.getString('DownloadLink'),
                    ));
                    scaffoldMessenger.currentState!.showSnackBar(
                      SnackBar(
                        content: Text(
                            'حدث خطأ أثناء فتح رابط التحديث وتم نقله الى الحافظة'),
                      ),
                    );
                  }
                },
                child: Text(canCancel ? 'نعم' : 'تحديث'),
              ),
            ],
          );
        },
      );
    } else if (latest >
        Version.parse((await PackageInfo.fromPlatform()).version)) {
      await showDialog(
        barrierDismissible: canCancel,
        context: context,
        builder: (context) {
          return DataDialog(
            title: Text(''),
            content: Text(canCancel
                ? 'هل تريد التحديث إلى إصدار $latest؟'
                : 'للأسف فإصدار البرنامج الحالي غير مدعوم\nيرجى تحديث البرنامج'),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  navigator.currentState!.pop();
                  if (await canLaunch(
                    RemoteConfig.instance
                        .getString('DownloadLink')
                        .replaceFirst('https://', 'https:'),
                  )) {
                    await launch(
                      RemoteConfig.instance
                          .getString('DownloadLink')
                          .replaceFirst('https://', 'https:'),
                    );
                  } else {
                    navigator.currentState!.pop();
                    await Clipboard.setData(ClipboardData(
                      text: RemoteConfig.instance.getString('DownloadLink'),
                    ));
                    scaffoldMessenger.currentState!.showSnackBar(
                      SnackBar(
                        content: Text(
                            'حدث خطأ أثناء فتح رابط التحديث وتم نقله الى الحافظة'),
                      ),
                    );
                  }
                },
                child: Text(canCancel ? 'نعم' : 'تحديث'),
              ),
              if (canCancel)
                TextButton(
                  onPressed: () {
                    navigator.currentState!.pop();
                  },
                  child: Text('لا'),
                ),
            ],
          );
        },
      );
    }
  }
}

class _UpdateState extends State<Update> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('التحقق من التحديثات'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text('الإصدار الحالي:',
                      style: Theme.of(context).textTheme.bodyText2),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (cont, data) {
                      if (data.hasData) {
                        return Text(data.data!.version);
                      }
                      return CircularProgressIndicator();
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text('آخر إصدار:',
                      style: Theme.of(context).textTheme.bodyText2),
                  Text(
                    RemoteConfig.instance.getString('LatestVersion'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Updates.showUpdateDialog(context);
  }
}
