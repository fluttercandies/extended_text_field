import 'dart:math';
import 'package:example/common/my_extended_text_selection_controls.dart';
import 'package:example/common/pic_swiper.dart';
import 'package:example/common/toggle_button.dart';
import 'package:example/common/tu_chong_repository.dart';
import 'package:example/common/tu_chong_source.dart';
import 'package:example/special_text/at_text.dart';
import 'package:example/special_text/dollar_text.dart';
import 'package:example/special_text/emoji_text.dart';
import 'package:example/special_text/my_special_text_span_builder.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:extended_image/extended_image.dart';
import 'package:loading_more_list/loading_more_list.dart';

import 'package:ff_annotation_route/ff_annotation_route.dart';

@FFRoute(
    name: "fluttercandies://TextDemo",
    routeName: "text",
    description: "build special text and inline image in text field")
class TextDemo extends StatefulWidget {
  @override
  _TextDemoState createState() => _TextDemoState();
}

class _TextDemoState extends State<TextDemo> {
  TuChongRepository tuChongRepository;
  TextEditingController _textEditingController = TextEditingController();
  MyExtendedMaterialTextSelectionControls
      _myExtendedMaterialTextSelectionControls =
      MyExtendedMaterialTextSelectionControls();
  final GlobalKey _key = GlobalKey();
  MySpecialTextSpanBuilder _mySpecialTextSpanBuilder =
      MySpecialTextSpanBuilder();

  List<TuChongItem> images = List<TuChongItem>();

  FocusNode _focusNode = FocusNode();
  double _keyboardHeight = 267.0;
  bool get showCustomKeyBoard =>
      activeEmojiGird || activeAtGrid || activeDollarGrid || activeImageGrid;
  bool activeEmojiGird = false;
  bool activeAtGrid = false;
  bool activeDollarGrid = false;
  bool activeImageGrid = false;
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
  void initState() {
    tuChongRepository = TuChongRepository();
  }

  @override
  void dispose() {
    tuChongRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).autofocus(_focusNode);
    var keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    if (keyboardHeight > 0) {
      activeEmojiGird =
          activeAtGrid = activeDollarGrid = activeImageGrid = false;
    }

    _keyboardHeight = max(_keyboardHeight, keyboardHeight);

    return Scaffold(
      appBar: AppBar(
        title: Text("special text and inline image"),
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
              //print(sessions[index]);
              Widget text = ExtendedText(
                sessions[index],
                textAlign: left ? TextAlign.left : TextAlign.right,
                specialTextSpanBuilder: _mySpecialTextSpanBuilder,
                onSpecialTextTap: (value) {
                  if (value.startsWith("\$")) {
                    launch("https://github.com/fluttercandies");
                  } else if (value.startsWith("@")) {
                    launch("mailto:zmtzawqlp@live.com");
                  }
                  //image
                  else {
                    Navigator.pushNamed(context, "fluttercandies://picswiper",
                        arguments: {
                          "index": images.indexOf(images.firstWhere(
                              (x) => x.imageUrl == value.toString())),
                          "pics": images
                              .map<PicSwiperItem>((f) =>
                                  PicSwiperItem(f.imageUrl, des: f.title))
                              .toList(),
                        });
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
            padding: EdgeInsets.only(bottom: 10.0),
            reverse: true,
            itemCount: sessions.length,
          )),
          //  TextField()
          Container(
            height: 2.0,
            color: Colors.blue,
          ),
          ExtendedTextField(
            key: _key,
            specialTextSpanBuilder: MySpecialTextSpanBuilder(
              showAtBackground: true,
            ),
            controller: _textEditingController,
            textSelectionControls: _myExtendedMaterialTextSelectionControls,
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
                              activeAtGrid =
                                  activeDollarGrid = activeImageGrid = false;
                              FocusScope.of(context).requestFocus(_focusNode);
                            }
                            activeEmojiGird = active;
                          });
                        };
                        update(change);
                      },
                      active: activeEmojiGird,
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
                                activeEmojiGird =
                                    activeDollarGrid = activeImageGrid = false;
                                FocusScope.of(context).requestFocus(_focusNode);
                              }
                              activeAtGrid = active;
                            });
                          };
                          update(change);
                        },
                        active: activeAtGrid),
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
                                activeEmojiGird =
                                    activeAtGrid = activeImageGrid = false;
                                FocusScope.of(context).requestFocus(_focusNode);
                              }
                              activeDollarGrid = active;
                            });
                          };
                          update(change);
                        },
                        active: activeDollarGrid),
                    ToggleButton(
                        activeWidget: Icon(
                          Icons.picture_in_picture,
                          color: Colors.orange,
                        ),
                        unActiveWidget: Icon(Icons.picture_in_picture),
                        activeChanged: (bool active) {
                          Function change = () {
                            setState(() {
                              if (active) {
                                activeEmojiGird =
                                    activeAtGrid = activeDollarGrid = false;
                                FocusScope.of(context).requestFocus(_focusNode);
                              }
                              activeImageGrid = active;
                            });
                          };
                          update(change);
                        },
                        active: activeImageGrid),
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
    if (activeEmojiGird) return buildEmojiGird();
    if (activeAtGrid) return buildAtGrid();
    if (activeDollarGrid) return buildDollarGrid();
    if (activeImageGrid)
      return ImageGrid((item, text) {
        images.add(item);
        insertText(text);
      }, tuChongRepository);
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
  }
}

class ImageGrid extends StatefulWidget {
  final Function(TuChongItem item, String text) insertText;
  final TuChongRepository tuChongRepository;
  ImageGrid(this.insertText, this.tuChongRepository);
  @override
  _ImageGridState createState() => _ImageGridState();
}

class _ImageGridState extends State<ImageGrid>
    with AutomaticKeepAliveClientMixin<ImageGrid> {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return LoadingMoreList(ListConfig<TuChongItem>(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 2.0, mainAxisSpacing: 2.0),
        itemBuilder: (BuildContext context, TuChongItem item, int index) {
          var url = item.imageUrl;

          ///<img src=‘http://pic2016.5442.com:82/2016/0513/12/3.jpg!960.jpg’/>
          return GestureDetector(
            child: ExtendedImage.network(
              url,
              fit: BoxFit.scaleDown,
            ),
            behavior: HitTestBehavior.translucent,
            onTap: () {
              widget.insertText?.call(item,
                  "<img src='$url' width='${item.imageSize.width}' height='${item.imageSize.height}'/>");
            },
          );
        },
        padding: EdgeInsets.all(5.0),
        sourceList: widget.tuChongRepository));
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
