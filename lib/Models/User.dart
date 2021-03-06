import 'dart:async';
import 'dart:ui';

import 'package:async/async.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:churchdata/models/super_classes.dart';
import 'package:churchdata/typedefs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_database/firebase_database.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:rxdart/rxdart.dart';

import '../EncryptionKeys.dart';
import '../utils/globals.dart';
import 'person.dart';

class User extends DataObject with PhotoObject {
  static final User instance = User._initInstance();

  Completer<bool> _initialized = Completer<bool>();
  Future<bool> get initialized => _initialized.future;

  Stream<User> get stream => _streamSubject.stream;
  final _streamSubject = BehaviorSubject<User>();

  @override
  bool get hasPhoto => uid != null;

  @override
  set hasPhoto(bool? _) {}

  String? _uid;

  String? get uid => _uid;

  set uid(String? uid) {
    _uid = uid;
    if (!_initialized.isCompleted) _initialized.complete(uid != null);
  }

  late String email;
  String? password;

  String? personRef;
  JsonRef? get personDocRef =>
      personRef != null ? FirebaseFirestore.instance.doc(personRef!) : null;

  bool manageUsers = false;
  bool manageAllowedUsers = false;
  bool superAccess = false;
  bool manageDeleted = false;
  bool exportAreas = false;
  bool write = false;
  List<String> allowedUsers = [];

  bool birthdayNotify = false;
  bool confessionsNotify = false;
  bool tanawolNotify = false;

  bool approveLocations = false;
  bool approved = false;

  StreamSubscription? userTokenListener;
  StreamSubscription? connectionListener;
  StreamSubscription<auth.User?>? authListener;

  final AsyncCache<String> _photoUrlCache =
      AsyncCache<String>(Duration(days: 1));

  Future<void> dispose() async {
    await recordLastSeen();
    await Hive.close();
    await userTokenListener?.cancel();
    await connectionListener?.cancel();
    await authListener?.cancel();
    await _streamSubject.close();
  }

