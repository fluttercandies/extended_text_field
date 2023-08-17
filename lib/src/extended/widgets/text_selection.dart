part of 'package:extended_text_field/src/extended/widgets/text_field.dart';

/// [TextSelectionOverlay ]
class ExtendedTextSelectionOverlay extends _TextSelectionOverlay {
  ExtendedTextSelectionOverlay({
    required super.value,
    required super.context,
    super.debugRequiredFor,
    required super.toolbarLayerLink,
    required super.startHandleLayerLink,
    required super.endHandleLayerLink,
    required super.renderObject,
    super.selectionControls,
    super.handlesVisible = false,
    required super.selectionDelegate,
    super.dragStartBehavior = DragStartBehavior.start,
    super.onSelectionHandleTapped,
    super.clipboardStatus,
    super.contextMenuBuilder,
    required super.magnifierConfiguration,
  });

  @override
  void _handleSelectionStartHandleDragUpdate(DragUpdateDetails details) {
    if (!renderObject.attached) {
      return;
    }

    _startHandleDragPosition =
        _getHandleDy(details.globalPosition.dy, _startHandleDragPosition);
    final Offset adjustedOffset = Offset(
      details.globalPosition.dx,
      _startHandleDragPosition + _startHandleDragPositionToCenterOfLine,
    );
    TextPosition position = renderObject.getPositionForPoint(adjustedOffset);

    /// zmtzawqlp
    if ((renderObject as ExtendedRenderEditable).hasSpecialInlineSpanBase) {
      position =
          ExtendedTextLibraryUtils.convertTextPainterPostionToTextInputPostion(
              renderObject.text!, position)!;
    }
    if (_selection.isCollapsed) {
      _selectionOverlay.updateMagnifier(_buildMagnifier(
        currentTextPosition: position,
        globalGesturePosition: details.globalPosition,
        renderEditable: renderObject,
      ));

      final TextSelection currentSelection =
          TextSelection.fromPosition(position);
      _handleSelectionHandleChanged(currentSelection);
      return;
    }

    final TextSelection newSelection;
    switch (defaultTargetPlatform) {
      // On Apple platforms, dragging the base handle makes it the extent.
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        newSelection = TextSelection(
          extentOffset: position.offset,
          baseOffset: _selection.end,
        );
        if (newSelection.extentOffset >= _selection.end) {
          return; // Don't allow order swapping.
        }
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        newSelection = TextSelection(
          baseOffset: position.offset,
          extentOffset: _selection.extentOffset,
        );
        if (newSelection.baseOffset >= newSelection.extentOffset) {
          return; // Don't allow order swapping.
        }
    }

    _selectionOverlay.updateMagnifier(_buildMagnifier(
      currentTextPosition: newSelection.extent.offset < newSelection.base.offset
          ? newSelection.extent
          : newSelection.base,
      globalGesturePosition: details.globalPosition,
      renderEditable: renderObject,
    ));

    _handleSelectionHandleChanged(newSelection);
  }

  @override
  void _handleSelectionEndHandleDragUpdate(DragUpdateDetails details) {
    if (!renderObject.attached) {
      return;
    }

    _endHandleDragPosition =
        _getHandleDy(details.globalPosition.dy, _endHandleDragPosition);
    final Offset adjustedOffset = Offset(
      details.globalPosition.dx,
      _endHandleDragPosition + _endHandleDragPositionToCenterOfLine,
    );

    TextPosition position = renderObject.getPositionForPoint(adjustedOffset);

    // zmtzawqlp
    if ((renderObject as ExtendedRenderEditable).hasSpecialInlineSpanBase) {
      position =
          ExtendedTextLibraryUtils.convertTextPainterPostionToTextInputPostion(
              renderObject.text!, position)!;
    }
    if (_selection.isCollapsed) {
      _selectionOverlay.updateMagnifier(_buildMagnifier(
        currentTextPosition: position,
        globalGesturePosition: details.globalPosition,
        renderEditable: renderObject,
      ));

      final TextSelection currentSelection =
          TextSelection.fromPosition(position);
      _handleSelectionHandleChanged(currentSelection);
      return;
    }

    final TextSelection newSelection;
    switch (defaultTargetPlatform) {
      // On Apple platforms, dragging the base handle makes it the extent.
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        newSelection = TextSelection(
          extentOffset: position.offset,
          baseOffset: _selection.start,
        );
        if (position.offset <= _selection.start) {
          return; // Don't allow order swapping.
        }
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        newSelection = TextSelection(
          baseOffset: _selection.baseOffset,
          extentOffset: position.offset,
        );
        if (newSelection.baseOffset >= newSelection.extentOffset) {
          return; // Don't allow order swapping.
        }
    }

    _handleSelectionHandleChanged(newSelection);

    _selectionOverlay.updateMagnifier(_buildMagnifier(
      currentTextPosition: newSelection.extent,
      globalGesturePosition: details.globalPosition,
      renderEditable: renderObject,
    ));
  }
}
