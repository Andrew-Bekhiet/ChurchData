import 'package:async/async.dart';
import 'package:churchdata/models/super_classes.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:tinycolor/tinycolor.dart';

import 'area.dart';
import 'family.dart';
import 'person.dart';
import 'street.dart';

class DataObjectWidget<T extends DataObject> extends StatelessWidget {
  final T current;

  final void Function() onLongPress;
  final void Function() onTap;
  final Widget trailing;
  final Widget subtitle;
  final Widget title;
  final Widget photo;
  final bool wrapInCard;
  final bool isDense;
  final bool showSubtitle;

  final _memoizer = AsyncMemoizer<String>();

  DataObjectWidget(this.current,
      {Key key,
      this.isDense = false,
      this.onLongPress,
      this.onTap,
      this.trailing,
      this.subtitle,
      this.title,
      this.wrapInCard = true,
      this.photo,
      this.showSubtitle = true})
      : super(key: key);

  String _getTName() {
    if (current is Area) return 'Area';
    if (current is Street) return 'Street';
    if (current is Family) return 'Family';
    if (current is Person) return 'Person';
    throw UnimplementedError();
  }

  String _getArabicTName() {
    if (current is Area) return 'المنطقة';
    if (current is Street) return 'الشارع';
    if (current is Family) return 'العائلة';
    if (current is Person) return 'الشخص';
    throw UnimplementedError();
  }

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      dense: isDense,
      onLongPress: onLongPress,
      onTap: current.name != null
          ? (onTap ?? () => dataObjectTap(current, context))
          : null,
      trailing: trailing,
      title: title ??
          Text(current.name ?? 'حدث خطأ: لا يمكن إيجاد $_getArabicTName()'),
      subtitle: showSubtitle
          ? (subtitle ??
              (Hive.box('Settings').get(_getTName() + 'SecondLine') != null
                  ? FutureBuilder(
                      future: _memoizer
                          .runOnce(() async => await current.getSecondLine()),
                      builder: (cont, subT) {
                        if (subT.hasData) {
                          return Text(subT.data ?? '',
                              maxLines: 1, overflow: TextOverflow.ellipsis);
                        } else {
                          return LinearProgressIndicator(
                              backgroundColor:
                                  current.color != Colors.transparent
                                      ? current.color
                                      : null,
                              valueColor: AlwaysStoppedAnimation(
                                  current.color != Colors.transparent
                                      ? current.color
                                      : Theme.of(context).primaryColor));
                        }
                      },
                    )
                  : null))
          : null,
      leading: photo ??
          (current is PhotoObject ? (current as PhotoObject).photo : null),
    );
    return wrapInCard ? Card(color: _getColor(context), child: tile) : tile;
  }

  Color _getColor(BuildContext context) {
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
