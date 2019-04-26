import 'package:extended_text/extended_text.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';

class AtText extends SpecialText {
  static const String flag = "@";
  AtText(TextStyle textStyle, SpecialTextGestureTapCallback onTap)
      : super(flag, " ", textStyle, onTap: onTap);

  @override
  TextSpan finishText() {
    // TODO: implement finishText

    final String atText = toString();
    return SpecialTextSpan(
      text: atText,
      style: textStyle?.copyWith(color: Colors.blue, fontSize: 16.0),
    );
  }
}
