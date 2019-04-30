import 'package:example/common/ensure_visible_when_focused.dart';
import 'package:flutter/material.dart';
import 'package:extended_text_field/extended_text_field.dart';

import 'special_text/my_special_text_span_builder.dart';

class TextDemo extends StatelessWidget {
  TextEditingController _textEditingController = new TextEditingController()
    ..text = "[love]";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("quickly build special text"),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
              child: Container(
            color: Colors.red,
          )),
          //  TextField()
          Row(
            children: <Widget>[
              Expanded(
                child: ExtendedTextField(
                  specialTextSpanBuilder: MySpecialTextSpanBuilder(),
                  controller: _textEditingController,
                  maxLines: 2,
                  //textDirection: TextDirection.rtl,
                ),
              ),
              GestureDetector(
                onTap: () {
//                  showDialog(
//                      context: context,
//                      builder: (c) {
//                        return Column(
//                          children: <Widget>[
//                            Expanded(
//                              child: Container(),
//                            ),
//                            Container(
//                              height: MediaQuery.of(c).viewInsets.bottom,
//                              color: Colors.red,
//                            )
//                          ],
//                        );
//                      });
                },
                child: Icon(Icons.send),
              ),
            ],
          ),
          Container(
            height: 50.0,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

//  void djdkdl() {
//    FocusScope.of(context).requestFocus(_inputFocusNode);
//  }
}
