import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/painting/image_provider.dart';

///
///  create by zmtzawqlp on 2019/4/26
///

class TextFieldImageSpan extends ImageSpan {
  final String imageText;

  TextFieldImageSpan(ImageProvider image, this.imageText,
      {@required double imageWidth,
      @required double imageHeight,
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
            fit: fit);

  @override
  String toPlainText({bool includeSemanticsLabels = true}) {
    // TODO: implement toPlainText
    return imageText;
    return super.toPlainText(includeSemanticsLabels: includeSemanticsLabels);
  }
}
