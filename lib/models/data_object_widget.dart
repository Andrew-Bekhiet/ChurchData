import 'package:async/async.dart';
import 'package:churchdata/models/models.dart';
import 'package:churchdata/models/super_classes.dart';
import 'package:churchdata/typedefs.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:derived_colors/derived_colors.dart';
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
    final nonTransparentColor =
        current.color == Colors.transparent ? null : current.color;

    final invert = nonTransparentColor?.findInvert();
    final foregroundColor = invert ??
        (wrapInCard
            ? CardTheme.of(context).color?.findInvert()
            : ListTileTheme.of(context).textColor);

    final tile = ListTile(
      iconColor: foregroundColor,
      textColor: foregroundColor,
      tileColor: nonTransparentColor,
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
                      maxLines: 2,
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

    if (wrapInCard) {
      return Card.filled(
        elevation: 1,
        color: nonTransparentColor,
        child: tile,
      );
    }

    return tile;
  }
}
