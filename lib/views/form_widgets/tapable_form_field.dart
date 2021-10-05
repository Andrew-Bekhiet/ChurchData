import 'package:flutter/material.dart';

class TapableFormField<T> extends StatelessWidget {
  const TapableFormField({
    Key? key,
    required this.initialValue,
    required this.onTap,
    this.labelText,
    required this.builder,
    this.decoration,
    this.onSaved,
    this.validator,
    this.autovalidateMode,
  })  : assert(labelText != null || decoration != null),
        super(key: key);

  final T initialValue;
  final void Function(FormFieldState<T>) onTap;
  final String? labelText;
  final Widget? Function(BuildContext, FormFieldState<T>) builder;
  final String? Function(T?)? validator;
  final void Function(T?)? onSaved;
  final InputDecoration Function(BuildContext, FormFieldState<T>)? decoration;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: FormField<T>(
        autovalidateMode: autovalidateMode,
        initialValue: initialValue,
        builder: (state) => InkWell(
          onTap: () => onTap(state),
          child: InputDecorator(
            decoration: decoration != null
                ? decoration!(context, state)
                : InputDecoration(
                    errorText: state.errorText,
                    labelText: labelText,
                  ),
            isEmpty: state.value == null,
            child: builder(context, state),
          ),
        ),
        onSaved: onSaved,
        validator:
            validator ?? (value) => value == null ? 'هذا الحقل مطلوب' : null,
      ),
    );
  }
}
