import 'dart:async';
import 'dart:ui';

import 'package:async/async.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:churchdata/Models/super_classes.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive/hive.dart';
import '../EncryptionKeys.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_database/firebase_database.dart'
    if (dart.library.io) 'package:firebase_database/firebase_database.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../Models.dart';
import '../utils/globals.dart';

class User extends DataObject with PhotoObject, ChangeNotifier {
  static final User _user = User.empty();

  String uid;

  String email;
  String password;

  String personRef;
  DocumentReference get personDocRef =>
      FirebaseFirestore.instance.doc(personRef);

  bool manageUsers;
  bool superAccess;
  bool exportAreas;
  bool write;

  bool birthdayNotify;
  bool confessionsNotify;
  bool tanawolNotify;

  bool approveLocations;
  bool approved;

  StreamSubscription userTokenListener;
  StreamSubscription connectionListener;
  StreamSubscription<auth.User> authListener;

  final AsyncCache<String> _photoUrlCache =
      AsyncCache<String>(Duration(days: 1));

  @override
  void dispose() {
    Hive.close();
    userTokenListener?.cancel();
    connectionListener?.cancel();
    authListener?.cancel();
    super.dispose();
  }

  void _initListeners() {
    authListener ??= auth.FirebaseAuth.instance.userChanges().listen(
      (user) async {
        if (user != null) {
          userTokenListener ??= FirebaseDatabase.instance
              .reference()
              .child('Users/${user.uid}/forceRefresh')
              .onValue
              .listen((e) async {
            if (user?.uid == null ||
                e.snapshot == null ||
                e.snapshot.value != true) return;

            Map<dynamic, dynamic> idTokenClaims;
            try {
              var idToken = await user.getIdTokenResult(true);
              if (kIsWeb)
                await Encryption.setUserData(idToken.claims);
              else {
                for (var item in idToken.claims.entries) {
                  await flutterSecureStorage.write(
                      key: item.key, value: item.value?.toString());
                }
              }
              await FirebaseDatabase.instance
                  .reference()
                  .child('Users/${user.uid}/forceRefresh')
                  .set(false);
              connectionListener ??= FirebaseDatabase.instance
                  .reference()
                  .child('.info/connected')
                  .onValue
                  .listen((snapshot) {
                if (snapshot.snapshot.value == true) {
                  FirebaseDatabase.instance
                      .reference()
                      .child('Users/${user.uid}/lastSeen')
                      .onDisconnect()
                      .set(ServerValue.timestamp);
                  FirebaseDatabase.instance
                      .reference()
                      .child('Users/${user.uid}/lastSeen')
                      .set('Active');
                }
              });
              idTokenClaims = idToken.claims;
            } on Exception {
              if (kIsWeb)
                idTokenClaims = await Encryption.getUserData();
              else
                idTokenClaims = await flutterSecureStorage.readAll();
              if (idTokenClaims?.isEmpty ?? true) rethrow;
            }
            uid = user.uid;
            name = user.displayName;
            password = idTokenClaims['password'];
            manageUsers = idTokenClaims['manageUsers'].toString() == 'true';
            superAccess = idTokenClaims['superAccess'].toString() == 'true';
            write = idTokenClaims['write'].toString() == 'true';
            exportAreas = idTokenClaims['exportAreas'].toString() == 'true';
            birthdayNotify =
                idTokenClaims['birthdayNotify'].toString() == 'true';
            confessionsNotify =
                idTokenClaims['confessionsNotify'].toString() == 'true';
            tanawolNotify = idTokenClaims['tanawolNotify'].toString() == 'true';
            approveLocations =
                idTokenClaims['approveLocations'].toString() == 'true';
            approved = idTokenClaims['approved'].toString() == 'true';
            personRef = idTokenClaims['personRef'];
            email = user.email;

            notifyListeners();
          });
          Map<dynamic, dynamic> idTokenClaims;
          try {
            var idToken = await user.getIdTokenResult();
            if (kIsWeb)
              await Encryption.setUserData(idToken.claims);
            else {
              for (var item in idToken.claims.entries) {
                await flutterSecureStorage.write(
                    key: item.key, value: item.value?.toString());
              }
            }
            await FirebaseDatabase.instance
                .reference()
                .child('Users/${user.uid}/forceRefresh')
                .set(false);
            connectionListener ??= FirebaseDatabase.instance
                .reference()
                .child('.info/connected')
                .onValue
                .listen((snapshot) {
              if (snapshot.snapshot.value == true) {
                FirebaseDatabase.instance
                    .reference()
                    .child('Users/${user.uid}/lastSeen')
                    .onDisconnect()
                    .set(ServerValue.timestamp);
                FirebaseDatabase.instance
                    .reference()
                    .child('Users/${user.uid}/lastSeen')
                    .set('Active');
              }
            });
            idTokenClaims = idToken.claims;
          } on Exception {
            if (kIsWeb)
              idTokenClaims = await Encryption.getUserData();
            else
              idTokenClaims = await flutterSecureStorage.readAll();
            if (idTokenClaims?.isEmpty ?? true) rethrow;
          }
          uid = user.uid;
          name = user.displayName;
          password = idTokenClaims['password'];
          manageUsers = idTokenClaims['manageUsers'].toString() == 'true';
          superAccess = idTokenClaims['superAccess'].toString() == 'true';
          write = idTokenClaims['write'].toString() == 'true';
          exportAreas = idTokenClaims['exportAreas'].toString() == 'true';
          birthdayNotify = idTokenClaims['birthdayNotify'].toString() == 'true';
          confessionsNotify =
              idTokenClaims['confessionsNotify'].toString() == 'true';
          tanawolNotify = idTokenClaims['tanawolNotify'].toString() == 'true';
          approveLocations =
              idTokenClaims['approveLocations'].toString() == 'true';
          approved = idTokenClaims['approved'].toString() == 'true';
          personRef = idTokenClaims['personRef'];
          email = user.email;
          notifyListeners();
        } else if (uid != null) {
          await userTokenListener?.cancel();
          uid = null;
          notifyListeners();
        }
      },
    );
  }

