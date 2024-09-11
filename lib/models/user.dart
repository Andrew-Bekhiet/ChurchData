// ignore_for_file:

import 'dart:async';

import 'package:async/async.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:churchdata/models/super_classes.dart';
import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hive/hive.dart';
import 'package:rxdart/rxdart.dart';

import 'person.dart';

class User extends DataObject with PhotoObject {
  static final User instance = User._initInstance();

  Completer<bool> _initialized = Completer<bool>();
  Future<bool> get initialized => _initialized.future;

  Stream<User> get stream => _stream.stream;
  final _stream = BehaviorSubject<User>();

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
      personRef != null ? firestore.doc(personRef!) : null;

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
      AsyncCache<String>(const Duration(days: 1));

  Future<void> dispose() async {
    await recordLastSeen();
    await Hive.close();
    await userTokenListener?.cancel();
    await connectionListener?.cancel();
    await authListener?.cancel();
    await _stream.close();
  }

  void _initListeners() {
    if (Hive.box('User').toMap().isNotEmpty &&
        Hive.box('User').get('name') != null &&
        Hive.box('User').get('email') != null &&
        Hive.box('User').get('sub') != null) {
      _refreshFromIdToken(
        Hive.box('User').toMap(),
        name: Hive.box('User').get('name'),
        email: Hive.box('User').get('email'),
        uid: Hive.box('User').get('sub'),
      );
    }

    authListener = firebaseAuth.userChanges().listen(
      (user) async {
        if (user != null) {
          userTokenListener = firebaseDatabase
              .ref()
              .child('Users/${user.uid}/forceRefresh')
              .onValue
              .listen((e) async {
            if (e.snapshot.value != true) return;

            Map idTokenClaims;
            try {
              final idToken = await user.getIdTokenResult(true);

              await Hive.box('User').putAll(
                (idToken.claims ?? {}).cast<String, dynamic>(),
              );

              await firebaseDatabase
                  .ref()
                  .child('Users/${user.uid}/forceRefresh')
                  .set(false);

              idTokenClaims = idToken.claims ?? {};
            } on Exception {
              idTokenClaims = Hive.box('User').toMap();
              if (idTokenClaims.isEmpty) rethrow;
            }

            _refreshFromIdToken(idTokenClaims, user: user);
          });

          Map idTokenClaims;
          try {
            late auth.IdTokenResult idToken;
            idToken = await user.getIdTokenResult();

            await Hive.box('User').putAll(
              (idToken.claims ?? {}).cast<String, dynamic>(),
            );

            await firebaseDatabase
                .ref()
                .child('Users/${user.uid}/forceRefresh')
                .set(false);

            idTokenClaims = idToken.claims ?? Hive.box('User').toMap();
          } on Exception {
            idTokenClaims = Hive.box('User').toMap();
            if (idTokenClaims.isEmpty) rethrow;
          }

          _refreshFromIdToken(idTokenClaims, user: user);
        } else if (uid != null) {
          if (!_initialized.isCompleted) _initialized.complete(false);
          _initialized = Completer<bool>();
          await userTokenListener?.cancel();
          _uid = null;
          notifyListeners();
        }
      },
    );
  }

  Future<void> forceRefresh() async {
    late Map idTokenClaims;
    try {
      final auth.IdTokenResult idToken =
          await firebaseAuth.currentUser!.getIdTokenResult(true);

      await Hive.box('User').putAll(
        (idToken.claims ?? {}).cast<String, dynamic>(),
      );

      idTokenClaims = idToken.claims ?? Hive.box('User').toMap();
    } on Exception {
      idTokenClaims = Hive.box('User').toMap();
      if (idTokenClaims.isEmpty) rethrow;
    }
    _refreshFromIdToken(idTokenClaims, user: firebaseAuth.currentUser);
  }

