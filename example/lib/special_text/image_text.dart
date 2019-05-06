import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';

import 'my_special_text_span_builder.dart';

class ImageText extends SpecialText {
  static const String flag = "<img";
  final int start;
  final BuilderType type;
  ImageText(TextStyle textStyle, {this.start, this.type})
      : super(ImageText.flag, "/>", textStyle);

  @override
  TextSpan finishText() {
    // TODO: implement finishText
    ///content already has endflag "/"
    var text = flag + getContent() + ">";

    ///"<img src='$url'/>"
    var index1 = text.indexOf("'") + 1;
    var index2 = text.indexOf("'", index1);

    var url = text.substring(index1, index2);

    //fontsize id define image height
    //size = 30.0/26.0 * fontSize
    double width = 60.0;
    double height = 60.0;
    BoxFit fit = BoxFit.fill;
    if (type == BuilderType.extendedText) {
      width = 120.0;
      height = 80.0;
      fit = BoxFit.cover;
    }

    ///fontSize 26 and text height =30.0
    //final double fontSize = 26.0;

    return ImageSpan(
      ExtendedNetworkImageProvider(url),
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
      },
      afterPaintImage: (Canvas canvas, Rect rect, ImageSpan imageSpan) {
        drawLoadFailed(canvas, rect, imageSpan);
        Border.all(color: Colors.red, width: 1)
            .paint(canvas, rect, shape: BoxShape.rectangle);
      },
    );
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
