import 'package:flutter/material.dart';

/// class CustomTextFieldWidget extends StatelessWidget
///     with SystemKeyboardShowWidgetMixin {
///   const CustomTextFieldWidget({
///     Key? key,
///     this.ignoreSystemKeyboardShow = true,
///   }) : super(key: key);
///   @override
///   final bool ignoreSystemKeyboardShow;
/// }
mixin SystemKeyboardShowWidgetMixin on Widget {
  /// no system keyboard show
  bool get ignoreSystemKeyboardShow;

  /// find SystemKeyboardShowWidgetMixin and check ignoreSystemKeyboardShow
  ///
  /// SystemKeyboardShowWidgetMixin.ignoreShowSystemKeyboard<ExtendedTextField>()
  ///
  /// see [TextInputBinding]
  static bool
      ignoreShowSystemKeyboard<T extends SystemKeyboardShowWidgetMixin>() {
    final FocusNode? focus = FocusManager.instance.primaryFocus;
    if (focus != null && focus.context != null) {
      final T? widget = focus.context!.findAncestorWidgetOfExactType<T>();
      if (widget != null && widget.ignoreSystemKeyboardShow) {
        return true;
      }
    }
    return false;
  }
}

/// class CustomTextFieldState extends State<CustomTextField>
///     with SystemKeyboardShowStateMixin {
///   @override
///   bool get ignoreSystemKeyboardShow => true;
/// }
@optionalTypeArgs
mixin SystemKeyboardShowStateMixin<T extends StatefulWidget> on State<T> {
  /// no system keyboard show
  bool get ignoreSystemKeyboardShow;

  /// find SystemKeyboardShowStateMixin and check ignoreSystemKeyboardShow
  ///
  /// SystemKeyboardShowStateMixin.ignoreShowSystemKeyboard<CustomTextFieldState>()
  ///
  /// see [TextInputBinding]
  static bool
      ignoreShowSystemKeyboard<T extends SystemKeyboardShowStateMixin>() {
    final FocusNode? focus = FocusManager.instance.primaryFocus;
    if (focus != null && focus.context != null) {
      final T? widget = focus.context!.findAncestorStateOfType<T>();
      if (widget != null && widget.ignoreSystemKeyboardShow) {
        return true;
      }
    }
    return false;
  }
}
