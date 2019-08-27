import 'package:example/common/my_extended_text_selection_controls.dart';
import 'package:example/special_text/my_special_text_span_builder.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:ff_annotation_route/ff_annotation_route.dart';

///
///  create by zmtzawqlp on 2019/7/31
///

@FFRoute(
    name: "fluttercandies://CustomToolBar",
    routeName: "custom toolbar",
    description: "custom selection toolbar and handles for text field")
class CustomToolBar extends StatefulWidget {
  @override
  _CustomToolBarState createState() => _CustomToolBarState();
}

class _CustomToolBarState extends State<CustomToolBar> {
  MyExtendedMaterialTextSelectionControls
      _myExtendedMaterialTextSelectionControls =
      MyExtendedMaterialTextSelectionControls();
  MySpecialTextSpanBuilder _mySpecialTextSpanBuilder =
      MySpecialTextSpanBuilder();
  TextEditingController controller = TextEditingController()
    ..text =
        "[33]Extended text field help you to build rich text quickly. any special text you will have with extended text. this is demo to show how to create custom toolbar and handles."
            "\n\nIt's my pleasure to invite you to join \$FlutterCandies\$ if you want to improve flutter .[36]"
            "\n\nif you meet any problem, please let me konw @zmtzawqlp .[44]";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("custom selection toolbar handles"),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.0),
        child: Center(
          child: ExtendedTextField(
            textSelectionControls: _myExtendedMaterialTextSelectionControls,
            specialTextSpanBuilder: _mySpecialTextSpanBuilder,
            controller: controller,
            maxLines: null,
          ),
        ),
      ),
    );
  }
}
