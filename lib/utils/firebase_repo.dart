import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;
FirebaseAuth firebaseAuth = FirebaseAuth.instance;
FirebaseDatabase firebaseDatabase = FirebaseDatabase.instance;
FirebaseFunctions firebaseFunctions = FirebaseFunctions.instance;
FirebaseStorage firebaseStorage = FirebaseStorage.instance;
FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
GoogleSignIn googleSignIn = GoogleSignIn();
RemoteConfig remoteConfig = RemoteConfig.instance;