  void _refreshFromIdToken(Map<dynamic, dynamic> idTokenClaims,
      {auth.User? user, String? name, String? uid, String? email}) {
    assert(user != null || (name != null && uid != null && email != null));
    this.uid = user?.uid ?? uid!;
    this.name = user?.displayName ?? name ?? '';

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
    this.email = user?.email ?? email!;

    connectionListener ??= firebaseDatabase
        .ref()
        .child('.info/connected')
        .onValue
        .listen((snapshot) {
      if (snapshot.snapshot.value == true &&
          (mainScfld.currentState?.mounted ?? false)) {
        FirebaseDatabase.instance
            .ref()
            .child('Users/${this.uid}/lastSeen')
            .onDisconnect()
            .set(ServerValue.timestamp);

        FirebaseFirestore.instance.enableNetwork();

        FirebaseDatabase.instance
            .ref()
            .child('Users/${this.uid}/lastSeen')
            .set('Active');

        if (scaffoldMessenger.currentState?.mounted ?? false)
          scaffoldMessenger.currentState!.showSnackBar(
            const SnackBar(
              backgroundColor: Colors.greenAccent,
              content: Text('تم استرجاع الاتصال بالانترنت'),
            ),
          );
      } else if (mainScfld.currentState?.mounted ?? false) {
        if (!_stream.hasValue) _stream.add(this);

        FirebaseFirestore.instance.disableNetwork();

        scaffoldMessenger.currentState!.showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('لا يوجد اتصال بالانترنت!'),
          ),
        );
      }
    });

    notifyListeners();
  }

  Future<void> signOut() async {
    await recordLastSeen();
    await userTokenListener?.cancel();
    if (!_initialized.isCompleted) _initialized.complete(false);
    _initialized = Completer<bool>();
    _uid = null;
    notifyListeners();
    await googleSignIn.signOut();
    await firebaseAuth.signOut();
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
    if (uid == null || uid == firebaseAuth.currentUser!.uid) {
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
        super(ref ?? firestore.collection('Users').doc(id ?? 'null'), name,
            null) {
    defaultIcon = Icons.account_circle;
    this.allowedUsers = allowedUsers ?? [];
  }

  User._initInstance()
      : allowedUsers = [],
        super(firestore.collection('Users').doc('null'), '', null) {
    hasPhoto = true;
    defaultIcon = Icons.account_circle;
    _initListeners();
  }

  User._createFromData(this._uid, Json data)
      : super.createFromData(data, firestore.collection('Users').doc(_uid)) {
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
      child: StreamBuilder<DatabaseEvent>(
        stream: firebaseDatabase.ref().child('Users/$uid/lastSeen').onValue,
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
                  final String? cache = Hive.box<String?>('PhotosURLsCache')
                      .get(photoRef.fullPath);

                  if (cache == null) {
                    final String url = await photoRef
                        .getDownloadURL()
                        .catchError((onError) => '');
                    await Hive.box<String?>('PhotosURLsCache')
                        .put(photoRef.fullPath, url);

                    return url;
                  }

                  void _updateCache(String cache) async {
                    String? url;
                    try {
                      url = await photoRef.getDownloadURL();
                    } catch (e) {
                      url = null;
                    }
                    if (cache != url) {
                      await Hive.box<String?>('PhotosURLsCache')
                          .put(photoRef.fullPath, url);
                      await DefaultCacheManager().removeFile(cache);
                      _photoUrlCache.invalidate();

                      setState(() {});
                    }
                  }

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
    return (await Future.wait(
            users.map((s) => firestore.collection('Users').doc(s).get())))
        .map(User.fromDoc)
        .toList();
  }

  static Future<JsonQuery> getAllUsersLive(
      {bool onlyCanApproveLocations = false}) {
    if (onlyCanApproveLocations) {
      return firestore
          .collection('Users')
          .orderBy('Name')
          .where('ApproveLocations', isEqualTo: true)
          .get();
    }
    return firestore.collection('Users').orderBy('Name').get();
  }

  static Future<List<User>> getUsersForEdit() async {
    final users = {
      for (final u in (await User.getAllUsersLive()).docs)
        u.id: (u.data()['allowedUsers'] as List?)?.cast<String>()
    };
    return (await firebaseFunctions.httpsCallable('getUsers').call())
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
    return Person.fromDoc(await personDocRef!.get());
  }

  static Future<Person?> getCurrentPerson() async {
    return User.instance.getPerson();
  }

  Future<void> recordActive() async {
    if (uid == null) return;
    await firebaseDatabase.ref().child('Users/$uid/lastSeen').set('Active');
  }

  Future<void> recordLastSeen() async {
    if (uid == null) return;
    await firebaseDatabase
        .ref()
        .child('Users/$uid/lastSeen')
        .set(Timestamp.now().millisecondsSinceEpoch);
  }

  @override
  String get id => uid!;

  Future<bool> userDataUpToDate() async {
    final userPerson = await getPerson();
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
  Reference get photoRef => firebaseStorage.ref().child('UsersPhotos/$uid');

  static Future<List<User>> getAllSemiManagers() async {
    return (await getUsersForEdit())
        .where((u) => u.manageAllowedUsers == true)
        .toList();
  }

  static Future<String?> onlyName(String id) async {
    return (await firestore.collection('Users').doc(id).get()).data()?['Name'];
  }

  void notifyListeners() {
    _stream.add(this);
  }

  @override
  User copyWith() {
    throw UnimplementedError();
  }

  static Widget photoFromUID(String uid, {bool removeHero = false}) =>
      PhotoWidget(firebaseStorage.ref().child('UsersPhotos/$uid'),
              defaultIcon: Icons.account_circle)
          .photo(removeHero: removeHero);

  static Stream<List<User>> getAllForUser() {
    return firestore
        .collection('Users')
        .orderBy('Name')
        .snapshots()
        .map((u) => u.docs.map(fromQueryDoc).toList());
  }
}
