import 'package:feature_discovery/feature_discovery.dart';
import 'package:hive/hive.dart';

class HivePersistenceProvider extends PersistenceProvider {
  final _box = Hive.box<bool>('FeatureDiscovery');

  @override
  Future<void> clearStep(String featureId) async {
    await _box.delete(featureId);
  }

  @override
  Future<void> clearSteps(Iterable<String> featuresIds) async {
    await _box.deleteAll(featuresIds);
  }

  @override
  Future<void> completeStep(String featureId) async {
    await _box.put(featureId, true);
  }

  @override
  Future<Set<String>> completedSteps(Iterable<String> featuresIds) async {
    return _box
        .toMap()
        .entries
        .where((element) =>
            element.value == true && featuresIds.contains(element.key))
        .map((e) => e.key)
        .toSet()
        .cast<String>();
  }

  @override
  Future<bool> hasCompletedStep(String featureId) async {
    return _box.get(featureId, defaultValue: false);
  }
}
