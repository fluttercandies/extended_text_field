# extended_text_field

[![pub package](https://img.shields.io/pub/v/extended_text_field.svg)](https://pub.dartlang.org/packages/extended_text_field)

extended official text field to quickly build special text like inline image or @somebody etc.

base on flutter version 1.5.7

## limitation

1.Not support: TextDirection.rtl.
Image position calculated by TextPainter is strange.

2.Not support: obscureText is true.

3.Not support: TextEditingValue is composed.

4.codes are base on flutter 1.5.7, if any one find some codes are broken,
please fix them base on your flutter version, we can't maintain codes for every version.

##  How to use it.

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text_field/extended_text_field.gif)

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text_field/extended_text_field_input.gif)

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
          ),
```

[more detail](https://github.com/fluttercandies/extended_text_field/blob/master/example/lib/text_demo.dart)
