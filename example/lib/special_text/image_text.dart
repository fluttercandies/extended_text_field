import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';

class ImageText extends SpecialText {
  static const String flag = "<img";
  final int start;
  ImageText(TextStyle textStyle, {this.start})
      : super(ImageText.flag, "/>", textStyle);

  @override
  TextSpan finishText() {
    // TODO: implement finishText
    var text = toString();

    ///"<img src='$url'/>"
    var index1 = text.indexOf("'") + 1;
    var index2 = text.indexOf("'", index1);

    var url = text.substring(index1, index2);

    //fontsize id define image height
    //size = 30.0/26.0 * fontSize
    final double size = 25.0;

    ///fontSize 26 and text height =30.0
    //final double fontSize = 26.0;

    return ImageSpan(CachedNetworkImage(url),
        actualText: text,
        imageWidth: 30.0,
        imageHeight: 25.0,
        start: start,
        deleteAll: true,
        fit: BoxFit.fill,
        margin: EdgeInsets.only(left: 2.0, top: 2.0, right: 2.0));
  }
}
