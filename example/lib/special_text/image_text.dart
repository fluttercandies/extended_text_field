import 'dart:math';

import 'package:extended_image/extended_image.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';

class ImageText extends SpecialText {
  static const String flag = "<img";
  final int start;
  final SpecialTextGestureTapCallback onTap;
  ImageText(TextStyle textStyle, {this.start, this.onTap})
      : super(ImageText.flag, "/>", textStyle);
  String _imageUrl;
  String get imageUrl => _imageUrl;
  @override
  InlineSpan finishText() {
    // TODO: implement finishText
    ///content already has endflag "/"
    var text = flag + getContent() + ">";

    ///"<img src='$url'/>"
//    var index1 = text.indexOf("'") + 1;
//    var index2 = text.indexOf("'", index1);
//
//    var url = text.substring(index1, index2);
//
    ////"<img src='$url' width='${item.imageSize.width}' height='${item.imageSize.height}'/>"
    var html = parse(text);

    var img = html.getElementsByTagName("img").first;
    var url = img.attributes["src"];
    _imageUrl = url;

    //fontsize id define image height
    //size = 30.0/26.0 * fontSize
    double width = 60.0;
    double height = 60.0;
    BoxFit fit = BoxFit.cover;
    double num300 = 60.0;
    double num400 = 80.0;

    height = num300;
    width = num400;
    bool knowImageSize = true;
    if (knowImageSize) {
      height = double.tryParse(img.attributes["height"]);
      width = double.tryParse(img.attributes["width"]);
      var n = height / width;
      if (n >= 4 / 3) {
        width = num300;
        height = num400;
      } else if (4 / 3 > n && n > 3 / 4) {
        var maxValue = max(width, height);
        height = num400 * height / maxValue;
        width = num400 * width / maxValue;
      } else if (n <= 3 / 4) {
        width = num400;
        height = num300;
      }
    }

    ///fontSize 26 and text height =30.0
    //final double fontSize = 26.0;

    return ExtendedWidgetSpan(
        start: start,
        actualText: text,
        child: GestureDetector(
            onTap: () {
              onTap?.call(url);
            },
            child: ExtendedImage.network(url,
                width: width,
                height: height,
                fit: fit,
                loadStateChanged: loadStateChanged)));
  }

  Widget loadStateChanged(ExtendedImageState state) {
    switch (state.extendedImageLoadState) {
      case LoadState.loading:
        return Container(
          color: Colors.grey,
        );
      case LoadState.completed:
        return null;
      case LoadState.failed:
        state.imageProvider.evict();
        return GestureDetector(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.asset(
                "assets/failed.jpg",
                fit: BoxFit.fill,
              ),
              Positioned(
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                child: Text(
                  "load image failed, click to reload",
                  textAlign: TextAlign.center,
                ),
              )
            ],
          ),
          onTap: () {
            state.reLoadImage();
          },
        );
    }
    return null;
  }
}
