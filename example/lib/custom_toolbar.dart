import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';

import 'common/my_extended_text_selection_controls.dart';

///
///  create by zmtzawqlp on 2019/7/31
///

class CustomToolBar extends StatefulWidget {
  @override
  _CustomToolBarState createState() => _CustomToolBarState();
}

class _CustomToolBarState extends State<CustomToolBar> {
  MyExtendedMaterialTextSelectionControls
      _myExtendedMaterialTextSelectionControls =
      MyExtendedMaterialTextSelectionControls();
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("special text and inline image"),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.0),
        child: Center(
          child: ExtendedTextField(
            textSelectionControls: _myExtendedMaterialTextSelectionControls,
            controller: controller,
            maxLines: null,
          ),
        ),
      ),
    );
  }
}
