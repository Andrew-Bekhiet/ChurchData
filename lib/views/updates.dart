import 'dart:async';

import 'package:churchdata/utils/firebase_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import '../utils/globals.dart';

class Update extends StatefulWidget {
  const Update({Key? key}) : super(key: key);

  @override
  _UpdateState createState() => _UpdateState();
}

class Updates {
  static Future showUpdateDialog(BuildContext context,
      {bool canCancel = true}) async {
    final Version latest =
        Version.parse(remoteConfig.getString('LatestVersion'));
    if (latest > Version.parse((await PackageInfo.fromPlatform()).version)) {
      await showDialog(
        barrierDismissible: canCancel,
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text(canCancel
                ? 'هل تريد التحديث إلى إصدار $latest؟'
                : 'للأسف فإصدار البرنامج الحالي غير مدعوم\nيرجى تحديث البرنامج'),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  navigator.currentState!.pop();
                  if (await canLaunch(remoteConfig
                      .getString('DownloadLink')
                      .replaceFirst('https://', 'https:'))) {
                    await launch(remoteConfig
                        .getString('DownloadLink')
                        .replaceFirst('https://', 'https:'));
                  } else {
                    navigator.currentState!.pop();
                    await Clipboard.setData(ClipboardData(
                        text: remoteConfig.getString('DownloadLink')));
                    scaffoldMessenger.currentState!.showSnackBar(
                      const SnackBar(
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
                  child: const Text('لا'),
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
  void initState() {
    super.initState();
    Updates.showUpdateDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التحقق من التحديثات'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ListTile(
                title: const Text('الإصدار الحالي:'),
                subtitle: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (cont, data) {
                    if (data.hasData) {
                      return Text(data.data!.version);
                    }
                    return const LinearProgressIndicator();
                  },
                ),
              ),
              ListTile(
                title: const Text('أخر إصدار:'),
                subtitle: Text(remoteConfig.getString('LatestVersion')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
