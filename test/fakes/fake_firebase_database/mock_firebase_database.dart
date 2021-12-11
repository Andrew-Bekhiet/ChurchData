import 'package:firebase_database/firebase_database.dart';
import 'package:mockito/mockito.dart';

import 'mock_database_reference.dart';

class MockFirebaseDatabase extends Mock implements FirebaseDatabase {
  static FirebaseDatabase get instance => MockFirebaseDatabase();
  static bool get persistData => _persistData;

  @override
  DatabaseReference ref([String? path]) => MockDatabaseReference();
  // ignore: unused_field
  static bool _persistData = true;
  //Todo support non persistence.
  static void setDataPersistanceEnabled({bool ennabled = true}) {
    _persistData = ennabled;
  }
}
