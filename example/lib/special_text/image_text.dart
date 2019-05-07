import 'dart:math';

import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'my_special_text_span_builder.dart';

class ImageText extends SpecialText {
  static const String flag = "<img";
  final int start;
  final BuilderType type;
  final SpecialTextGestureTapCallback onTap;
  ImageText(TextStyle textStyle, {this.start, this.type, this.onTap})
      : super(ImageText.flag, "/>", textStyle);
  String _imageUrl;
  String get imageUrl => _imageUrl;
  @override
  TextSpan finishText() {
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
    double num300 = type == BuilderType.extendedText ? 90.0 : 60.0;
    double num400 = type == BuilderType.extendedText ? 120.0 : 80.0;

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

    return ImageSpan(ExtendedNetworkImageProvider(url),
        actualText: text,
        imageWidth: width,
        imageHeight: height,
        start: start,
        deleteAll: true,
        fit: fit,
        clearMemoryCacheIfFailed: true,
        margin: EdgeInsets.only(left: 2.0, top: 2.0, right: 2.0),
        beforePaintImage: (Canvas canvas, Rect rect, ImageSpan imageSpan) {
      bool hasPlaceholder = drawPlaceholder(canvas, rect, imageSpan);

      if (!hasPlaceholder) {
        clearRect(rect, canvas);
      }

      return false;
    }, afterPaintImage: (Canvas canvas, Rect rect, ImageSpan imageSpan) {
      drawLoadFailed(canvas, rect, imageSpan);
      Border.all(color: Colors.red, width: 1)
          .paint(canvas, rect, shape: BoxShape.rectangle);
    },
        recognizer: type == BuilderType.extendedText
            ? (TapGestureRecognizer()
              ..onTap = () {
                onTap?.call(url);
              })
            : null);
  }
}

bool drawPlaceholder(Canvas canvas, Rect rect, ImageSpan imageSpan) {
  bool hasPlaceholder = imageSpan.imageSpanResolver.imageInfo?.image == null;

  if (hasPlaceholder) {
    canvas.drawRect(rect, Paint()..color = Colors.grey);
    var textPainter = TextPainter(
        text: TextSpan(text: "loading", style: TextStyle(fontSize: 10.0)),
        textAlign: TextAlign.center,
        textScaleFactor: 1,
        textDirection: TextDirection.ltr,
        maxLines: 1)
      ..layout(maxWidth: rect.width);

    textPainter.paint(
        canvas,
        Offset(rect.left + (rect.width - textPainter.width) / 2.0,
            rect.top + (rect.height - textPainter.height) / 2.0));
  }
  return hasPlaceholder;
}

void clearRect(Rect rect, Canvas canvas) {
  ///if don't save layer
  ///BlendMode.clear will show black
  ///maybe this is bug for blendMode.clear
  canvas.saveLayer(rect, Paint());
  canvas.drawRect(rect, Paint()..blendMode = BlendMode.clear);
  canvas.restore();
}

bool drawLoadFailed(Canvas canvas, Rect rect, ImageSpan imageSpan) {
  bool loadFailed = imageSpan.imageSpanResolver.loadFailed;

  if (loadFailed) {
    //canvas.drawRect(rect, Paint()..color = Colors.grey);
    var textPainter = TextPainter(
        text: TextSpan(
            text: "failed",
            style: TextStyle(fontSize: 10.0, color: Colors.red)),
        textAlign: TextAlign.center,
        textScaleFactor: 1,
        textDirection: TextDirection.ltr,
        maxLines: 1)
      ..layout(maxWidth: rect.width);

    textPainter.paint(
        canvas,
        Offset(rect.left + (rect.width - textPainter.width) / 2.0,
            rect.top + (rect.height - textPainter.height) / 2.0));
  }
  return loadFailed;
}
