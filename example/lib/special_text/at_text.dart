import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';

class AtText extends SpecialText {
  static const String flag = "@";
  final int start;
  AtText(TextStyle textStyle, SpecialTextGestureTapCallback onTap, this.start)
      : super(flag, " ", textStyle, onTap: onTap);

  @override
  TextSpan finishText() {
    // TODO: implement finishText

    final String atText = toString();
    return SpecialTextSpan(
      text: atText,
      actualText: atText,
      start: start,
      deleteAll: false,
      style: textStyle?.copyWith(color: Colors.blue, fontSize: 16.0),
    );
  }
}
