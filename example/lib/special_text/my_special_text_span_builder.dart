import 'package:example/special_text/at_text.dart';
import 'package:example/special_text/dollar_text.dart';
import 'package:example/special_text/emoji_text.dart';
import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/material.dart';

class MySpecialTextSpanBuilder extends SpecialTextSpanBuilder {
  @override
  TextSpan build(String data, {TextStyle textStyle, onTap}) {
    // TODO: implement build
    if (data == null) return null;
    List<TextSpan> inlineList = new List<TextSpan>();
    if (data.length > 0) {
      SpecialText specialText;
      String textStack = "";
      //String text
      for (int i = 0; i < data.length; i++) {
        String char = data[i];
        if (specialText != null) {
          if (!specialText.isEnd(char)) {
            specialText.appendContent(char);
          } else {
            inlineList.add(specialText.finishText());
            specialText = null;
          }
        } else {
          textStack += char;
          specialText = createSpecialText(textStack,
              textStyle: textStyle, onTap: onTap, start: i);
          if (specialText != null) {
            if (textStack.length - specialText.startFlag.length >= 0) {
              textStack = textStack.substring(
                  0, textStack.length - specialText.startFlag.length);
              if (textStack.length > 0) {
                inlineList.add(TextSpan(text: textStack, style: textStyle));
              }
            }
            textStack = "";
          }
        }
      }

      if (specialText != null) {
        inlineList.add(TextSpan(
            text: specialText.startFlag + specialText.getContent(),
            style: textStyle));
      } else if (textStack.length > 0) {
        inlineList.add(TextSpan(text: textStack, style: textStyle));
      }
    } else {
      inlineList.add(TextSpan(text: data, style: textStyle));
    }

    // TODO: implement build
    return TextSpan(children: inlineList, style: textStyle);
  }

  @override
  SpecialText createSpecialText(String flag,
      {TextStyle textStyle, SpecialTextGestureTapCallback onTap, int start}) {
    if (flag == null || flag == "") return null;
    // TODO: implement createSpecialText

    if (isStart(flag, AtText.flag)) {
      return AtText(textStyle, onTap, start);
    } else if (isStart(flag, EmojiText.flag)) {
      return EmojiText(textStyle, start);
    } else if (isStart(flag, DollarText.flag)) {
      return DollarText(textStyle, onTap, start);
    }
    return null;
  }
}
