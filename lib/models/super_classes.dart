import 'dart:async';

import 'package:async/async.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:churchdata/typedefs.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';

abstract class DataObject {
  JsonRef ref;
  String name;
  Color color;

  DataObject(this.ref, this.name, Color? color)
      : color = color ?? Colors.transparent;

  DataObject.createFromData(Json data, this.ref)
      : name = data['Name'] ?? '',
        color = Color(data['Color'] ?? Colors.transparent.value);

  @override
  int get hashCode =>
      Object.hashAll([id, _fullyHash(getMap().values.toList())]);

  String get id => ref.id;

  @override
  bool operator ==(other) {
    return other is DataObject && other.id == id && other.hashCode == hashCode;
  }

  DataObject copyWith();

  Json getMap();

  Json getHumanReadableMap();

  Future<String?> getSecondLine();

  int _fullyHash(dynamic e) {
    if (e is Map)
      return Object.hash(
        _fullyHash(e.keys.toList()),
        _fullyHash(e.values.toList()),
      );
    else if (e is JsonRef)
      return e.path.hashCode;
    else if (e is List &&
        e.whereType<Map>().isEmpty &&
        e.whereType<JsonRef>().isEmpty &&
        e.whereType<List>().isEmpty)
      return Object.hashAll(e);
    else if (e is List) return Object.hashAll(e.map(_fullyHash));

    return e?.hashCode ?? 0;
  }

  Future<void> set() async {
    await ref.set(getMap());
  }

  Future<void> update({Json old = const {}}) async {
    await ref.update(getMap()..removeWhere((key, value) => old[key] == value));
  }
}

abstract mixin class ParentObject<T extends DataObject> {
  Future<List<T>> getChildren([
    String orderBy = 'Name',
    bool tranucate = false,
  ]);

  Future<String> getMembersString() async {
    return (await getChildren('Name', true)).map((f) => f.name).join(',');
  }
}

abstract mixin class ChildObject<T extends DataObject> {
  JsonRef? get parentId;
  Future<String?> getParentName();
}

abstract mixin class PhotoObject {
  IconData defaultIcon = Icons.help;
  late bool hasPhoto;

  final AsyncCache<String> _photoUrlCache =
      AsyncCache<String>(const Duration(days: 1));

  Reference get photoRef;

  Widget photo({bool cropToCircle = true, bool removeHero = false}) {
    return DataObjectPhoto(
      this,
      wrapPhotoInCircle: cropToCircle,
      key: hasPhoto ? ValueKey(photoRef.fullPath) : null,
      heroTag: removeHero ? UniqueKey() : null,
    );
  }
}

class DataObjectPhoto extends StatefulWidget {
  final PhotoObject object;
  final bool wrapPhotoInCircle;
  final Object? heroTag;
  const DataObjectPhoto(
    this.object, {
    super.key,
    this.wrapPhotoInCircle = false,
    this.heroTag,
  });

  @override
  _DataObjectPhotoState createState() => _DataObjectPhotoState();
}

class _DataObjectPhotoState extends State<DataObjectPhoto> {
  bool disposed = false;

  String get cacheKey => widget.object.photoRef.fullPath;

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }

  Future<void> _updateCache(String cache) async {
    String? url;

    try {
      url = await widget.object.photoRef.getDownloadURL();
    } catch (e) {
      url = null;
    }

    if (cache != url && url != null) {
      await Hive.box<String?>('PhotosURLsCache').put(cacheKey, url);

      await DefaultCacheManager().removeFile(cacheKey);
      widget.object._photoUrlCache.invalidate();

      if (mounted && !disposed) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrains) {
        if (!widget.object.hasPhoto)
          return Icon(widget.object.defaultIcon, size: constrains.maxHeight);

        return Hero(
          tag: widget.heroTag ?? cacheKey,
          child: ConstrainedBox(
            constraints: BoxConstraints.expand(
              height: constrains.maxHeight,
              width: constrains.maxHeight,
            ),
            child: FutureBuilder<String>(
              future: widget.object._photoUrlCache.fetch(
                () async {
                  final String? cache =
                      Hive.box<String?>('PhotosURLsCache').get(cacheKey);

                  if (cache == null) {
                    final String url = await widget.object.photoRef
                        .getDownloadURL()
                        .catchError((onError) => '');
                    await Hive.box<String?>('PhotosURLsCache')
                        .put(cacheKey, url);

                    return url;
                  }

                  unawaited(_updateCache(cache));

                  return SynchronousFuture(cache);
                },
              ),
              builder: (context, data) {
                if (data.hasError)
                  return Center(child: ErrorWidget(data.error!));
                if (!data.hasData)
                  return const AspectRatio(
                    aspectRatio: 1,
                    child: CircularProgressIndicator(),
                  );
                if (data.data == '')
                  return Icon(
                    widget.object.defaultIcon,
                    size: constrains.maxHeight,
                  );
                else {
                  final photo = Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: () => showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: Hero(
                            tag: widget.heroTag ?? cacheKey,
                            child: InteractiveViewer(
                              child: CachedNetworkImage(
                                cacheKey: cacheKey,
                                imageUrl: data.data!,
                                progressIndicatorBuilder:
                                    (context, url, progress) => AspectRatio(
                                  aspectRatio: 1,
                                  child: CircularProgressIndicator(
                                    value: progress.progress,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      child: CachedNetworkImage(
                        cacheKey: cacheKey,
                        memCacheHeight: (constrains.maxHeight * 4).toInt(),
                        imageUrl: data.data!,
                        progressIndicatorBuilder: (context, url, progress) =>
                            AspectRatio(
                          aspectRatio: 1,
                          child: CircularProgressIndicator(
                            value: progress.progress,
                          ),
                        ),
                      ),
                    ),
                  );
                  return widget.wrapPhotoInCircle
                      ? ClipOval(
                          child: photo,
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: photo,
                        );
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class PhotoWidget with PhotoObject {
  PhotoWidget(this.photoRef, {IconData? defaultIcon}) {
    if (defaultIcon != null) this.defaultIcon = defaultIcon;
  }

  @override
  Reference photoRef;

  @override
  bool get hasPhoto => true;
}
