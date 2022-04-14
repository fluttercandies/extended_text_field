import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:example/common/toggle_button.dart';
import 'package:example/special_text/at_text.dart';
import 'package:example/special_text/dollar_text.dart';
import 'package:example/special_text/emoji_text.dart' as emoji;
import 'package:example/special_text/my_extended_text_selection_controls.dart';
import 'package:example/special_text/my_special_text_span_builder.dart';
import 'package:extended_list/extended_list.dart';
import 'package:extended_text/extended_text.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

@FFRoute(
  name: 'fluttercandies://TextDemo',
  routeName: 'text',
  description: 'build special text and inline image in text field',
  exts: <String, dynamic>{
    'group': 'Complex',
    'order': 0,
  },
)
class TextDemo extends StatefulWidget {
  @override
  _TextDemoState createState() => _TextDemoState();
}

class _TextDemoState extends State<TextDemo> {
  final TextEditingController _textEditingController = TextEditingController();
  final MyTextSelectionControls _myExtendedMaterialTextSelectionControls =
      MyTextSelectionControls();
  final GlobalKey<ExtendedTextFieldState> _key =
      GlobalKey<ExtendedTextFieldState>();
  final MySpecialTextSpanBuilder _mySpecialTextSpanBuilder =
      MySpecialTextSpanBuilder();
  final StreamController<void> _gridBuilderController =
      StreamController<void>.broadcast();

  final FocusNode _focusNode = FocusNode();
  double _keyboardHeight = 0;
  bool get showCustomKeyBoard =>
      activeEmojiGird || activeAtGrid || activeDollarGrid;
  bool activeEmojiGird = false;
  bool activeAtGrid = false;
  bool activeDollarGrid = false;
  List<String> sessions = <String>[
    '[44] @Dota2 CN dota best dota',
    'yes, you are right [36].',
    '大家好，我是拉面，很萌很新 [12].',
    '\$Flutter\$. CN dev best dev',
    '\$Dota2 Ti9\$. Shanghai,I\'m coming.',
    'error 0 [45] warning 0',
  ];

