import 'package:extended_text/extended_text.dart';
import 'package:extended_text_field/src/text_span/special_text_span_base.dart';
import 'package:flutter/material.dart';

///
///  create by zmtzawqlp on 2019/4/26
///

class TextFieldImageSpan extends ImageSpan with SpecialTextSpanBase {
  TextFieldImageSpan(ImageProvider image,
      {@required double imageWidth,
      @required double imageHeight,
      @required String actualText,
      @required int start,
      EdgeInsets margin,
      BeforePaintTextImage beforePaintImage,
      AfterPaintTextImage afterPaintImage,
      BoxFit fit: BoxFit.scaleDown})
      : super(image,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            margin: margin,
            beforePaintImage: beforePaintImage,
            afterPaintImage: afterPaintImage,
            fit: fit) {
    this.actualText = actualText;
    this.start = start;
  }

  @override
  String toPlainText({bool includeSemanticsLabels = true}) {
    // TODO: implement toPlainText
    return super.toPlainText(includeSemanticsLabels: includeSemanticsLabels);
  }
}
