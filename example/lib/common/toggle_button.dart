import 'package:flutter/material.dart';

class ToggleButton extends StatefulWidget {
  const ToggleButton(
      {this.activeWidget,
      this.unActiveWidget,
      this.activeChanged,
      this.active = false});
  final Widget? activeWidget;
  final Widget? unActiveWidget;
  final bool active;
  final ValueChanged<bool>? activeChanged;
  @override
  _ToggleButtonState createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<ToggleButton> {
  bool _active = false;

  @override
  void initState() {
    _active = widget.active;
    super.initState();
  }

  @override
  void didUpdateWidget(ToggleButton oldWidget) {
    _active = widget.active;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        setState(() {
          _active = !_active;
          widget.activeChanged?.call(_active);
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 20.0, top: 10.0, bottom: 10.0),
        child: widget.active ? widget.activeWidget : widget.unActiveWidget,
      ),
    );
  }
}
