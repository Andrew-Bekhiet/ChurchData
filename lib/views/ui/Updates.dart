import 'dart:async';

import 'package:churchdata/views/utils/DataDialog.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart' hide User;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import '../../utils/globals.dart';

class Update extends StatefulWidget {
  Update({Key key}) : super(key: key);
  @override
  _UpdateState createState() => _UpdateState();
}

class UpdateHelper {
  static Future<RemoteConfig> setupRemoteConfig() async {
    try {
      remoteConfig = await RemoteConfig.instance;
      await remoteConfig.setDefaults(<String, dynamic>{
        'LatestVersion': (await PackageInfo.fromPlatform()).version,
        'LoadApp': 'false',
        'DownloadLink':
            'https://github.com/Andrew-Bekhiet/ChurchData/releases/download/v' +
                (await PackageInfo.fromPlatform()).version +
                '/ChurchData.apk',
      });
      await remoteConfig.fetch(
        expiration: const Duration(minutes: 2),
      );
      await remoteConfig.activateFetched();
      return remoteConfig;
      // ignore: empty_catches
    } catch (err) {}
    return remoteConfig;
  }
}

class Updates {
  static Future showUpdateDialog(BuildContext context,
      {bool canCancel = true}) async {
    Version latest = Version.parse(
      (await UpdateHelper.setupRemoteConfig()).getString('LatestVersion'),
    );
    if (latest > Version.parse((await PackageInfo.fromPlatform()).version)) {
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
                  child: Text(canCancel ? 'نعم' : 'تحديث'),
                  onPressed: () async {
                    if (await canLaunch(
                      (await UpdateHelper.setupRemoteConfig())
                          .getString('DownloadLink')
                          .replaceFirst('https://', 'https:'),
                    )) {
                      await launch(
                        (await UpdateHelper.setupRemoteConfig())
                            .getString('DownloadLink')
                            .replaceFirst('https://', 'https:'),
                      );
                    } else {
                      Navigator.of(context).pop();
                      await Clipboard.setData(ClipboardData(
                        text: (await UpdateHelper.setupRemoteConfig())
                            .getString('DownloadLink'),
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'حدث خطأ أثناء فتح رابط التحديث وتم نقله الى الحافظة'),
                        ),
                      );
                    }
                  }),
            ],
          );
        },
      );
    } else if ((latest >
        Version.parse((await PackageInfo.fromPlatform()).version))) {
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
                  child: Text(canCancel ? 'نعم' : 'تحديث'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    if (await canLaunch(
                      (await UpdateHelper.setupRemoteConfig())
                          .getString('DownloadLink')
                          .replaceFirst('https://', 'https:'),
                    )) {
                      await launch(
                        (await UpdateHelper.setupRemoteConfig())
                            .getString('DownloadLink')
                            .replaceFirst('https://', 'https:'),
                      );
                    } else {
                      Navigator.of(context).pop();
                      await Clipboard.setData(ClipboardData(
                        text: (await UpdateHelper.setupRemoteConfig())
                            .getString('DownloadLink'),
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'حدث خطأ أثناء فتح رابط التحديث وتم نقله الى الحافظة'),
                        ),
                      );
                    }
                  }),
              if (canCancel)
                TextButton(
                  child: Text('لا'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
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
                  FutureBuilder(
                    future: PackageInfo.fromPlatform(),
                    builder: (cont, data) {
                      if (data.hasData) {
                        return Text(data.data.version);
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
                  FutureBuilder<RemoteConfig>(
                    future: UpdateHelper.setupRemoteConfig(),
                    builder: (cont, data) {
                      if (data.hasData) {
                        return Text(
                          data.data.getString('LatestVersion'),
                        );
                      }
                      return CircularProgressIndicator();
                    },
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
