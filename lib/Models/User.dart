import 'dart:async';
import 'dart:ui';

import 'package:async/async.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:churchdata/models/super_classes.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_stream_notifiers/flutter_stream_notifiers.dart';
import 'package:hive/hive.dart';
import '../EncryptionKeys.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_database/firebase_database.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/globals.dart';
import 'person.dart';

class User extends DataObject
    with PhotoObject, ChangeNotifier, ChangeNotifierStream<User> {
  static final User instance = User._initInstance();

  Completer<bool> _initialized = Completer<bool>();
  Future<bool> get initialized => _initialized.future;

  String _uid;

  String get uid => _uid;

  set uid(String uid) {
    _uid = uid;
    if (!_initialized.isCompleted) _initialized.complete(uid != null);
  }

  String email;
  String password;

  String personRef;
  DocumentReference get personDocRef =>
      FirebaseFirestore.instance.doc(personRef);

  bool manageUsers;
  bool manageAllowedUsers;
  bool superAccess;
  bool exportAreas;
  bool write;
  List<String> allowedUsers = [];

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
  Future<void> dispose() async {
    await recordLastSeen();
    await Hive.close();
    await userTokenListener?.cancel();
    await connectionListener?.cancel();
    await authListener?.cancel();
    await super.dispose();
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
            manageAllowedUsers =
                idTokenClaims['manageAllowedUsers'].toString() == 'true';
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
            var idToken;
            if ((await Connectivity().checkConnectivity()) !=
                ConnectivityResult.none) {
              idToken = await user.getIdTokenResult();
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
            }
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
            idTokenClaims = idToken?.claims ??
                (kIsWeb
                    ? await Encryption.getUserData()
                    : await flutterSecureStorage.readAll());
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
          manageAllowedUsers =
              idTokenClaims['manageAllowedUsers'].toString() == 'true';
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
          if (!_initialized.isCompleted) _initialized.complete(false);
          _initialized = Completer<bool>();
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
    if (!_initialized.isCompleted) _initialized.complete(false);
    _initialized = Completer<bool>();
    uid = null;
    notifyListeners();
    await auth.FirebaseAuth.instance.signOut();
    await connectionListener?.cancel();
  }

  factory User(
      {String uid,
      String name,
      String password,
      bool manageUsers,
      bool manageAllowedUsers,
      bool superAccess,
      bool write,
      bool exportAreas,
      bool birthdayNotify,
      bool confessionsNotify,
      bool tanawolNotify,
      bool approveLocations,
      bool approved,
      String personRef,
      List<String> allowedUsers,
      String email}) {
    if (uid == null || uid == auth.FirebaseAuth.instance.currentUser.uid) {
      return instance;
    }
    return User._new(
        uid,
        name,
        password,
        manageUsers,
        manageAllowedUsers,
        superAccess,
        write,
        exportAreas,
        birthdayNotify,
        confessionsNotify,
        tanawolNotify,
        approveLocations,
        approved,
        personRef,
        allowedUsers,
        email: email);
  }

  User._new(
      this._uid,
      String name,
      this.password,
      this.manageUsers,
      bool manageAllowedUsers,
      this.superAccess,
      this.write,
      this.exportAreas,
      this.birthdayNotify,
      this.confessionsNotify,
      this.tanawolNotify,
      this.approveLocations,
      this.approved,
      this.personRef,
      List<String> allowedUsers,
      {this.email})
      : super(_uid, name, null) {
    hasPhoto = true;
    defaultIcon = Icons.account_circle;
    this.manageAllowedUsers = manageAllowedUsers ?? false;
    this.allowedUsers = allowedUsers ?? [];
  }

  User._initInstance()
      : allowedUsers = [],
        super(null, null, null) {
    hasPhoto = true;
    defaultIcon = Icons.account_circle;
    _initListeners();
  }

  User._createFromData(this._uid, Map<String, dynamic> data)
      : super.createFromData(data, _uid) {
    name = data['Name'] ?? data['name'];
    uid = data['uid'] ?? _uid;
    password = data['password'];
    manageUsers = data['manageUsers'];
    manageAllowedUsers = data['manageAllowedUsers'];
    allowedUsers = data['allowedUsers']?.cast<String>();
    superAccess = data['superAccess'];
    write = data['write'];
    exportAreas = data['exportAreas'];
    birthdayNotify = data['birthdayNotify'];
    confessionsNotify = data['confessionsNotify'];
    tanawolNotify = data['tanawolNotify'];
    approved = data['approved'];
    approveLocations = data['ApproveLocations'];
    email = data['email'];
    hasPhoto = true;
    defaultIcon = Icons.account_circle;
  }

  @override
  Color get color => Colors.transparent;

  @override
  int get hashCode => hashValues(
      uid,
      name,
      password,
      manageUsers,
      manageAllowedUsers,
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
    return other is User && other.uid == uid;
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
      if (manageAllowedUsers ?? false) permissions += 'تعديل مستخدمين محددين،';
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
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      height: 15,
                      width: 15,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white),
                        color: Colors.greenAccent,
                      ),
                    ),
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
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          height: 15,
                          width: 15,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white),
                            color: Colors.greenAccent,
                          ),
                        ),
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
        'manageAllowedUsers': manageAllowedUsers,
        'superAccess': superAccess ?? false,
        'write': write ?? false,
        'exportAreas': exportAreas ?? false,
        'approveLocations': approveLocations ?? false,
        'birthdayNotify': birthdayNotify ?? false,
        'confessionsNotify': confessionsNotify ?? false,
        'tanawolNotify': tanawolNotify ?? false,
        'approved': approved ?? false,
        'personRef': personRef,
        'allowedUsers': allowedUsers ?? [],
      };

  static User fromDoc(DocumentSnapshot data) =>
      User._createFromData(data.id, data.data());

  static Future<User> fromID(String uid) async {
    return (await User.getUsersForEdit()).singleWhere((u) => u.uid == uid);
  }

  static Future<List<User>> getAllUsers(List<String> users) async {
    return (await Future.wait(users.map((s) => FirebaseFirestore.instance
            .collection('Users')
            .doc(s)
            .get(dataSource))))
        .map(User.fromDoc)
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

  static Future<List<User>> getUsersForEdit() async {
    final users = {
      for (var u in (await User.getAllUsersLive()).docs)
        u.id: (u.data()['allowedUsers'] as List)?.cast<String>()
    };
    return (await FirebaseFunctions.instance.httpsCallable('getUsers').call())
        .data
        .map(
          (u) => User(
            uid: u['uid'],
            name: u['name'],
            password: u['password'],
            manageUsers: u['manageUsers'],
            manageAllowedUsers: u['manageAllowedUsers'],
            superAccess: u['superAccess'],
            write: u['write'],
            exportAreas: u['exportAreas'],
            birthdayNotify: u['birthdayNotify'],
            confessionsNotify: u['confessionsNotify'],
            tanawolNotify: u['tanawolNotify'],
            approveLocations: u['approveLocations'],
            approved: u['approved'],
            personRef: u['personRef'],
            allowedUsers: users[u['uid']],
            email: u['email'],
          ),
        )
        .toList()
        ?.cast<User>();
  }

  Future<Person> getPerson() async {
    if (personRef == null) return null;
    return Person.fromDoc(await personDocRef.get());
  }

  static Future<Person> getCurrentPerson() async {
    return await User.instance.getPerson() ?? Person();
  }

  Future<void> recordActive() async {
    if (uid == null) return;
    await FirebaseDatabase.instance
        .reference()
        .child('Users/$uid/lastSeen')
        .set('Active');
  }

  Future<void> recordLastSeen() async {
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

  static Future<List<User>> getAllSemiManagers() async {
    return (await getUsersForEdit())
        .where((u) => u.manageAllowedUsers == true)
        .toList();
  }

  static Future<String> onlyName(String id) async {
    return (await FirebaseFirestore.instance
            .collection('Users')
            .doc(id)
            .get(dataSource))
        .data()['Name'];
  }
}
