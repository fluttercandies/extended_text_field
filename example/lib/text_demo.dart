import 'dart:math';
import 'package:example/common/toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/services.dart';

import 'special_text/my_special_text_span_builder.dart';

class TextDemo extends StatefulWidget {
  @override
  _TextDemoState createState() => _TextDemoState();
}

class _TextDemoState extends State<TextDemo> {
  TextEditingController _textEditingController = new TextEditingController()
    ..text = "[love]";
  double _keyboardHeight = 267.0;
  bool get showCustomKeyBoard => active1 || active2 || active3;
  bool active1 = false;
  bool active2 = false;
  bool active3 = false;

  @override
  Widget build(BuildContext context) {
    var keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    print(keyboardHeight);
    if (keyboardHeight > 0) {
      active1 = active2 = active3 = false;
    }

    _keyboardHeight = max(_keyboardHeight, keyboardHeight);

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
          ExtendedTextField(
            specialTextSpanBuilder:
                MySpecialTextSpanBuilder(showAtBackground: false),
            controller: _textEditingController,
            maxLines: null,
            decoration: InputDecoration(
                suffixIcon: GestureDetector(
                  onTap: () {
                    //FocusScope.of(context).requestFocus(new FocusNode());
                  },
                  child: Icon(Icons.send),
                ),
                contentPadding: EdgeInsets.all(12.0)),
            //textDirection: TextDirection.rtl,
          ),
          Container(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    ToggleButton(
                      activeWidget: Icon(
                        Icons.sentiment_very_satisfied,
                        color: Colors.orange,
                      ),
                      unActiveWidget: Icon(Icons.sentiment_very_satisfied),
                      activeChanged: (bool active) {
                        Function change = () {
                          setState(() {
                            if (active) {
                              active2 = active3 = false;
                            }
                            active1 = active;
                          });
                        };
                        update(change);
                      },
                      active: active1,
                    ),
                    ToggleButton(
                        activeWidget: Padding(
                          padding: EdgeInsets.only(bottom: 5.0),
                          child: Text(
                            "@",
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 20.0,
                            ),
                          ),
                        ),
                        unActiveWidget: Padding(
                          padding: EdgeInsets.only(bottom: 5.0),
                          child: Text(
                            "@",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20.0),
                          ),
                        ),
                        activeChanged: (bool active) {
                          Function change = () {
                            setState(() {
                              if (active) {
                                active1 = active3 = false;
                              }
                              active2 = active;
                            });
                          };
                          update(change);
                        },
                        active: active2),
                    ToggleButton(
                        activeWidget: Icon(
                          Icons.attach_money,
                          color: Colors.orange,
                        ),
                        unActiveWidget: Icon(Icons.attach_money),
                        activeChanged: (bool active) {
                          Function change = () {
                            setState(() {
                              if (active) {
                                active1 = active2 = false;
                              }
                              active3 = active;
                            });
                          };
                          update(change);
                        },
                        active: active3),
                    Container(
                      width: 20.0,
                    )
                  ],
                  mainAxisAlignment: MainAxisAlignment.end,
                ),
                Container(),
              ],
            ),
          ),
          Container(
            height: 2.0,
            color: Colors.blue,
          ),
          Container(
            height: showCustomKeyBoard ? _keyboardHeight : 0.0,
            color: Colors.yellow,
          )
        ],
      ),
    );
  }

  void update(Function change) {
    if (showCustomKeyBoard) {
      change();
    } else {
      SystemChannels.textInput.invokeMethod('TextInput.hide').whenComplete(() {
        Future.delayed(Duration(milliseconds: 200)).whenComplete(() {
          change();
        });
      });
    }
  }
}
