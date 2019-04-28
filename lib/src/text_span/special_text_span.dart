import 'package:extended_text_field/src/text_span/special_text_span_base.dart';
import 'package:flutter/material.dart';

///
///  create by zmtzawqlp on 2019/4/26
///

class SpecialTextSpan extends TextSpan with SpecialTextSpanBase {
  SpecialTextSpan({
    TextStyle style,
    String text,
    @required String actualText,
    @required int start,
//    List<TextSpan> children,
  }) : super(
          style: style,
          text: text,
        ) {
    this.actualText = actualText;
    this.start = start;
  }

  @override
  String toPlainText({bool includeSemanticsLabels = true}) {
    // TODO: implement toPlainText
    return super.toPlainText(includeSemanticsLabels: includeSemanticsLabels);
  }
}
