import 'package:flutter/material.dart';

class ToggleButton extends StatefulWidget {
  final Widget activeWidget;
  final Widget unActiveWidget;
  bool active;
  final ValueChanged<bool> activeChanged;
  ToggleButton(
      {this.activeWidget,
      this.unActiveWidget,
      this.activeChanged,
      this.active: false});
  @override
  _ToggleButtonState createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<ToggleButton> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        setState(() {
          widget.active = !widget.active;
          widget.activeChanged?.call(widget.active);
        });
      },
      child: Padding(
        padding: EdgeInsets.only(left: 20.0, top: 10.0, bottom: 10.0),
        child: widget.active ? widget.activeWidget : widget.unActiveWidget,
      ),
    );
  }
}
