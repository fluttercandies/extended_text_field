import 'dart:math';
import 'package:extended_text_library/extended_text_library.dart';
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
      if (ts is SpecialTextSpan) {
        var length = ts.actualText.length;
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
      if (ts is SpecialTextSpan) {
        var length = ts.actualText.length;
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

///correct caret Offset
///make sure caret is not in image span
TextEditingValue correctCaretOffset(TextEditingValue value, TextSpan textSpan,
    TextInputConnection textInputConnection) {
  if (value.selection.isValid && value.selection.isCollapsed) {
    int caretOffset = value.selection.extentOffset;
    var imageSpans = textSpan.children.where((x) => x is ImageSpan);
    //correct caret Offset
    //make sure caret is not in image span
    for (ImageSpan ts in imageSpans) {
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
  return value;
}

TextEditingValue handleSpecialTextSpanDelete(
    TextEditingValue value,
    TextEditingValue oldValue,
    TextSpan oldTextSpan,
    TextInputConnection textInputConnection) {
  var oldText = oldValue?.text;
  var newText = value?.text;
  if (oldTextSpan != null) {
    var imageSpans = oldTextSpan.children
        .where((x) => (x is SpecialTextSpan && x.deleteAll));

    ///take care of image span
    if (imageSpans.length > 0 &&
        oldText != null &&
        newText != null &&
        oldText.length > newText.length) {
      int difStart = 0;
      //int difEnd = oldText.length - 1;
      for (; difStart < newText.length; difStart++) {
        if (oldText[difStart] != newText[difStart]) {
          break;
        }
      }

      int caretOffset = value.selection.extentOffset;
      if (difStart > 0) {
        for (SpecialTextSpan ts in imageSpans) {
          if (difStart > ts.start && difStart < ts.end) {
            //difStart = ts.start;
            newText = newText.replaceRange(ts.start, difStart, "");
            caretOffset -= (difStart - ts.start);
            break;
          }
        }
        if (newText != value.text) {
          value = TextEditingValue(
              text: newText,
              selection: value.selection.copyWith(
                  baseOffset: caretOffset,
                  extentOffset: caretOffset,
                  affinity: value.selection.affinity,
                  isDirectional: value.selection.isDirectional));
          textInputConnection?.setEditingState(value);
        }
      }
    }
  }

  return value;
}

bool hasSpecialText(List<TextSpan> value) {
  if (value == null) return false;

  for (var textSpan in value) {
    if (textSpan is SpecialTextSpan) return true;
    if (hasSpecialText(textSpan.children)) {
      return true;
    }
  }
  return false;
}
