# extended_text_field

[![pub package](https://img.shields.io/pub/v/extended_text_field.svg)](https://pub.dartlang.org/packages/extended_text_field)

extended official text field to quickly build special text like inline image or @somebody etc.

## limitation
1.Not support TextDirection.rtl.
Image position calculated by TextPainter is strange.

2.Not support for obscureText.

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text_field/extended_text_field.gif)

how to use it.

### 1. just to extend SpecialText and define your rule.

code for @xxx
```dart
class AtText extends SpecialText {
  static const String flag = "@";
  final int start;

  /// whether show background for @somebody
  final bool showAtBackground;

  final BuilderType type;
  AtText(TextStyle textStyle, SpecialTextGestureTapCallback onTap, this.start,
      {this.showAtBackground: false, this.type})
      : super(flag, " ", textStyle, onTap: onTap);

  @override
  TextSpan finishText() {
    // TODO: implement finishText
    TextStyle textStyle = showAtBackground
        ? this.textStyle?.copyWith(
            fontSize: 16.0,
            background: Paint()..color = Colors.blue.withOpacity(0.5))
        : this.textStyle?.copyWith(color: Colors.blue, fontSize: 16.0);

    final String atText = toString();

    if (type == BuilderType.extendedText)
      return TextSpan(
          text: atText,
          style: textStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (onTap != null) onTap(atText);
            });

    return SpecialTextSpan(
      text: atText,
      actualText: atText,
      start: start,
      deleteAll: false,
      style: textStyle,
    );
  }
}
```

code for image
``` dart
class EmojiText extends SpecialText {
  static const String flag = "[";
  final int start;
  EmojiText(TextStyle textStyle, this.start)
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
      return AtText(textStyle, onTap, start,
          showAtBackground: showAtBackground, type: type);
    } else if (isStart(flag, EmojiText.flag)) {
      return EmojiText(textStyle, start);
    } else if (isStart(flag, DollarText.flag)) {
      return DollarText(textStyle, onTap, start, type: type);
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
                showAtBackground: false, type: BuilderType.extendedTextField),
            controller: _textEditingController,
            maxLines: null,
            focusNode: _focusNode,
            decoration: InputDecoration(
                suffixIcon: GestureDetector(
                  onTap: () {
                    setState(() {
                      sessions.insert(0, _textEditingController.text);
                      _textEditingController.clear();
                    });
                  },
                  child: Icon(Icons.send),
                ),
                contentPadding: EdgeInsets.all(12.0)),
            //textDirection: TextDirection.rtl,
          ),
```

[more detail](https://github.com/fluttercandies/extended_text_field/blob/master/example/lib/text_demo.dart)
