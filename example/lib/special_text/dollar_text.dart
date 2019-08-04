import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';

class DollarText extends SpecialText {
  static const String flag = "\$";
  final int start;
  DollarText(TextStyle textStyle, SpecialTextGestureTapCallback onTap,
      {this.start})
      : super(flag, flag, textStyle, onTap: onTap);

  @override
  InlineSpan finishText() {
    final String text = getContent();

    return SpecialTextSpan(
      text: text,
      actualText: toString(),
      start: start,

      ///caret can move into special text
      deleteAll: true,
      style: textStyle?.copyWith(color: Colors.orange),
    );
  }
}

List<String> dollarList = <String>[
  "\$Dota2\$",
  "\$Dota2 Ti9\$",
  "\$CN dota best dota\$",
  "\$Flutter\$",
  "\$CN dev best dev\$",
  "\$UWP\$",
  "\$Nevermore\$",
  "\$FlutterCandies\$",
  "\$ExtendedImage\$",
  "\$ExtendedText\$",
];
