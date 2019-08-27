import 'package:example/special_text/email_span_builder.dart';
import 'package:example/special_text/my_special_text_span_builder.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:ff_annotation_route/ff_annotation_route.dart';

///
///  create by zmtzawqlp on 2019/8/4
///
@FFRoute(
    name: "fluttercandies://WidgetSpanDemo",
    routeName: "widget span",
    description: "mailbox demo with widgetSpan")
class WidgetSpanDemo extends StatefulWidget {
  @override
  _WidgetSpanDemoState createState() => _WidgetSpanDemoState();
}

class _WidgetSpanDemoState extends State<WidgetSpanDemo> {
  TextEditingController controller = TextEditingController();
  TextEditingController controller1 = TextEditingController();
  TextEditingController controller2 = TextEditingController()
    ..text =
        "[33]Extended text field help you to build rich text quickly. any special text you will have with extended text field. this is demo to show how to create special text with widget span."
            "\n\nIt's my pleasure to invite you to join \$FlutterCandies\$ if you want to improve flutter .[36]"
            "\n\nif you meet any problem, please let me konw @zmtzawqlp .[44]";
  EmailSpanBuilder _emailSpanBuilder;
  @override
  void initState() {
    _emailSpanBuilder = EmailSpanBuilder(controller, context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("E-mail"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                child: Text("To : "),
                width: 60.0,
                padding: EdgeInsets.only(
                  left: 10.0,
                ),
              ),
              Expanded(
                child: ExtendedTextField(
                  controller: controller,
                  specialTextSpanBuilder: _emailSpanBuilder,
                  maxLines: null,
                  decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          var selection = controller.selection.copyWith();
                          showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (c) {
                                return Column(
                                  children: <Widget>[
                                    Flexible(
                                      child: Container(),
                                    ),
                                    Expanded(
                                      child: Material(
                                          child: Padding(
                                        padding: EdgeInsets.all(10.0),
                                        child: Column(
                                          children: <Widget>[
                                            FlatButton(
                                                onPressed: () {
                                                  insertEmail(
                                                      "zmtzawqlp@live.com ",
                                                      selection);
                                                  Navigator.pop(context);
                                                },
                                                child:
                                                    Text("zmtzawqlp@live.com")),
                                            FlatButton(
                                                onPressed: () {
                                                  insertEmail(
                                                      "410496936@qq.com ",
                                                      selection);
                                                  Navigator.pop(context);
                                                },
                                                child:
                                                    Text("410496936@qq.com")),
                                          ],
                                        ),
                                      )),
                                    ),
                                    Flexible(
                                      child: Container(),
                                    )
                                  ],
                                );
                              });
                        },
                      ),
                      border: InputBorder.none,
                      hintText: "input receiver here"),
                ),
              ),
            ],
          ),
          Divider(),
          Row(
            children: <Widget>[
              Container(
                child: Text("Topic : "),
                width: 60.0,
                padding: EdgeInsets.only(left: 10.0),
              ),
              Expanded(
                child: ExtendedTextField(
                  controller: controller1,
                  maxLines: null,
                  decoration: InputDecoration(
                      border: InputBorder.none, hintText: "input topic here"),
                ),
              )
            ],
          ),
          Divider(),
          Expanded(
            child: ExtendedTextField(
              controller: controller2,
              maxLines: null,
              specialTextSpanBuilder: MySpecialTextSpanBuilder(),
              decoration: InputDecoration(
                  border: InputBorder.none, contentPadding: EdgeInsets.all(10)),
            ),
          )
        ],
      ),
    );
  }

  void insertEmail(String text, TextSelection selection) {
    var value = controller.value;
    var start = selection.baseOffset;
    var end = selection.extentOffset;
    if (selection.isValid) {
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
      controller.value = value.copyWith(
          text: newText,
          selection: selection.copyWith(
              baseOffset: end + text.length, extentOffset: end + text.length));
    } else {
      controller.value = TextEditingValue(
          text: text,
          selection:
              TextSelection.fromPosition(TextPosition(offset: text.length)));
    }
  }
}
