import 'dart:math';
import 'package:example/common/toggle_button.dart';
import 'package:example/special_text/emoji_text.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/services.dart';

import 'special_text/at_text.dart';
import 'special_text/dollar_text.dart';
import 'special_text/my_special_text_span_builder.dart';
import 'package:url_launcher/url_launcher.dart';

class TextDemo extends StatefulWidget {
  @override
  _TextDemoState createState() => _TextDemoState();
}

class _TextDemoState extends State<TextDemo> {
  TextEditingController _textEditingController = new TextEditingController();
  FocusNode _focusNode = FocusNode();
  double _keyboardHeight = 267.0;
  bool get showCustomKeyBoard => active1 || active2 || active3;
  bool active1 = false;
  bool active2 = false;
  bool active3 = false;
  List<String> sessions = <String>[
    "[44] @Dota2 CN dota best dota",
    "yes, you are right [36].",
    "大家好，我是拉面，很萌很新 [12].",
    "\$Flutter\$. CN dev best dev",
    "\$Dota2 Ti9\$. Shanghai,I'm coming.",
    "error 0 [45] warning 0",
    "error 0 [45] warning 0",
    "error 0 [45] warning 0",
    "error 0 [45] warning 0",
    "error 0 [45] warning 0",
    "error 0 [45] warning 0",
    "error 0 [45] warning 0",
    "error 0 [45] warning 0",
    "error 0 [45] warning 0",
    "error 0 [45] warning 0",
    "error 0 [45] warning 0",
    "error 0 [45] warning 0",
  ];

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).autofocus(_focusNode);
    var keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    print(keyboardHeight);
    if (keyboardHeight > 0) {
      active1 = active2 = active3 = false;
    }

    _keyboardHeight = max(_keyboardHeight, keyboardHeight);

    return Scaffold(
      appBar: AppBar(
        title: Text("special text amd inline image"),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
              child: ListView.builder(
            itemBuilder: (context, index) {
              var left = index % 2 == 0;
              var logo = Image.asset(
                "assets/flutter_candies_logo.png",
                width: 30.0,
                height: 30.0,
              );
              var text = ExtendedText(
                sessions[index],
                textAlign: left ? TextAlign.left : TextAlign.right,
                specialTextSpanBuilder:
                    MySpecialTextSpanBuilder(type: BuilderType.extendedText),
                onSpecialTextTap: (value) {
                  if (value.startsWith("\$")) {
                    launch("https://github.com/fluttercandies");
                  } else if (value.startsWith("@")) {
                    launch("mailto:zmtzawqlp@live.com");
                  }
                },
              );

              var list = <Widget>[
                logo,
                Expanded(child: text),
                Container(
                  width: 30.0,
                )
              ];
              if (!left) list = list.reversed.toList();
              return Row(
                children: list,
              );
            },
            padding: EdgeInsets.all(0.0),
            reverse: true,
            itemCount: sessions.length,
          )),
          //  TextField()
          Container(
            height: 2.0,
            color: Colors.blue,
          ),
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
          Container(
            color: Colors.grey.withOpacity(0.3),
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
                              FocusScope.of(context).requestFocus(_focusNode);
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
                                FocusScope.of(context).requestFocus(_focusNode);
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
                                FocusScope.of(context).requestFocus(_focusNode);
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
            child: buildCustomKeyBoard(),
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

  Widget buildCustomKeyBoard() {
    if (!showCustomKeyBoard) return Container();
    if (active1) return buildEmojiGird();
    if (active2) return buildAtGrid();
    if (active3) return buildDollarGrid();
    return Container();
  }

  Widget buildEmojiGird() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8, crossAxisSpacing: 10.0, mainAxisSpacing: 10.0),
      itemBuilder: (context, index) {
        return GestureDetector(
          child: Image.asset(EmojiUitl.instance.emojiMap["[${index + 1}]"]),
          behavior: HitTestBehavior.translucent,
          onTap: () {
            insertText("[${index + 1}]");
          },
        );
      },
      itemCount: EmojiUitl.instance.emojiMap.length,
      padding: EdgeInsets.all(5.0),
    );
  }

  Widget buildAtGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 10.0, mainAxisSpacing: 10.0),
      itemBuilder: (context, index) {
        var text = atList[index];
        return GestureDetector(
          child: Align(
            child: Text(text),
          ),
          behavior: HitTestBehavior.translucent,
          onTap: () {
            insertText(text);
          },
        );
      },
      itemCount: atList.length,
      padding: EdgeInsets.all(5.0),
    );
  }

  Widget buildDollarGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 10.0, mainAxisSpacing: 10.0),
      itemBuilder: (context, index) {
        var text = dollarList[index];
        return GestureDetector(
          child: Align(
            child: Text(text.replaceAll("\$", "")),
          ),
          behavior: HitTestBehavior.translucent,
          onTap: () {
            insertText(text);
          },
        );
      },
      itemCount: dollarList.length,
      padding: EdgeInsets.all(5.0),
    );
  }

  void insertText(String text) {
    var value = _textEditingController.value;
    var start = value.selection.baseOffset;
    var end = value.selection.extentOffset;
    if (value.selection.isValid) {
      String newText = "";
      if (value.selection.isCollapsed) {
        if (end > 0) {
          newText += value.text.substring(0, end);
        }
        newText += text;
        if (value.text.length > end) {
          newText += value.text.substring(end, value.text.length);
        }
      } else {
        newText = value.text.replaceRange(start, end, text);
      }
      setState(() {
        //FocusScope.of(context).requestFocus(_focusNode);
        _textEditingController.value = value.copyWith(
            text: newText,
            selection: value.selection.copyWith(
                baseOffset: end + text.length,
                extentOffset: end + text.length));
      });
    }
  }
}