  void _initListeners() {
    authListener = auth.FirebaseAuth.instance.userChanges().listen(
      (user) async {
        if (user != null) {
          userTokenListener = FirebaseDatabase.instance
              .reference()
              .child('Users/${user.uid}/forceRefresh')
              .onValue
              .listen((e) async {
            if (e.snapshot.value != true) return;

            Json idTokenClaims;
            try {
              var idToken = await user.getIdTokenResult(true);
              if (kIsWeb)
                await Encryption.setUserData(idToken.claims!);
              else {
                for (var item in idToken.claims!.entries) {
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
              idTokenClaims = idToken.claims!;
            } on Exception {
              if (kIsWeb)
                idTokenClaims = await Encryption.getUserData() ?? {};
              else
                idTokenClaims = await flutterSecureStorage.readAll();
              if (idTokenClaims.isEmpty) rethrow;
            }

            _refreshFromIdToken(user, idTokenClaims);
          });

          Json idTokenClaims;
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
              idTokenClaims = await Encryption.getUserData() ?? {};
            else
              idTokenClaims = await flutterSecureStorage.readAll();
            if (idTokenClaims.isEmpty) rethrow;
          }

          _refreshFromIdToken(user, idTokenClaims);
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

  void _refreshFromIdToken(auth.User user, Json idTokenClaims) {
    uid = user.uid;
    name = user.displayName ?? '';
    password = idTokenClaims['password'];
    manageUsers = idTokenClaims['manageUsers'].toString() == 'true';
    manageAllowedUsers =
        idTokenClaims['manageAllowedUsers'].toString() == 'true';
    superAccess = idTokenClaims['superAccess'].toString() == 'true';
    manageDeleted = idTokenClaims['manageDeleted'].toString() == 'true';
    write = idTokenClaims['write'].toString() == 'true';
    exportAreas = idTokenClaims['exportAreas'].toString() == 'true';
    birthdayNotify = idTokenClaims['birthdayNotify'].toString() == 'true';
    confessionsNotify = idTokenClaims['confessionsNotify'].toString() == 'true';
    tanawolNotify = idTokenClaims['tanawolNotify'].toString() == 'true';
    approveLocations = idTokenClaims['approveLocations'].toString() == 'true';
    approved = idTokenClaims['approved'].toString() == 'true';
    personRef = idTokenClaims['personRef'];
    email = user.email!;

    notifyListeners();
  }

  Future<void> signOut() async {
    await recordLastSeen();
    await userTokenListener?.cancel();
    if (!_initialized.isCompleted) _initialized.complete(false);
    _initialized = Completer<bool>();
    uid = null;
    notifyListeners();
    await GoogleSignIn().signOut();
    await auth.FirebaseAuth.instance.signOut();
    await connectionListener?.cancel();
  }

  factory User(
      {JsonRef? ref,
      String? uid,
      required String name,
      String? password,
      bool manageUsers = false,
      bool manageDeleted = false,
      bool manageAllowedUsers = false,
      bool superAccess = false,
      bool write = false,
      bool exportAreas = false,
      bool birthdayNotify = false,
      bool confessionsNotify = false,
      bool tanawolNotify = false,
      bool approveLocations = false,
      bool approved = false,
      String? personRef,
      List<String>? allowedUsers,
      required String email}) {
    if (uid == null || uid == auth.FirebaseAuth.instance.currentUser!.uid) {
      return instance;
    }
    return User._new(
        uid: uid,
        name: name,
        password: password,
        manageUsers: manageUsers,
        manageAllowedUsers: manageAllowedUsers,
        superAccess: superAccess,
        manageDeleted: manageDeleted,
        write: write,
        exportAreas: exportAreas,
        birthdayNotify: birthdayNotify,
        confessionsNotify: confessionsNotify,
        tanawolNotify: tanawolNotify,
        approveLocations: approveLocations,
        approved: approved,
        personRef: personRef,
        allowedUsers: allowedUsers,
        email: email);
  }

  User._new(
      {String? uid,
      String? id,
      required String name,
      this.password,
      required this.manageUsers,
      required this.manageAllowedUsers,
      required this.superAccess,
      required this.manageDeleted,
      required this.write,
      required this.exportAreas,
      required this.birthdayNotify,
      required this.confessionsNotify,
      required this.tanawolNotify,
      required this.approveLocations,
      required this.approved,
      this.personRef,
      List<String>? allowedUsers,
      required this.email,
      JsonRef? ref})
      : _uid = uid,
        super(
            ref ??
                FirebaseFirestore.instance
                    .collection('Users')
                    .doc(id ?? 'null'),
            name,
            null) {
    defaultIcon = Icons.account_circle;
    this.allowedUsers = allowedUsers ?? [];
  }

  User._initInstance()
      : allowedUsers = [],
        super(FirebaseFirestore.instance.collection('Users').doc('null'), '',
            null) {
    hasPhoto = true;
    defaultIcon = Icons.account_circle;
    _initListeners();
  }

  User._createFromData(this._uid, Json data)
      : super.createFromData(
            data, FirebaseFirestore.instance.collection('Users').doc(_uid)) {
    name = data['Name'] ?? data['name'];
    uid = data['uid'] ?? _uid;
    password = data['password'];
    manageUsers = data['manageUsers']?.toString() == 'true';
    manageAllowedUsers = data['manageAllowedUsers']?.toString() == 'true';
    allowedUsers = data['allowedUsers']?.cast<String>() ?? [];
    manageDeleted = data['manageDeleted']?.toString() == 'true';
    superAccess = data['superAccess']?.toString() == 'true';
    write = data['write']?.toString() == 'true';
    exportAreas = data['exportAreas']?.toString() == 'true';
    birthdayNotify = data['birthdayNotify']?.toString() == 'true';
    confessionsNotify = data['confessionsNotify']?.toString() == 'true';
    tanawolNotify = data['tanawolNotify']?.toString() == 'true';
    approved = data['approved']?.toString() == 'true';
    approveLocations = data['approveLocations']?.toString() == 'true';
    email = data['email'] ?? '';
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
      manageDeleted,
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
        'birthdayNotify': birthdayNotify,
        'confessionsNotify': confessionsNotify,
        'tanawolNotify': tanawolNotify,
      };

  String getPermissions() {
    if (approved) {
      String permissions = '';
      if (manageUsers) permissions += 'تعديل المستخدمين،';
      if (manageAllowedUsers) permissions += 'تعديل مستخدمين محددين،';
      if (superAccess) permissions += 'رؤية جميع البيانات،';
      if (manageDeleted) permissions += 'استرجاع المحئوفات،';
      if (write) permissions += 'تعديل البيانات،';
      if (exportAreas) permissions += 'تصدير منطقة،';
      if (approveLocations) permissions += 'تأكيد المواقع،';
      if (birthdayNotify) permissions += 'اشعار أعياد الميلاد،';
      if (confessionsNotify) permissions += 'اشعار الاعتراف،';
      if (tanawolNotify) permissions += 'اشعار التناول،';
      return permissions;
    }
    return 'حساب غير منشط';
  }

  @override
  Widget photo({bool cropToCircle = true, bool removeHero = false}) =>
      getPhoto(cropToCircle);

  Widget getPhoto([bool showCircle = true, bool showActiveStatus = true]) {
    return AspectRatio(
      aspectRatio: 1,
      child: StreamBuilder<Event>(
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
                    activity.data?.snapshot.value == 'Active')
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
                  String? cache = Hive.box<String>('PhotosURLsCache')
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
                                  backgroundImage: CachedNetworkImageProvider(
                                      photoUrl.data!),
                                )
                              : CachedNetworkImage(imageUrl: photoUrl.data!)
                          : const CircularProgressIndicator(),
                    ),
                    if (showActiveStatus &&
                        activity.data?.snapshot.value == 'Active')
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

  Json getUpdateMap() => {
        'name': name,
        'manageUsers': manageUsers,
        'manageAllowedUsers': manageAllowedUsers,
        'superAccess': superAccess,
        'manageDeleted': manageDeleted,
        'write': write,
        'exportAreas': exportAreas,
        'approveLocations': approveLocations,
        'birthdayNotify': birthdayNotify,
        'confessionsNotify': confessionsNotify,
        'tanawolNotify': tanawolNotify,
        'approved': approved,
        'personRef': personRef,
        'allowedUsers': allowedUsers,
      };

  static User? fromDoc(JsonDoc data) =>
      data.exists ? User._createFromData(data.id, data.data()!) : null;

  static User fromQueryDoc(JsonQueryDoc data) => fromDoc(data)!;

  static Future<User> fromID(String uid) async {
    return (await User.getUsersForEdit()).singleWhere((u) => u.uid == uid);
  }

  static Future<List<User?>> getAllUsers(List<String> users) async {
    return (await Future.wait(users.map((s) => FirebaseFirestore.instance
            .collection('Users')
            .doc(s)
            .get(dataSource))))
        .map(User.fromDoc)
        .toList();
  }

  static Future<JsonQuery> getAllUsersLive(
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
        u.id: (u.data()['allowedUsers'] as List?)?.cast<String>()
    };
    return (await FirebaseFunctions.instance.httpsCallable('getUsers').call())
        .data
        .map(
          (u) => User(
            uid: u['uid'],
            name: u['name'],
            password: u['password'],
            manageUsers: u['manageUsers']?.toString() == 'true',
            manageAllowedUsers: u['manageAllowedUsers']?.toString() == 'true',
            superAccess: u['superAccess']?.toString() == 'true',
            manageDeleted: u['manageDeleted']?.toString() == 'true',
            write: u['write']?.toString() == 'true',
            exportAreas: u['exportAreas']?.toString() == 'true',
            birthdayNotify: u['birthdayNotify']?.toString() == 'true',
            confessionsNotify: u['confessionsNotify']?.toString() == 'true',
            tanawolNotify: u['tanawolNotify']?.toString() == 'true',
            approveLocations: u['approveLocations']?.toString() == 'true',
            approved: u['approved']?.toString() == 'true',
            personRef: u['personRef'],
            allowedUsers: users[u['uid']],
            email: u['email'] ?? '',
          ),
        )
        .toList()
        ?.cast<User>();
  }

  Future<Person?> getPerson() async {
    if (personRef == null) return null;
    return Person.fromDoc(await personDocRef!.get(dataSource));
  }

  static Future<Person?> getCurrentPerson() async {
    return User.instance.getPerson();
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
  String get id => uid!;

  Future<bool> userDataUpToDate() async {
    var userPerson = await getPerson();
    return userPerson != null &&
        userPerson.lastTanawol != null &&
        userPerson.lastConfession != null &&
        ((userPerson.lastTanawol!.millisecondsSinceEpoch + 2592000000) >=
                DateTime.now().millisecondsSinceEpoch &&
            (userPerson.lastConfession!.millisecondsSinceEpoch + 5184000000) >=
                DateTime.now().millisecondsSinceEpoch);
  }

  void reloadImage() {
    _photoUrlCache.invalidate();
  }

  @override
  Json getHumanReadableMap() {
    throw UnimplementedError();
  }

  @override
  Json getMap() {
    return getUpdateMap();
  }

  @override
  Reference get photoRef =>
      FirebaseStorage.instance.ref().child('UsersPhotos/$uid');

  static Future<List<User>> getAllSemiManagers() async {
    return (await getUsersForEdit())
        .where((u) => u.manageAllowedUsers == true)
        .toList();
  }

  static Future<String?> onlyName(String id) async {
    return (await FirebaseFirestore.instance
            .collection('Users')
            .doc(id)
            .get(dataSource))
        .data()?['Name'];
  }

  void notifyListeners() {
    _streamSubject.add(this);
  }

  @override
  User copyWith() {
    throw UnimplementedError();
  }

  static Widget photoFromUID(String uid, {bool removeHero = false}) =>
      PhotoWidget(FirebaseStorage.instance.ref().child('UsersPhotos/$uid'),
              defaultIcon: Icons.account_circle)
          .photo(removeHero: removeHero);

  static Stream<List<User>> getAllForUser() {
    return FirebaseFirestore.instance
        .collection('Users')
        .orderBy('Name')
        .snapshots()
        .map((u) => u.docs.map(fromQueryDoc).toList());
  }
}
