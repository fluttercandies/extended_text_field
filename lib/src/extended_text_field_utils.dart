import 'dart:math';

import 'package:extended_text/extended_text.dart';
import 'package:extended_text_field/src/text_span/special_text_span_base.dart';
import 'package:extended_text_field/src/text_span/text_field_image_span.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

double getImageSpanCorrectPosition(ImageSpan image, TextDirection direction) {
  var correctPosition = image.width / 2.0;
  //if (direction == TextDirection.rtl) correctPosition = -correctPosition;

  return correctPosition;
}

TextEditingValue correctCaretOffset(TextEditingValue value, TextSpan newText,
    TextInputConnection textInputConnection) {
  var text = newText.toPlainText();
  if (text != value.text) {
    if (value.selection.isValid && value.selection.isCollapsed) {
      int caretOffset = value.selection.extentOffset;
      //correct caret Offset
      //make sure caret is not in image span
      var images = newText.children.where((x) => x is TextFieldImageSpan);
      for (TextFieldImageSpan ts in images) {
        if (caretOffset > ts.start && caretOffset < ts.end) {
          //move caretOffset to end
          caretOffset = ts.end;
          break;
        }
      }

      ///tell textInput caretOffset is changed.
      if (caretOffset != value.selection.baseOffset) {
        value = value.copyWith(
            selection: value.selection
                .copyWith(baseOffset: caretOffset, extentOffset: caretOffset));
        textInputConnection?.setEditingState(value);
      }
    }
  }
  return value;
}
