import 'package:example/special_text/at_text.dart';
import 'package:example/special_text/dollar_text.dart';
import 'package:example/special_text/emoji_text.dart';
import 'package:example/special_text/image_text.dart';
import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/material.dart';

class MySpecialTextSpanBuilder extends SpecialTextSpanBuilder {
  Map<TextRange, TextStyle> specialTextStyle = Map<TextRange, TextStyle>();

  /// whether show background for @somebody
  final bool showAtBackground;
  final BuilderType type;
  MySpecialTextSpanBuilder(
      {this.showAtBackground: false, this.type: BuilderType.extendedText});

  @override
  TextSpan build(String data, {TextStyle textStyle, onTap}) {
    TextSpan result = super.build(data, textStyle: textStyle, onTap: onTap);
    handleSpeicalTextStyle(result);
    return result;
  }

  TextSpan handleSpeicalTextStyle(TextSpan result) {
    if (specialTextStyle.length != 0 &&
        result != null &&
        result.children != null) {
      int index = 0;
      List<InlineSpan> inlineList = new List<InlineSpan>();
      for (InlineSpan item in result.children) {
        if (item is SpecialInlineSpanBase) {
          var base = item as SpecialInlineSpanBase;

          index = base.end;
        } else {
          var start = index;
          var end = index + item.toPlainText().length;

          index = end;
        }
      }
      return TextSpan(style: result.style, children: inlineList);
    }
    return result;
  }

  @override
  SpecialText createSpecialText(String flag,
      {TextStyle textStyle, SpecialTextGestureTapCallback onTap, int index}) {
    if (flag == null || flag == "") return null;
    // TODO: implement createSpecialText

    ///index is end index of start flag, so text start index should be index-(flag.length-1)
    if (isStart(flag, AtText.flag)) {
      return AtText(textStyle, onTap,
          start: index - (AtText.flag.length - 1),
          showAtBackground: showAtBackground,
          type: type);
    } else if (isStart(flag, EmojiText.flag)) {
      return EmojiText(textStyle, start: index - (EmojiText.flag.length - 1));
    } else if (isStart(flag, DollarText.flag)) {
      return DollarText(textStyle, onTap,
          start: index - (DollarText.flag.length - 1), type: type);
    } else if (isStart(flag, ImageText.flag)) {
      return ImageText(textStyle,
          start: index - (ImageText.flag.length - 1), type: type, onTap: onTap);
    }
    return null;
  }
}

enum BuilderType { extendedText, extendedTextField }

class SpecialTextStyle {
  TextRange textRange;
}