  Future<void> signOut() async {
    await recordLastSeen();
    await userTokenListener?.cancel();
    uid = null;
    await auth.FirebaseAuth.instance.signOut();
    await connectionListener?.cancel();
    notifyListeners();
  }

  factory User(
      {String uid,
      String name,
      String password,
      bool manageUsers,
      bool superAccess,
      bool write,
      bool exportAreas,
      bool birthdayNotify,
      bool confessionsNotify,
      bool tanawolNotify,
      bool approveLocations,
      bool approved,
      String personRef,
      String email}) {
    if (uid == null || uid == auth.FirebaseAuth.instance.currentUser.uid) {
      return _user;
    }
    return User._new(
        uid,
        name,
        password,
        manageUsers,
        superAccess,
        write,
        exportAreas,
        birthdayNotify,
        confessionsNotify,
        tanawolNotify,
        approveLocations,
        approved,
        personRef,
        email: email);
  }

  User._new(
      this.uid,
      String name,
      this.password,
      this.manageUsers,
      this.superAccess,
      this.write,
      this.exportAreas,
      this.birthdayNotify,
      this.confessionsNotify,
      this.tanawolNotify,
      this.approveLocations,
      this.approved,
      this.personRef,
      {this.email})
      : super(uid, name, null) {
    hasPhoto = true;
    defaultIcon = Icons.account_circle;
  }

  User.empty() : super(null, null, null) {
    hasPhoto = true;
    defaultIcon = Icons.account_circle;
    _initListeners();
  }

  User._createFromData(this.uid, Map<String, dynamic> data)
      : super.createFromData(data, uid) {
    name = data['Name'];
    hasPhoto = true;
    defaultIcon = Icons.account_circle;
    approveLocations = data['ApproveLocations'];
  }

  @override
  Color get color => Colors.transparent;

  @override
  int get hashCode => hashValues(
      uid,
      name,
      password,
      manageUsers,
      superAccess,
      write,
      exportAreas,
      birthdayNotify,
      confessionsNotify,
      tanawolNotify,
      approveLocations,
      approved,
      personRef,
      email);

  @override
  bool operator ==(other) {
    return other is User && other.hashCode == hashCode;
  }

  Map<String, bool> getNotificationsPermissions() => {
        'birthdayNotify': birthdayNotify ?? false,
        'confessionsNotify': confessionsNotify ?? false,
        'tanawolNotify': tanawolNotify ?? false,
      };

  String getPermissions() {
    if (approved ?? false) {
      String permissions = '';
      if (manageUsers ?? false) permissions += 'تعديل المستخدمين،';
      if (superAccess ?? false) permissions += 'رؤية جميع البيانات،';
      if (write ?? false) permissions += 'تعديل البيانات،';
      if (exportAreas ?? false) permissions += 'تصدير منطقة،';
      if (approveLocations ?? false) permissions += 'تأكيد المواقع،';
      if (birthdayNotify ?? false) permissions += 'اشعار أعياد الميلاد،';
      if (confessionsNotify ?? false) permissions += 'اشعار الاعتراف،';
      if (tanawolNotify ?? false) permissions += 'اشعار التناول،';
      return permissions;
    }
    return 'حساب غير منشط';
  }

