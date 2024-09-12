import 'package:async/async.dart';
import 'package:churchdata/models/models.dart';
import 'package:churchdata/models/super_classes.dart';
import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:tinycolor2/tinycolor2.dart';

class AsyncDataObjectWidget<T extends DataObject> extends StatelessWidget {
  final JsonRef doc;
  final T? Function(JsonDoc) transform;

  final void Function()? onLongPress;
  final void Function()? onTap;
  final Widget? trailing;
  final Widget? photo;
  final Widget? subtitle;
  final Widget? title;
  final bool wrapInCard;
  final bool isDense;
  final bool showSubtitle;
  const AsyncDataObjectWidget(
    this.doc,
    this.transform, {
    this.isDense = false,
    this.onLongPress,
    this.onTap,
    this.trailing,
    this.subtitle,
    this.title,
    this.wrapInCard = true,
    this.photo,
    this.showSubtitle = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T?>(
      future: doc.get().then(transform),
      builder: (context, snapshot) {
        if (snapshot.hasError &&
            !snapshot.error.toString().toLowerCase().contains('denied'))
          return ErrorWidget(snapshot.error!);

        if (snapshot.hasError)
          return const Text('لا يمكن اظهار العنصر المطلوب');

        if (!snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done)
          return const Text('لا يوجد بيانات');

        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }

        return DataObjectWidget<T>(
          snapshot.data!,
          isDense: isDense,
          onLongPress: onLongPress,
          onTap: onTap,
          photo: photo,
          showSubtitle: showSubtitle,
          subtitle: subtitle,
          title: title,
          trailing: trailing,
          wrapInCard: wrapInCard,
        );
      },
    );
  }
}

class DataObjectWidget<T extends DataObject> extends StatelessWidget {
  final T current;

  final void Function()? onLongPress;
  final void Function()? onTap;
  final Widget? trailing;
  final Widget? photo;
  final Widget? subtitle;
  final Widget? title;
  final bool wrapInCard;
  final bool isDense;
  final bool showSubtitle;

  final _memoizer = AsyncMemoizer<String?>();

  DataObjectWidget(
    this.current, {
    super.key,
    this.isDense = false,
    this.onLongPress,
    this.onTap,
    this.trailing,
    this.subtitle,
    this.title,
    this.wrapInCard = true,
    this.photo,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      dense: isDense,
      onLongPress: onLongPress,
      onTap: onTap ?? () => dataObjectTap(current),
      trailing: trailing ??
          ((current is Person || current is User)
              ? (current as Person).getLeftWidget()
              : null),
      title: title ?? Text(current.name),
      subtitle: showSubtitle
          ? subtitle ??
              FutureBuilder<String?>(
                future: _memoizer.runOnce(current.getSecondLine),
                builder: (context, subtitleData) {
                  if (subtitleData.connectionState == ConnectionState.done &&
                      subtitleData.data == null) {
                    return const SizedBox();
                  } else if (subtitleData.hasData) {
                    return Text(
                      subtitleData.data!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  } else {
                    return LinearProgressIndicator(
                      backgroundColor: current.color.tint(56),
                      valueColor: current.color != Colors.transparent
                          ? AlwaysStoppedAnimation(
                              current.color,
                            )
                          : null,
                    );
                  }
                },
              )
          : null,
      leading: photo ??
          (current is PhotoObject
              ? (current as PhotoObject)
                  .photo(cropToCircle: current is Person || current is User)
              : null),
    );
    return wrapInCard
        ? Card(
            color: _getColor(context),
            child: tile,
          )
        : tile;
  }

  Color? _getColor(BuildContext context) {
    if (current.color == Colors.transparent) return null;
    if (current.color.brightness > 170 &&
        Theme.of(context).brightness == Brightness.dark) {
      //refers to the contrasted text theme color
      return current.color
          .darken(((265 - current.color.brightness) / 255 * 100).toInt());
    } else if (current.color.brightness < 85 &&
        Theme.of(context).brightness == Brightness.light) {
      return current.color
          .lighten(((265 - current.color.brightness) / 255 * 100).toInt());
    }
    return current.color;
  }
}
