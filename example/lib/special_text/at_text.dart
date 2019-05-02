import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'my_special_text_span_builder.dart';

class AtText extends SpecialText {
  static const String flag = "@";
  final int start;

  /// whether show background for @somebody
  final bool showAtBackground;

  final BuilderType type;
  AtText(TextStyle textStyle, SpecialTextGestureTapCallback onTap, this.start,
      {this.showAtBackground: false, this.type})
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

    if (type == BuilderType.extendedText) {
      return TextSpan(
          text: atText,
          style: textStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (onTap != null) onTap(atText);
            }
      );
    }

    return SpecialTextSpan(
      text: atText,
      actualText: atText,
      start: start,
      deleteAll: false,
      style: textStyle,
    );
  }
}

List<String> atList = <String>[
  "@Nevermore ",
  "@Dota2 ",
  "@Biglao ",
  "@艾莉亚·史塔克 ",
  "@丹妮莉丝 ",
  "@HandPulledNoodles ",
  "@Zmtzawqlp ",
  "@FaDeKongJian ",
  "@CaiJingLongDaLao ",
];
