import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorsList extends StatelessWidget {
  final List<Color> colors;

  final Color selectedColor;
  final void Function(Color) onSelect;
  final bool onlyPrimaries;
  ColorsList(
      {Key key,
      this.colors,
      this.selectedColor,
      this.onSelect,
      this.onlyPrimaries = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (colors == null)
      return BlockPicker(
        pickerColor: selectedColor,
        onColorChanged: (v) => onSelect(v),
      );
    else
      return BlockPicker(
        pickerColor: selectedColor,
        onColorChanged: (v) => onSelect(v),
        availableColors: colors,
      );
  }
}