  Widget getPhoto([bool showCircle = true, bool showActiveStatus = true]) {
    return AspectRatio(
      aspectRatio: 1,
      child: StreamBuilder(
        stream: FirebaseDatabase.instance
            .reference()
            .child('Users/$uid/lastSeen')
            .onValue,
        builder: (context, activity) {
          if (!hasPhoto)
            return Stack(
              children: [
                Positioned.fill(
                    child: Icon(Icons.account_circle,
                        size: MediaQuery.of(context).size.height / 16.56)),
                if (showActiveStatus &&
                    activity.data?.snapshot?.value == 'Active')
                  Align(
                    child: Container(
                      height: 15,
                      width: 15,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white),
                        color: Colors.greenAccent,
                      ),
                    ),
                    alignment: Alignment.bottomLeft,
                  ),
              ],
            );
          return StatefulBuilder(
            builder: (context, setState) => FutureBuilder<String>(
              future: _photoUrlCache.fetch(
                () async {
                  String cache = Hive.box<String>('PhotosURLsCache')
                      .get(photoRef.fullPath);

                  if (cache == null) {
                    String url = await photoRef
                        .getDownloadURL()
                        .catchError((onError) => '');
                    await Hive.box<String>('PhotosURLsCache')
                        .put(photoRef.fullPath, url);

                    return url;
                  }
                  void Function(String) _updateCache = (String cache) async {
                    String url = await photoRef
                        .getDownloadURL()
                        .catchError((onError) => '');
                    if (cache != url) {
                      await Hive.box<String>('PhotosURLsCache')
                          .put(photoRef.fullPath, url);
                      _photoUrlCache.invalidate();
                      setState(() {});
                    }
                  };
                  _updateCache(cache);
                  return cache;
                },
              ),
              builder: (context, photoUrl) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: photoUrl.hasData
                          ? showCircle
                              ? CircleAvatar(
                                  backgroundImage:
                                      CachedNetworkImageProvider(photoUrl.data),
                                )
                              : CachedNetworkImage(imageUrl: photoUrl.data)
                          : CircularProgressIndicator(),
                    ),
                    if (showActiveStatus &&
                        activity.data?.snapshot?.value == 'Active')
                      Align(
                        child: Container(
                          height: 15,
                          width: 15,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white),
                            color: Colors.greenAccent,
                          ),
                        ),
                        alignment: Alignment.bottomLeft,
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Future<String> getSecondLine() async => getPermissions();

  Map<String, dynamic> getUpdateMap() => {
        'name': name,
        'manageUsers': manageUsers ?? false,
        'superAccess': superAccess ?? false,
        'write': write ?? false,
        'exportAreas': exportAreas ?? false,
        'approveLocations': approveLocations ?? false,
        'birthdayNotify': birthdayNotify ?? false,
        'confessionsNotify': confessionsNotify ?? false,
        'tanawolNotify': tanawolNotify ?? false,
        'approved': approved ?? false,
        'personRef': personRef,
      };

  static User fromDocumentSnapshot(DocumentSnapshot data) =>
      User._createFromData(data.id, data.data());

  static Future<User> fromID(String uid) async {
    return (await User.getUsersForEdit()).singleWhere((u) => u.uid == uid);
  }

  static Future<List<User>> getAllUsers(List<String> users) async {
    return (await Future.wait(users.map((s) => FirebaseFirestore.instance
            .collection('Users')
            .doc(s)
            .get(dataSource))))
        .map((e) => User.fromDocumentSnapshot(e))
        .toList();
  }

  static Future<QuerySnapshot> getAllUsersLive(
      {bool onlyCanApproveLocations = false}) {
    if (onlyCanApproveLocations) {
      return FirebaseFirestore.instance
          .collection('Users')
          .orderBy('Name')
          .where('ApproveLocations', isEqualTo: true)
          .get(dataSource);
    }
    return FirebaseFirestore.instance
        .collection('Users')
        .orderBy('Name')
        .get(dataSource);
  }

  static Future<User> getCurrentUser(
      {bool checkForForceRefresh = true, bool fromCache = false}) async {
    auth.User currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser?.uid == null) return User.empty();
    Map<dynamic, dynamic> idTokenClaims;
    try {
      if (await Connectivity().checkConnectivity() != ConnectivityResult.none &&
          !fromCache) {
        var idToken = await currentUser.getIdTokenResult();
        if (!kIsWeb &&
            ((checkForForceRefresh &&
                    (await FirebaseDatabase.instance
                                .reference()
                                .child('Users/${currentUser.uid}/forceRefresh')
                                .once())
                            .value ==
                        true) ||
                (await flutterSecureStorage.readAll()).isEmpty)) {
          idToken = await currentUser.getIdTokenResult(true);
          for (var item in idToken.claims.entries) {
            await flutterSecureStorage.write(
              key: item.key,
              value: item.value.toString(),
            );
          }
          await FirebaseDatabase.instance
              .reference()
              .child('Users/${currentUser.uid}/forceRefresh')
              .set(false);
        } else if (kIsWeb &&
            ((checkForForceRefresh &&
                    (await FirebaseDatabase.instance
                                .reference()
                                .child('Users/${currentUser.uid}/forceRefresh')
                                .once())
                            .value ==
                        true) ||
                Encryption.getUserData() == null)) {
          idToken = await currentUser.getIdTokenResult(true);
          await Encryption.setUserData(idToken.claims);
          await FirebaseDatabase.instance
              .reference()
              .child('Users/${currentUser.uid}/forceRefresh')
              .set(false);
        }
        idTokenClaims = idToken.claims;
      } else {
        if (kIsWeb) {
          idTokenClaims = await Encryption.getUserData();
        } else {
          idTokenClaims = await flutterSecureStorage.readAll();
        }
        if (idTokenClaims?.isEmpty ?? true)
          throw Exception("Couldn't find User cache");
      }
    } on Exception {
      if (kIsWeb) {
        idTokenClaims = await Encryption.getUserData();
      } else {
        idTokenClaims = await flutterSecureStorage.readAll();
      }
      if (idTokenClaims?.isEmpty ?? true) rethrow;
    }
    _user
      ..uid = currentUser.uid
      ..name = currentUser.displayName
      ..password = idTokenClaims['password']
      ..manageUsers = idTokenClaims['manageUsers'].toString() == 'true'
      ..superAccess = idTokenClaims['superAccess'].toString() == 'true'
      ..write = idTokenClaims['write'].toString() == 'true'
      ..exportAreas = idTokenClaims['exportAreas'].toString() == 'true'
      ..birthdayNotify = idTokenClaims['birthdayNotify'].toString() == 'true'
      ..confessionsNotify =
          idTokenClaims['confessionsNotify'].toString() == 'true'
      ..tanawolNotify = idTokenClaims['tanawolNotify'].toString() == 'true'
      ..approveLocations =
          idTokenClaims['approveLocations'].toString() == 'true'
      ..approved = idTokenClaims['approved'].toString() == 'true'
      ..personRef = idTokenClaims['personRef']
      ..email = currentUser.email;
    _user.notifyListeners();
    return _user;
  }

  static Future<List<User>> getUsersForEdit() async {
    return (await FirebaseFunctions.instance.httpsCallable('getUsers').call())
        .data
        .map(
          (u) => User(
            uid: u['uid'],
            name: u['name'],
            password: u['password'],
            manageUsers: u['manageUsers'],
            superAccess: u['superAccess'],
            write: u['write'],
            exportAreas: u['exportAreas'],
            birthdayNotify: u['birthdayNotify'],
            confessionsNotify: u['confessionsNotify'],
            tanawolNotify: u['tanawolNotify'],
            approveLocations: u['approveLocations'],
            approved: u['approved'],
            personRef: u['personRef'],
            email: u['email'],
          ),
        )
        .toList()
        ?.cast<User>();
  }

  Future<Person> getPerson() async {
    if (personRef == null) return null;
    return Person.fromDocumentSnapshot(
      await personDocRef.get(),
    );
  }

  static Future<Person> getCurrentPerson() async {
    return await (await getCurrentUser()).getPerson() ?? Person();
  }

  void recordActive() async {
    if (uid == null) return;
    await FirebaseDatabase.instance
        .reference()
        .child('Users/$uid/lastSeen')
        .set('Active');
  }

  void recordLastSeen() async {
    if (uid == null) return;
    await FirebaseDatabase.instance
        .reference()
        .child('Users/$uid/lastSeen')
        .set(Timestamp.now().millisecondsSinceEpoch);
  }

  @override
  String get id => uid;

  Future<bool> userDataUpToDate() async {
    var userPerson = await getPerson();
    return userPerson != null &&
        (userPerson.lastTanawol != null &&
            userPerson.lastConfession != null &&
            ((userPerson.lastTanawol.millisecondsSinceEpoch + 2592000000) >=
                    DateTime.now().millisecondsSinceEpoch &&
                (userPerson.lastConfession.millisecondsSinceEpoch +
                        5184000000) >=
                    DateTime.now().millisecondsSinceEpoch));
  }

  void reloadImage() {
    _photoUrlCache.invalidate();
  }

  @override
  Map<String, dynamic> getExportMap() {
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> getHumanReadableMap() {
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> getMap() {
    return getUpdateMap();
  }

  @override
  DocumentReference get ref =>
      FirebaseFirestore.instance.collection('Users').doc(uid);

  @override
  Reference get photoRef =>
      FirebaseStorage.instance.ref().child('UsersPhotos/$uid');
}
