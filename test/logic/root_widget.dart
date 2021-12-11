import 'package:churchdata/models/data_object_widget.dart';
import 'package:churchdata/models/hive_persistence_provider.dart';
import 'package:churchdata/models/models.dart';
import 'package:churchdata/utils/firebase_repo.dart';
import 'package:churchdata/views/root.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../globals.dart';
import '../main.dart';

Future<void> main() async {
  await initTests();

  group('Root widget', () {
    setUpAll(() async {
      if (User.instance.uid != null) await User.instance.signOut();
      await firebaseAuth.signInWithCustomToken('token');
      await User.instance.initialized;

      await Person(
        ref: User.instance.personDocRef,
        areaId: firestore.doc('Areas/fakeArea'),
        streetId: firestore.doc('Streets/fakeStreet'),
        familyId: firestore.doc('Families/fakeFamily'),
        name: 'Mock User Data',
        lastTanawol: Timestamp.now(),
        lastConfession: Timestamp.now(),
      ).set();

      //Populate database with fake data:
      await Area(
        name: 'Fake Area',
        address: 'address',
        allowedUsers: [User.instance.uid!],
        ref: firestore.doc('Areas/fakeArea'),
      ).set();

      await Street(
        ref: firestore.doc('Streets/fakeStreet'),
        areaId: firestore.doc('Areas/fakeArea'),
        name: 'Fake Street',
      ).set();

      await Family(
        ref: firestore.doc('Families/fakeFamily'),
        areaId: firestore.doc('Areas/fakeArea'),
        streetId: firestore.doc('Streets/fakeStreet'),
        name: 'Fake Family',
        address: 'address',
      ).set();

      await Person(
        ref: firestore.doc('Persons/fakePerson'),
        areaId: firestore.doc('Areas/fakeArea'),
        streetId: firestore.doc('Streets/fakeStreet'),
        familyId: firestore.doc('Families/fakeFamily'),
        name: 'Fake Person',
      ).set();
    });

    testWidgets('Tabs', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          FeatureDiscovery.withProvider(
            persistenceProvider: MockHivePersistenceProvider(),
            child: const Root(),
          ),
        ),
      );

      expect(
        find.ancestor(
          of: find.byIcon(Icons.pin_drop),
          matching: find.byType(Tab),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('_AreasTab')), findsOneWidget);

      expect(
        find.ancestor(
          of: find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                widget.image is AssetImage &&
                (widget.image as AssetImage).assetName == 'assets/streets.png',
          ),
          matching: find.byType(Tab),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('_StreetsTab')), findsOneWidget);

      expect(
        find.ancestor(
          of: find.byIcon(Icons.group),
          matching: find.byType(Tab),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('_FamiliesTab')), findsOneWidget);

      expect(
        find.ancestor(
          of: find.byIcon(Icons.person),
          matching: find.byType(Tab),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('_PersonsTab')), findsOneWidget);
    });

    testWidgets('Data', (tester) async {
      tester.binding.window.physicalSizeTestValue =
          const Size(1080 * 3, 2400 * 3);

      await tester.pumpWidget(
        wrapWithMaterialApp(
          FeatureDiscovery.withProvider(
            persistenceProvider: MockHivePersistenceProvider(),
            child: const Root(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(DataObjectWidget<Area>, 'Fake Area'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('_StreetsTab')));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(DataObjectWidget<Street>, 'Fake Street'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('_FamiliesTab')));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(DataObjectWidget<Family>, 'Fake Family'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('_PersonsTab')));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(DataObjectWidget<Person>, 'Fake Person'),
        findsOneWidget,
      );
    });
  });
}
