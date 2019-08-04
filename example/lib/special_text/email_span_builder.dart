import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/material.dart';

import 'email_text.dart';

///
///  create by zmtzawqlp on 2019/8/4
///

class EmailSpanBuilder extends SpecialTextSpanBuilder {
  final TextEditingController controller;
  final BuildContext context;
  EmailSpanBuilder(this.controller, this.context);
  @override
  SpecialText createSpecialText(String flag,
      {TextStyle textStyle, onTap, int index}) {
    if (flag == null || flag == "") return null;

    if (!flag.startsWith(" ") && !flag.startsWith("@")) {
      return EmailText(textStyle, onTap,
          start: index,
          context: context,
          controller: controller,
          startFlag: flag);
    }
    return null;
  }
}
