import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_auth_mocks/src/mock_confirmation_result.dart';
import 'package:firebase_auth_mocks/src/mock_user_credential.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';

class FakeFirebaseAuth implements auth.FirebaseAuth {
  final stateChanged = BehaviorSubject<auth.User?>.seeded(null);
  final MockUser? _mockUser;
  auth.User? _currentUser;

  FakeFirebaseAuth({signedIn = false, MockUser? mockUser})
      : _mockUser = mockUser {
    if (signedIn) {
      signInWithCredential(null);
    }
  }

  @override
  auth.User? get currentUser {
    return _currentUser;
  }

  @override
  Future<auth.UserCredential> signInWithCredential(
    auth.AuthCredential? credential,
  ) {
    return _fakeSignIn();
  }

  @override
  Future<auth.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _fakeSignIn();
  }

  @override
  Future<auth.UserCredential> signInWithCustomToken(String token) async {
    return _fakeSignIn();
  }

  @override
  Future<auth.ConfirmationResult> signInWithPhoneNumber(
    String phoneNumber, [
    auth.RecaptchaVerifier? verifier,
  ]) async {
    return MockConfirmationResult(onConfirm: _fakeSignIn);
  }

  @override
  Future<auth.UserCredential> signInAnonymously() {
    return _fakeSignIn(isAnonymous: true);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    stateChanged.add(null);
  }

  Future<auth.UserCredential> _fakeSignIn({bool isAnonymous = false}) async {
    final userCredential = MockUserCredential(isAnonymous, mockUser: _mockUser);
    _currentUser = userCredential.user;
    stateChanged.add(_currentUser);
    return userCredential;
  }

  @override
  Stream<auth.User?> authStateChanges() => stateChanged.shareValue();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  BehaviorSubject<auth.User?> changeIdToken =
      BehaviorSubject<auth.User?>.seeded(null);

  @override
  Stream<auth.User?> idTokenChanges() => changeIdToken.shareValue();

  @override
  Stream<auth.User?> userChanges() =>
      Rx.merge([authStateChanges(), idTokenChanges()]);

  Future<void> dipose() async {
    await changeIdToken.close();
    await stateChanged.close();
  }
}

class _FakeIdTokenResult extends Fake implements auth.IdTokenResult {}

class MyMockUser extends MockUser with Mock {
  MyMockUser({
    super.isAnonymous,
    super.isEmailVerified,
    String super.uid = 'some_random_id',
    super.email,
    super.displayName,
    super.phoneNumber,
    super.photoURL,
    super.refreshToken,
    super.metadata,
  });

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async {
    return (await getIdTokenResult(forceRefresh)).token!;
  }

  @override
  Future<auth.IdTokenResult> getIdTokenResult([bool forceRefresh = false]) {
    return super.noSuchMethod(
      Invocation.method(#getIdTokenResult, [forceRefresh]),
      returnValue: Future<auth.IdTokenResult>.value(_FakeIdTokenResult()),
    ) as Future<auth.IdTokenResult>;
  }
}

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  @visibleForTesting
  static Map<String, String> data = {};

  @override
  Future<String?> read({
    required String key,
    aOptions,
    iOptions,
    lOptions,
    mOptions,
    wOptions,
    webOptions,
  }) async =>
      data[key];

  @override
  Future<Map<String, String>> readAll({
    aOptions,
    iOptions,
    lOptions,
    mOptions,
    wOptions,
    webOptions,
  }) async =>
      data;

  @override
  Future<void> write({
    required String key,
    required String? value,
    iOptions,
    aOptions,
    lOptions,
    mOptions,
    wOptions,
    webOptions,
  }) async {
    if (value == null)
      data.remove(key);
    else
      data[key] = value;
  }

  @override
  Future<bool> containsKey({
    required String key,
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async =>
      data.containsKey(key);
}

class MyGoogleSignInMock extends Mock implements GoogleSignIn {
  MockGoogleSignInAccount? _currentUser;

  bool _isCancelled = false;

  /// Used to simulate google login cancellation behaviour.
  void setIsCancelled(bool val) {
    _isCancelled = val;
  }

  @override
  GoogleSignInAccount? get currentUser => _currentUser;

  @override
  Future<GoogleSignInAccount?> signIn() {
    _currentUser = MockGoogleSignInAccount();
    return Future.value(_isCancelled ? null : _currentUser);
  }

  @override
  Future<GoogleSignInAccount?> signOut() async {
    _currentUser = null;
    return Future.value(_isCancelled ? null : _currentUser);
  }
}

class FakeHttpsCallableResult<T> extends Fake
    implements HttpsCallableResult<T> {
  FakeHttpsCallableResult(this.data);

  @override
  T data;
}

class MockFirebaseDynamicLinks extends Fake implements FirebaseDynamicLinks {
  @override
  Future<PendingDynamicLinkData?> getInitialLink() async {
    return null;
  }

  @override
  Stream<PendingDynamicLinkData> get onLink => const Stream.empty();

  @override
  Map get pluginConstants => throw UnimplementedError();
}
