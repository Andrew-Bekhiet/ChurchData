//
// Generated file. Do not edit.
//

// ignore_for_file: directives_ordering
// ignore_for_file: lines_longer_than_80_chars

import 'package:cloud_firestore_web/cloud_firestore_web.dart';
import 'package:cloud_functions_web/cloud_functions_web.dart';
import 'package:connectivity_plus_web/connectivity_plus_web.dart';
import 'package:device_info_plus_web/device_info_plus_web.dart';
import 'package:file_picker/_internal/file_picker_web.dart';
import 'package:firebase_analytics_web/firebase_analytics_web.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:firebase_database_web/firebase_database_web.dart';
import 'package:firebase_messaging_web/firebase_messaging_web.dart';
import 'package:firebase_remote_config_web/firebase_remote_config_web.dart';
import 'package:firebase_storage_web/firebase_storage_web.dart';
import 'package:flutter_secure_storage_web/flutter_secure_storage_web.dart';
import 'package:google_maps_flutter_web/google_maps_flutter_web.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:image_picker_for_web/image_picker_for_web.dart';
import 'package:location_web/location_web.dart';
import 'package:package_info_plus_web/package_info_plus_web.dart';
import 'package:share_plus_web/share_plus_web.dart';
import 'package:shared_preferences_web/shared_preferences_web.dart';
import 'package:url_launcher_web/url_launcher_web.dart';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

// ignore: public_member_api_docs
void registerPlugins(Registrar registrar) {
  FirebaseFirestoreWeb.registerWith(registrar);
  FirebaseFunctionsWeb.registerWith(registrar);
  ConnectivityPlusPlugin.registerWith(registrar);
  DeviceInfoPlusPlugin.registerWith(registrar);
  FilePickerWeb.registerWith(registrar);
  FirebaseAnalyticsWeb.registerWith(registrar);
  FirebaseAuthWeb.registerWith(registrar);
  FirebaseCoreWeb.registerWith(registrar);
  FirebaseDatabaseWeb.registerWith(registrar);
  FirebaseMessagingWeb.registerWith(registrar);
  FirebaseRemoteConfigWeb.registerWith(registrar);
  FirebaseStorageWeb.registerWith(registrar);
  FlutterSecureStorageWeb.registerWith(registrar);
  GoogleMapsPlugin.registerWith(registrar);
  GoogleSignInPlugin.registerWith(registrar);
  ImagePickerPlugin.registerWith(registrar);
  LocationWebPlugin.registerWith(registrar);
  PackageInfoPlugin.registerWith(registrar);
  SharePlusPlugin.registerWith(registrar);
  SharedPreferencesPlugin.registerWith(registrar);
  UrlLauncherPlugin.registerWith(registrar);
  registrar.registerMessageHandler();
}
