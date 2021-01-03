import 'package:churchdata/utils/Helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Loading extends StatelessWidget {
  final bool error;
  final String message;
  final bool showVersionInfo;
  const Loading(
      {this.error = false, this.message, this.showVersionInfo = false})
      : super(key: null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: !kIsWeb,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
                child: Image.asset('assets/Logo.png', fit: BoxFit.scaleDown),
                flex: 16),
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(error
                      ? 'لا يمكن تحميل البرنامج في الوقت الحالي'
                      : 'جار التحميل...'),
                  error
                      ? OutlinedButton.icon(
                          label: Text('اضغط لمزيد من المعلومات'),
                          icon: Icon(Icons.error),
                          onPressed: () {
                            if (message != 'Exception: Error Update User Data')
                              showErrorDialog(context, message);
                            else
                              showErrorUpdateDataDialog(context: context);
                          },
                        )
                      : CircularProgressIndicator(),
                ],
              ),
            ),
            if (showVersionInfo || error)
              Align(
                child: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, data) => data.hasData
                      ? Text('اصدار: ' + data.data.version,
                          style: Theme.of(context).textTheme.caption)
                      : Text(''),
                ),
                alignment: Alignment.bottomRight,
              ),
          ],
        ),
      ),
    );
  }
}
