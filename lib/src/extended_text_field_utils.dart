import 'dart:math';

import 'package:extended_text_field/src/text_span/special_text_span_base.dart';
import 'package:flutter/material.dart';

///
///  create by zmtzawqlp on 2019/4/29
///

TextPosition convertTextInputPostionToTextPainterPostion(
    TextSpan text, TextPosition textPosition) {
  if (text != null && text.children != null) {
    int caretOffset = textPosition.offset;
    int textOffset = 0;
    for (TextSpan ts in text.children) {
      if (ts is SpecialTextSpanBase) {
        var length = (ts as SpecialTextSpanBase).actualText.length;
        caretOffset -= (length - ts.toPlainText().length);
        textOffset += length;
      } else {
        textOffset += ts.toPlainText().length;
      }
      if (textOffset >= textPosition.offset) {
        break;
      }
    }
    if (caretOffset != textPosition.offset) {
      return TextPosition(
          offset: max(0, caretOffset), affinity: textPosition.affinity);
    }
  }
  return textPosition;
}

TextSelection convertTextInputSelectionToTextPainterSelection(
    TextSpan text, TextSelection selection) {
  if (selection.isValid) {
    if (selection.isCollapsed) {
      var extent =
          convertTextInputPostionToTextPainterPostion(text, selection.extent);
      if (selection.extent != extent) {
        selection = selection.copyWith(
            baseOffset: extent.offset,
            extentOffset: extent.offset,
            affinity: selection.affinity,
            isDirectional: selection.isDirectional);
        return selection;
      }
    } else {
      var extent =
          convertTextInputPostionToTextPainterPostion(text, selection.extent);

      var base =
          convertTextInputPostionToTextPainterPostion(text, selection.base);

      if (selection.extent != extent || selection.base != base) {
        selection = selection.copyWith(
            baseOffset: base.offset,
            extentOffset: extent.offset,
            affinity: selection.affinity,
            isDirectional: selection.isDirectional);
        return selection;
      }
    }
  }

  return selection;
}

TextPosition convertTextPainterPostionToTextInputPostion(
    TextSpan text, TextPosition textPosition) {
  if (text != null && text.children != null && textPosition != null) {
    int caretOffset = textPosition.offset;
    if (caretOffset <= 0) return textPosition;

    int textOffset = 0;
    for (TextSpan ts in text.children) {
      if (ts is SpecialTextSpanBase) {
        var length = (ts as SpecialTextSpanBase).actualText.length;
        caretOffset += (length - ts.toPlainText().length);
      }
      textOffset += ts.toPlainText().length;
      if (textOffset >= textPosition.offset) {
        break;
      }
    }
    if (caretOffset != textPosition.offset) {
      return TextPosition(offset: caretOffset, affinity: textPosition.affinity);
    }
  }
  return textPosition;
}

TextSelection convertTextPainterSelectionToTextInputSelection(
    TextSpan text, TextSelection selection) {
  if (selection.isValid) {
    if (selection.isCollapsed) {
      var extent =
          convertTextPainterPostionToTextInputPostion(text, selection.extent);
      if (selection.extent != extent) {
        selection = selection.copyWith(
            baseOffset: extent.offset,
            extentOffset: extent.offset,
            affinity: selection.affinity,
            isDirectional: selection.isDirectional);
        return selection;
      }
    } else {
      var extent =
          convertTextPainterPostionToTextInputPostion(text, selection.extent);

      var base =
          convertTextPainterPostionToTextInputPostion(text, selection.base);

      if (selection.extent != extent || selection.base != base) {
        selection = selection.copyWith(
            baseOffset: base.offset,
            extentOffset: extent.offset,
            affinity: selection.affinity,
            isDirectional: selection.isDirectional);
        return selection;
      }
    }
  }

  return selection;
}
