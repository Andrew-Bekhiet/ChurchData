import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

class ColorField extends StatelessWidget {
  final Color? initialValue;
  final bool nullable;
  final FormFieldSetter<Color?>? onSaved;
  final FormFieldValidator<Color?>? validator;
  final AutovalidateMode? autovalidateMode;
  final void Function(Color?)? onChanged;

  const ColorField({
    this.initialValue,
    this.onSaved,
    this.validator,
    this.autovalidateMode,
    this.onChanged,
    this.nullable = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: FormField<Color?>(
        initialValue: initialValue,
        autovalidateMode: autovalidateMode,
        onSaved: onSaved,
        validator: validator,
        builder: (state) => InkWell(
          onTap: () => _selectColor(context, state),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'اللون',
              suffixIcon: nullable
                  ? IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        state.didChange(null);
                        onChanged?.call(null);
                      },
                    )
                  : null,
            ),
            child: ColorIndicator(
              width: 50,
              height: 50,
              borderRadius: 20,
              color: state.value ?? Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectColor(
    BuildContext context,
    FormFieldState<Color?> state,
  ) async {
    final focusScope = FocusScope.of(context);

    final Color newColor = await showColorPickerDialog(
      context,
      state.value ?? Colors.transparent,
      title: Text(
        'اختيار اللون',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      spacing: 10,
      runSpacing: 10,
      borderRadius: 20,
      wheelDiameter: 165,
      enableOpacity: true,
      enableTonalPalette: true,
      enableShadesSelection: false,
      showRecentColors: true,
      showColorName: true,
      showColorCode: true,
      colorCodeHasColor: true,
      pickersEnabled: <ColorPickerType, bool>{
        ColorPickerType.primary: false,
        ColorPickerType.accent: false,
        ColorPickerType.both: true,
        ColorPickerType.wheel: true,
        ColorPickerType.bw: false,
        ColorPickerType.custom: false,
        ColorPickerType.customSecondary: false,
      },
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        copyButton: true,
        pasteButton: true,
        longPressMenu: true,
      ),
      pickerTypeLabels: {
        ColorPickerType.both: 'ألوان محددة',
        ColorPickerType.wheel: 'مخصص',
      },
      opacitySubheading: const Text('الشفافية'),
      colorCodeReadOnly: true,
      barrierColor: Colors.black54,
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.height * 0.7,
      ),
    );

    if (newColor != state.value) {
      state.didChange(newColor);
      onChanged?.call(newColor);
      focusScope.nextFocus();
    }
  }
}
