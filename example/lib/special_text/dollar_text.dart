import 'package:extended_text/extended_text.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';

class DollarText extends SpecialText {
  static const String flag = "\$";
  final int start;
  DollarText(
      TextStyle textStyle, SpecialTextGestureTapCallback onTap, this.start)
      : super(flag, flag, textStyle, onTap: onTap);

  @override
  TextSpan finishText() {
    // TODO: implement finishText
    final String atText = getContent();
    return SpecialTextSpan(
      text: atText,
      actualText: toString(),
      start: start,
      style: textStyle?.copyWith(color: Colors.orange),
    );
  }
}
