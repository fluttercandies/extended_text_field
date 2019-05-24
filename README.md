# extended_text_field

[![pub package](https://img.shields.io/pub/v/extended_text_field.svg)](https://pub.dartlang.org/packages/extended_text_field)

extended official text field to quickly build special text like inline image or @somebody etc.

base on flutter version 1.5.7

[Chinese blog](https://juejin.im/post/5ccc25156fb9a0320f7df543)


![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text_field/extended_text_field.gif)


![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text_field/extended_text_field_image.gif)


## limitation

- Not support: it won't handle special text when TextDirection.rtl.

  Image position calculated by TextPainter is strange.

- Not support:it won't handle special text when obscureText is true.

- codes are base on flutter 1.5.4-hotfix.2, if any one find some codes are broken,
please fix them base on your flutter version.
it has not time to maintain codes for every version,sorry for that,
and will update codes for stable flutter version as soon as possible.

- TextPainter.getFullHeightForCaret api is not support under lower flutter version,
  I have to comment out them. if you think the caret height is not comfortable,
  you can uncomment them base on your flutter version.
```dart
    ///zmt
    ///1.5.7
    ///under lower version of flutter, getFullHeightForCaret is not support
    ///
    // Override the height to take the full height of the glyph at the TextPosition
    // when not on iOS. iOS has special handling that creates a taller caret.
    // TODO(garyq): See the TODO for _getCaretPrototype.
//    if (defaultTargetPlatform != TargetPlatform.iOS &&
//        _textPainter.getFullHeightForCaret(textPosition, _caretPrototype) !=
//            null) {
//      caretRect = Rect.fromLTWH(
//        caretRect.left,
//        // Offset by _kCaretHeightOffset to counteract the same value added in
//        // _getCaretPrototype. This prevents this from scaling poorly for small
//        // font sizes.
//        caretRect.top - _kCaretHeightOffset,
//        caretRect.width,
//        _textPainter.getFullHeightForCaret(textPosition, _caretPrototype),
//      );
//    }
```

##  How to use it.

### 1. just to extend SpecialText and define your rule.

code for @xxx
```dart
class AtText extends SpecialText {
  static const String flag = "@";
  final int start;

  /// whether show background for @somebody
  final bool showAtBackground;

  final BuilderType type;
  AtText(TextStyle textStyle, SpecialTextGestureTapCallback onTap,
      {this.showAtBackground: false, this.type, this.start})
      : super(flag, " ", textStyle, onTap: onTap);

  @override
  TextSpan finishText() {
    // TODO: implement finishText
    TextStyle textStyle =
        this.textStyle?.copyWith(color: Colors.blue, fontSize: 16.0);

    final String atText = toString();

    if (type == BuilderType.extendedText)
      return TextSpan(
          text: atText,
          style: textStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (onTap != null) onTap(atText);
            });

    return showAtBackground
        ? BackgroundTextSpan(
            background: Paint()..color = Colors.blue.withOpacity(0.15),
            text: atText,
            actualText: atText,
            start: start,
            deleteAll: false,
            style: textStyle,
            recognizer: type == BuilderType.extendedText
                ? (TapGestureRecognizer()
                  ..onTap = () {
                    if (onTap != null) onTap(atText);
                  })
                : null)
        : SpecialTextSpan(
            text: atText,
            actualText: atText,
            start: start,
            deleteAll: false,
            style: textStyle,
            recognizer: type == BuilderType.extendedText
                ? (TapGestureRecognizer()
                  ..onTap = () {
                    if (onTap != null) onTap(atText);
                  })
                : null);
  }
}
```

code for image
``` dart
class EmojiText extends SpecialText {
  static const String flag = "[";
  final int start;
  EmojiText(TextStyle textStyle, {this.start})
      : super(EmojiText.flag, "]", textStyle);

  @override
  TextSpan finishText() {
    // TODO: implement finishText
    var key = toString();
    if (EmojiUitl.instance.emojiMap.containsKey(key)) {
      //fontsize id define image height
      //size = 30.0/26.0 * fontSize
      final double size = 20.0;

      ///fontSize 26 and text height =30.0
      //final double fontSize = 26.0;

      return ImageSpan(AssetImage(EmojiUitl.instance.emojiMap[key]),
          actualText: key,
          imageWidth: size,
          imageHeight: size,
          start: start,
          deleteAll: true,
          fit: BoxFit.fill,
          margin: EdgeInsets.only(left: 2.0, top: 2.0, right: 2.0));
    }

    return TextSpan(text: toString(), style: textStyle);
  }
}
```

### 2. create your SpecialTextSpanBuilder.
``` dart
class MySpecialTextSpanBuilder extends SpecialTextSpanBuilder {
  /// whether show background for @somebody
  final bool showAtBackground;
  final BuilderType type;
  MySpecialTextSpanBuilder(
      {this.showAtBackground: false, this.type: BuilderType.extendedText});

  @override
  TextSpan build(String data, {TextStyle textStyle, onTap}) {
    // TODO: implement build
    var textSpan = super.build(data, textStyle: textStyle, onTap: onTap);
    //for performance, make sure your all SpecialTextSpan are only in textSpan.children
    //extended_text_field will only check SpecialTextSpan in textSpan.children
    return textSpan;
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
```

### 3.enjoy your nice text field
input text will auto change to SpecialTextSpan and show in text field
``` dart
 ExtendedTextField(
            specialTextSpanBuilder: MySpecialTextSpanBuilder(
                showAtBackground: true, type: BuilderType.extendedTextField),
            controller: _textEditingController,
            maxLines: null,
            focusNode: _focusNode,
            decoration: InputDecoration(
                suffixIcon: GestureDetector(
                  onTap: () {
                    setState(() {
                      sessions.insert(0, _textEditingController.text);
                      _textEditingController.value =
                          _textEditingController.value.copyWith(
                              text: "",
                              selection: TextSelection.collapsed(offset: 0),
                              composing: TextRange.empty);
                    });
                  },
                  child: Icon(Icons.send),
                ),
                contentPadding: EdgeInsets.all(12.0)),
            //textDirection: TextDirection.rtl,
          ),
```

[more detail](https://github.com/fluttercandies/extended_text_field/blob/master/example/lib/text_demo.dart)
