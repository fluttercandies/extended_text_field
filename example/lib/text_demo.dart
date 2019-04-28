import 'package:flutter/material.dart';
import 'package:extended_text_field/extended_text_field.dart';

import 'special_text/my_special_text_span_builder.dart';

class TextDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("quickly build special text"),
      ),
      body: Container(
          padding: EdgeInsets.all(20.0),
          child: ExtendedTextField(
            specialTextSpanBuilder: MySpecialTextSpanBuilder(),
            //controller: TextEditingController()..text = "[love]",
            maxLines: 2,
          )),
    );
  }
}
