import 'package:flutter/material.dart';

///
///  create by zmtzawqlp on 2019/4/26
///

class SpecialTextSpan extends TextSpan {
  const SpecialTextSpan({
    TextStyle style,
    String text,
//    List<TextSpan> children,
  }) : super(
          style: style,
          text: text,
        );

  @override
  String toPlainText({bool includeSemanticsLabels = true}) {
    // TODO: implement toPlainText
    return super.toPlainText(includeSemanticsLabels: includeSemanticsLabels);
  }
}