  @override
  Widget build(BuildContext context) {
    //FocusScope.of(context).autofocus(_focusNode);
    final MediaQueryData mediaQueryData = MediaQuery.of(context);
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    if (keyboardHeight > 0 && keyboardHeight >= _keyboardHeight) {
      activeEmojiGird = activeAtGrid = activeDollarGrid = false;
      _gridBuilderController.add(null);
    }

    _keyboardHeight = max(_keyboardHeight, keyboardHeight);

    return SafeArea(
      bottom: true,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text('special text'),
          actions: <Widget>[
            TextButton(
              child: const Icon(
                Icons.backspace,
                color: Colors.white,
              ),
              onPressed: manualDelete,
            )
          ],
        ),
        body: Column(
          children: <Widget>[
            Expanded(
                child: ExtendedListView.builder(
              extendedListDelegate:
                  const ExtendedListDelegate(closeToTrailing: true),
              itemBuilder: (BuildContext context, int index) {
                final bool left = index % 2 == 0;
                final Image logo = Image.asset(
                  'assets/flutter_candies_logo.png',
                  width: 30.0,
                  height: 30.0,
                );
                //print(sessions[index]);
                final Widget text = ExtendedText(
                  sessions[index],
                  textAlign: left ? TextAlign.left : TextAlign.right,
                  specialTextSpanBuilder: _mySpecialTextSpanBuilder,
                  onSpecialTextTap: (dynamic value) {
                    if (value.toString().startsWith('\$')) {
                      launch('https://github.com/fluttercandies');
                    } else if (value.toString().startsWith('@')) {
                      launch('mailto:zmtzawqlp@live.com');
                    }
                  },
                );
                List<Widget> list = <Widget>[
                  logo,
                  Expanded(child: text),
                  Container(
                    width: 30.0,
                  )
                ];
                if (!left) {
                  list = list.reversed.toList();
                }
                return Row(
                  children: list,
                );
              },
              padding: const EdgeInsets.only(bottom: 10.0),
              reverse: true,
              itemCount: sessions.length,
            )),
            //  TextField()
            Container(
              height: 2.0,
              color: Colors.blue,
            ),
            //EditableText(controller: controller, focusNode: focusNode, style: style, cursorColor: cursorColor, backgroundCursorColor: backgroundCursorColor)
            ExtendedTextField(
              key: _key,
              minLines: 1,
              maxLines: 2,
              // StrutStyle get strutStyle {
              //   if (_strutStyle == null) {
              //     return StrutStyle.fromTextStyle(style, forceStrutHeight: true);
              //   }
              //   return _strutStyle!.inheritFromTextStyle(style);
              // }
              // default strutStyle is not good for WidgetSpan
              strutStyle: const StrutStyle(),
              specialTextSpanBuilder: MySpecialTextSpanBuilder(
                showAtBackground: true,
              ),
              controller: _textEditingController,
              selectionControls: _myExtendedMaterialTextSelectionControls,

              focusNode: _focusNode,
              decoration: InputDecoration(
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        sessions.insert(0, _textEditingController.text);
                        _textEditingController.value =
                            _textEditingController.value.copyWith(
                                text: '',
                                selection:
                                    const TextSelection.collapsed(offset: 0),
                                composing: TextRange.empty);
                      });
                    },
                    child: const Icon(Icons.send),
                  ),
                  contentPadding: const EdgeInsets.all(12.0)),
              //textDirection: TextDirection.rtl,
            ),
            StreamBuilder<void>(
              stream: _gridBuilderController.stream,
              builder: (BuildContext b, AsyncSnapshot<void> d) {
                return Container(
                  color: Colors.grey.withOpacity(0.3),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          ToggleButton(
                            activeWidget: const Icon(
                              Icons.sentiment_very_satisfied,
                              color: Colors.orange,
                            ),
                            unActiveWidget:
                                const Icon(Icons.sentiment_very_satisfied),
                            activeChanged: (bool active) {
                              if (keyboardHeight > 0) {
                                SystemChannels.textInput
                                    .invokeMethod<void>('TextInput.hide');
                              }
                              if (active) {
                                activeAtGrid = activeDollarGrid = false;
                              }
                              activeEmojiGird = active;

                              _gridBuilderController.add(null);
                            },
                            active: activeEmojiGird,
                          ),
                          ToggleButton(
                              activeWidget: const Padding(
                                padding: EdgeInsets.only(bottom: 5.0),
                                child: Text(
                                  '@',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20.0,
                                  ),
                                ),
                              ),
                              unActiveWidget: const Padding(
                                padding: EdgeInsets.only(bottom: 5.0),
                                child: Text(
                                  '@',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20.0),
                                ),
                              ),
                              activeChanged: (bool active) {
                                if (keyboardHeight > 0) {
                                  SystemChannels.textInput
                                      .invokeMethod<void>('TextInput.hide');
                                }

                                if (active) {
                                  activeEmojiGird = activeDollarGrid = false;
                                  // FocusScope.of(context).requestFocus(_focusNode);
                                }
                                activeAtGrid = active;

                                _gridBuilderController.add(null);

                                //final Function change = () {};
                                //update(change);
                              },
                              active: activeAtGrid),
                          ToggleButton(
                              activeWidget: const Icon(
                                Icons.attach_money,
                                color: Colors.orange,
                              ),
                              unActiveWidget: const Icon(Icons.attach_money),
                              activeChanged: (bool active) {
                                if (keyboardHeight > 0) {
                                  SystemChannels.textInput
                                      .invokeMethod<void>('TextInput.hide');
                                }

                                if (active) {
                                  activeEmojiGird = activeAtGrid = false;
                                }
                                activeDollarGrid = active;

                                _gridBuilderController.add(null);
                              },
                              active: activeDollarGrid),
                          Container(
                            width: 20.0,
                          )
                        ],
                        mainAxisAlignment: MainAxisAlignment.end,
                      ),
                      Container(),
                    ],
                  ),
                );
              },
            ),

            Container(
              height: 2.0,
              color: Colors.blue,
            ),
            StreamBuilder<void>(
              stream: _gridBuilderController.stream,
              builder: (BuildContext b, AsyncSnapshot<void> d) {
                return SizedBox(
                    height: showCustomKeyBoard
                        ? _keyboardHeight -
                            (Platform.isIOS ? mediaQueryData.padding.bottom : 0)
                        : 0,
                    child: buildCustomKeyBoard());
              },
            ),

            StreamBuilder<void>(
              stream: _gridBuilderController.stream,
              builder: (BuildContext b, AsyncSnapshot<void> d) {
                return Container(
                  height: showCustomKeyBoard ? 0 : keyboardHeight,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void update(Function change) {
    change();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');

    // if (showCustomKeyBoard) {
    //   change();
    // } else {
    //   SystemChannels.textInput
    //       .invokeMethod<void>('TextInput.hide')
    //       .whenComplete(() {
    //     Future<void>.delayed(const Duration(milliseconds: 200))
    //         .whenComplete(() {
    //       change();
    //     });
    //   });
    // }
  }

  Widget buildCustomKeyBoard() {
    if (!showCustomKeyBoard) {
      return Container();
    }
    if (activeEmojiGird) {
      return buildEmojiGird();
    }
    if (activeAtGrid) {
      return buildAtGrid();
    }
    if (activeDollarGrid) {
      return buildDollarGrid();
    }
    return Container();
  }

  Widget buildEmojiGird() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8, crossAxisSpacing: 10.0, mainAxisSpacing: 10.0),
      itemBuilder: (BuildContext context, int index) {
        return GestureDetector(
          child:
              Image.asset(emoji.EmojiUitl.instance.emojiMap['[${index + 1}]']!),
          behavior: HitTestBehavior.translucent,
          onTap: () {
            insertText('[${index + 1}]');
          },
        );
      },
      itemCount: emoji.EmojiUitl.instance.emojiMap.length,
      padding: const EdgeInsets.all(5.0),
    );
  }

  Widget buildAtGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 10.0, mainAxisSpacing: 10.0),
      itemBuilder: (BuildContext context, int index) {
        final String text = atList[index];
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
      padding: const EdgeInsets.all(5.0),
    );
  }

  Widget buildDollarGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 10.0, mainAxisSpacing: 10.0),
      itemBuilder: (BuildContext context, int index) {
        final String text = dollarList[index];
        return GestureDetector(
          child: Align(
            child: Text(text.replaceAll('\$', '')),
          ),
          behavior: HitTestBehavior.translucent,
          onTap: () {
            insertText(text);
          },
        );
      },
      itemCount: dollarList.length,
      padding: const EdgeInsets.all(5.0),
    );
  }

  void insertText(String text) {
    final TextEditingValue value = _textEditingController.value;
    final int start = value.selection.baseOffset;
    int end = value.selection.extentOffset;
    if (value.selection.isValid) {
      String newText = '';
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
        end = start;
      }

      _textEditingController.value = value.copyWith(
          text: newText,
          selection: value.selection.copyWith(
              baseOffset: end + text.length, extentOffset: end + text.length));
    } else {
      _textEditingController.value = TextEditingValue(
          text: text,
          selection:
              TextSelection.fromPosition(TextPosition(offset: text.length)));
    }

    SchedulerBinding.instance?.addPostFrameCallback((Duration timeStamp) {
      _key.currentState
          ?.bringIntoView(_textEditingController.selection.base, offset: 1);
      //nestedPdfViewerGetxController.page.value = firstIndex + 1;
    });
    // Future<void>.delayed(Duration(milliseconds: 200), () {
    //   _key.currentState?.bringIntoView(_textEditingController.selection.base);
    // });
  }

  void manualDelete() {
    //delete by code
    final TextEditingValue _value = _textEditingController.value;
    final TextSelection selection = _value.selection;
    if (!selection.isValid) {
      return;
    }

    TextEditingValue value;
    final String actualText = _value.text;
    if (selection.isCollapsed && selection.start == 0) {
      return;
    }
    final int start =
        selection.isCollapsed ? selection.start - 1 : selection.start;
    final int end = selection.end;

    value = TextEditingValue(
      text: actualText.replaceRange(start, end, ''),
      selection: TextSelection.collapsed(offset: start),
    );

    final TextSpan oldTextSpan = _mySpecialTextSpanBuilder.build(_value.text);

    value = handleSpecialTextSpanDelete(value, _value, oldTextSpan, null);

    _textEditingController.value = value;
  }
}
