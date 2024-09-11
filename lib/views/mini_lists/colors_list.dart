import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorsList extends StatelessWidget {
  final List<Color>? colors;

  final Color? selectedColor;
  final void Function(Color)? onSelect;
  const ColorsList({super.key, this.colors, this.selectedColor, this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (colors == null)
      return BlockPicker(
        pickerColor: selectedColor,
        onColorChanged: onSelect!,
      );
    else
      return BlockPicker(
        pickerColor: selectedColor,
        onColorChanged: onSelect!,
        availableColors: colors!,
      );
  }
}
