import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';

class AtText extends SpecialText {
  static const String flag = "@";
  final int start;

  /// whether show background for @somebody
  final bool showAtBackground;
  AtText(TextStyle textStyle, SpecialTextGestureTapCallback onTap, this.start,
      {this.showAtBackground: false})
      : super(flag, " ", textStyle, onTap: onTap);

  @override
  TextSpan finishText() {
    // TODO: implement finishText
    TextStyle textStyle = showAtBackground
        ? this.textStyle?.copyWith(
            fontSize: 16.0,
            background: Paint()..color = Colors.blue.withOpacity(0.5))
        : this.textStyle?.copyWith(color: Colors.blue, fontSize: 16.0);

    final String atText = toString();
    return SpecialTextSpan(
        text: atText,
        actualText: atText,
        start: start,
        deleteAll: false,
        style: textStyle);
  }
}
