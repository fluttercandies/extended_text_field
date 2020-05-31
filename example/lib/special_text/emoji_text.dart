import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_candies_demo_library/flutter_candies_demo_library.dart'
    as demo;

///emoji/image text
class EmojiText extends demo.EmojiText {
  EmojiText(
    TextStyle textStyle, {
    int start,
  }) : super(
          textStyle,
          start: start,
        );

  @override
  InlineSpan finishText() {
    final String key = toString();
    if (EmojiUitl.instance.emojiMap.containsKey(key) && !kIsWeb) {
      //fontsize id define image height
      //size = 30.0/26.0 * fontSize
      const double size = 20.0;

      ///fontSize 26 and text height =30.0
      //final double fontSize = 26.0;

      return ImageSpan(AssetImage(EmojiUitl.instance.emojiMap[key]),
          actualText: key,
          imageWidth: size,
          imageHeight: size,
          start: start,
          fit: BoxFit.fill,
          margin: const EdgeInsets.only(left: 2.0, right: 2.0));
    }

    return TextSpan(text: toString(), style: textStyle);
  }
}

class EmojiUitl {
  EmojiUitl._() {
    for (int i = 1; i < 49; i++) {
      _emojiMap['[$i]'] = '$_emojiFilePath/$i.png';
    }
  }

  final Map<String, String> _emojiMap = <String, String>{};

  Map<String, String> get emojiMap => _emojiMap;

  final String _emojiFilePath = 'assets';

  static EmojiUitl _instance;
  static EmojiUitl get instance {
    _instance ??= EmojiUitl._();
    return _instance;
  }
}
